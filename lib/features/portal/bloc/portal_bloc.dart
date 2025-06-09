import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'package:solana_web3/solana_web3.dart' as web3;
import 'package:wagus/core/extensions/extensions.dart';
import 'package:wagus/features/portal/data/portal_repository.dart';
import 'package:wagus/services/privy_service.dart';
import 'package:wagus/services/user_service.dart';
import 'package:wagus/shared/holder/holder.dart';
import 'package:wagus/shared/token/token.dart';
import 'package:wagus/shared/transaction/transaction.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

part 'portal_event.dart';
part 'portal_state.dart';

class _CachedHolder {
  final Holder holder;
  final DateTime timestamp;

  _CachedHolder(this.holder) : timestamp = DateTime.now();

  bool get isFresh =>
      DateTime.now().difference(timestamp) < const Duration(minutes: 1);
}

class PortalBloc extends Bloc<PortalEvent, PortalState> {
  final PortalRepository portalRepository;

  final Map<String, _CachedHolder> _holderCache = {};

  PortalBloc({required this.portalRepository})
      : super(PortalState(selectedToken: Token.empty())) {
    on<PortalInitialEvent>(_handleInitial);
    on<PortalAuthorizeEvent>(_handleAuthorize);
    on<PortalRefreshEvent>(_handleRefresh);
    on<PortalClearEvent>(_handleClear);
    on<PortalUpdateTierEvent>(_handleUpdateTier);
    on<PortalFetchHoldersCountEvent>(_handleFetchHoldersCount);
    on<PortalListenSupportedTokensEvent>((event, emit) async {
      final user = state.user;
      if (user == null || user.embeddedSolanaWallets.isEmpty) return;

      final walletAddress = user.embeddedSolanaWallets.first.address;
      final stream = portalRepository.getSupportedTokens();

      await emitFromAsyncStream<List<Token>, PortalState>(
        stream: stream,
        emit: emit,
        onData: (tokens) async {
          final defaultToken = tokens.firstWhere(
            (t) => t.ticker.toUpperCase() == 'WAGUS',
            orElse: () => tokens.first,
          );

          final holdersMap = <String, Holder>{};

          for (final token in tokens) {
            final holder =
                await _getSolAndTokenBalances(walletAddress, token.address);
            holdersMap[token.ticker] = holder;
            await Future.delayed(
                const Duration(milliseconds: 200)); // to avoid API rate limits
          }

          return state.copyWith(
            supportedTokens: () => tokens,
            selectedToken: () => defaultToken,
            holdersMap: () => holdersMap,
            holder: () => holdersMap[defaultToken.ticker],
          );
        },
      );
    });

    on<PortalSetSelectedTokenEvent>((event, emit) async {
      final user = state.user;
      if (user == null || user.embeddedSolanaWallets.isEmpty) return;

      final walletAddress = user.embeddedSolanaWallets.first.address;
      final tokenMint = event.token.address;

      final updatedHolder =
          await _getSolAndTokenBalances(walletAddress, tokenMint);

      final updatedMap = Map<String, Holder>.from(state.holdersMap ?? {});
      updatedMap[event.token.ticker] = updatedHolder;

      emit(state.copyWith(
        selectedToken: () => event.token,
        holdersMap: () => updatedMap,
        holder: () => updatedHolder,
      ));
    });
  }

  Future<void> _handleInitial(
      PortalInitialEvent event, Emitter<PortalState> emit) async {
    final user = await portalRepository.connect();

    if (!PrivyService().isAuthenticated() ||
        user == null ||
        user.embeddedSolanaWallets.isEmpty) {
      debugPrint('[PortalBloc] Skipped init: user not ready');
      return;
    }

    final address = user.embeddedSolanaWallets.first.address;
    final userDoc = await UserService().getUser(address);
    final data = userDoc.data() ?? {};
    final tierString = (data['tier'] ?? 'Basic') as String;
    final expires = data['adventurer_expires'];
    final expiresAt =
        (expires is firestore.Timestamp) ? expires.toDate() : null;

    final isExpired = tierString.toLowerCase() == 'adventurer' &&
        (expiresAt == null || expiresAt.isBefore(DateTime.now()));

    final effectiveTierString = isExpired ? 'basic' : tierString;

    final tierEnum = TierStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == effectiveTierString.toLowerCase(),
      orElse: () => TierStatus.basic,
    );

    final tokensStream = portalRepository.getSupportedTokens();
    final tokens = await tokensStream.first;

    final defaultToken = tokens.firstWhere(
      (t) => t.ticker.toUpperCase() == 'WAGUS',
      orElse: () => tokens.first,
    );

    final holdersMap = <String, Holder>{};
    for (final token in tokens) {
      final holder = await _getSolAndTokenBalances(address, token.address);
      holdersMap[token.ticker] = holder;
      await Future.delayed(const Duration(milliseconds: 200));
    }

    emit(state.copyWith(
      user: () => user,
      tierStatus: tierEnum,
      supportedTokens: () => tokens,
      selectedToken: () => defaultToken,
      holdersMap: () => holdersMap,
      holder: () => holdersMap[defaultToken.ticker],
    ));

    add(PortalFetchHoldersCountEvent());
  }

  Future<void> _handleAuthorize(
      PortalAuthorizeEvent event, Emitter<PortalState> emit) async {
    final userInit = await portalRepository.init();
    if (userInit == null) return;

    var user = await portalRepository.connect();
    if (user == null) return;

    if (user.embeddedSolanaWallets.isEmpty) {
      debugPrint(
          '[PortalBloc] User has no embedded wallet — possible error on Privy side.');
      // Optional: force logout + retry login
      await PrivyService().logout(event.context);
      return;
    }

    emit(state.copyWith(user: () => user));

    final wallet = user.embeddedSolanaWallets.first.address;
    await UserService().updateUserLogin(wallet);

    if (PrivyService().isAuthenticated()) {
      if (user.embeddedSolanaWallets.isNotEmpty) {
        add(PortalInitialEvent());
      }
    }
  }

  Future<void> _handleRefresh(
      PortalRefreshEvent event, Emitter<PortalState> emit) async {
    try {
      emit(state.copyWith(isRefreshing: true));
      final user = state.user;
      final tokens = state.supportedTokens;
      if (user == null || user.embeddedSolanaWallets.isEmpty || tokens.isEmpty)
        return;

      final address = user.embeddedSolanaWallets.first.address;
      final holdersMap = <String, Holder>{};

      for (final token in tokens) {
        final cacheKey = '$address-${token.address}';
        final cached = _holderCache[cacheKey];

        if (cached != null && cached.isFresh) {
          holdersMap[token.ticker] = cached.holder;
        } else {
          final fresh = await _getSolAndTokenBalances(address, token.address);
          holdersMap[token.ticker] = fresh;
          await Future.delayed(const Duration(milliseconds: 200)); // API safety
        }
      }

      final selected = state.selectedToken.ticker;
      emit(state.copyWith(
        holdersMap: () => holdersMap,
        holder: () => holdersMap[selected],
        isRefreshing: false,
      ));
    } catch (e) {
      debugPrint('[PortalBloc] Refresh failed: $e');
      emit(state.copyWith(
        isRefreshing: false,
        holder: () => null,
        holdersMap: () => {},
      ));
    }
  }

  Future<Holder> _getSolAndTokenBalances(
      String walletAddress, String mintAddress) async {
    final cacheKey = '$walletAddress-$mintAddress';
    final cached = _holderCache[cacheKey];

    if (cached != null && cached.isFresh) {
      return cached.holder;
    }

    final rpcUrl = dotenv.env['HELIUS_RPC']!;
    final connection = web3.Connection(web3.Cluster(Uri.parse(rpcUrl)));

    final pubkey = web3.Pubkey.fromBase58(walletAddress);
    final mintPubkey = web3.Pubkey.fromBase58(mintAddress);

    // SOL balance
    final solBalanceLamports = await connection.getBalance(pubkey);
    final solBalance = solBalanceLamports / web3.lamportsPerSol;

    // Token balance
    final tokenAccounts = await connection.getTokenAccountsByOwner(
      pubkey,
      filter: web3.TokenAccountsFilter.mint(mintPubkey),
      config: web3.GetTokenAccountsByOwnerConfig(
        encoding: web3.AccountEncoding.jsonParsed,
      ),
    );

    double tokenBalance = 0;
    if (tokenAccounts.isNotEmpty) {
      final accountData = tokenAccounts.first.account.data;
      if (accountData is Map<String, dynamic>) {
        final parsed = accountData['parsed'];
        final amountStr = parsed?['info']?['tokenAmount']?['uiAmount'];
        tokenBalance = (amountStr as num?)?.toDouble() ?? 0;
      }
    }

    final holder = Holder(
      solanaAmount: solBalance,
      tokenAmount: tokenBalance,
      holderType: HolderType.plankton,
      holdings: tokenBalance,
    );

    // ✅ cache result
    _holderCache[cacheKey] = _CachedHolder(holder);

    return holder;
  }

  Future<void> _handleClear(
      PortalClearEvent event, Emitter<PortalState> emit) async {
    emit(state.copyWith(
      user: () => null,
      holder: () => null,
    ));
  }

  void _handleUpdateTier(
      PortalUpdateTierEvent event, Emitter<PortalState> emit) async {
    try {
      await UserService().upgradeTier(event.walletAddress, event.tier.name);
      emit(state.copyWith(tierStatus: event.tier));
    } catch (e) {
      debugPrint('[PortalBloc] Update tier failed: $e');
    }
  }

  Future<void> _handleFetchHoldersCount(
      PortalFetchHoldersCountEvent event, Emitter<PortalState> emit) async {
    final holdersCount =
        await portalRepository.getHoldersCount(state.selectedToken.address);
    emit(state.copyWith(holdersCount: holdersCount));
  }
}
