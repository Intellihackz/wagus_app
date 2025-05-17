import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'package:solana_web3/solana_web3.dart' as web3;
import 'package:wagus/features/portal/data/portal_repository.dart';
import 'package:wagus/services/privy_service.dart';
import 'package:wagus/services/user_service.dart';
import 'package:wagus/shared/holder/holder.dart';
import 'package:wagus/shared/token/token.dart';
import 'package:wagus/shared/transaction/transaction.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

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
    on<PortalListenTokenAddressEvent>(_handleTokenAddress);
    on<PortalClearEvent>(_handleClear);
    on<PortalUpdateTierEvent>(_handleUpdateTier);
    on<PortalFetchHoldersCountEvent>(_handleFetchHoldersCount);
    on<PortalListenSupportedTokensEvent>((event, emit) async {
      final tokensStream = portalRepository.getSupportedTokens();

      await for (final tokens in tokensStream) {
        final defaultToken = tokens.firstWhere(
          (t) => t.ticker.toUpperCase() == 'WAGUS',
          orElse: () => tokens.first,
        );

        final user = state.user;

        final walletAddress = user?.embeddedSolanaWallets.first.address;

        final holdersMap = <String, Holder>{};

        if (walletAddress != null) {
          final entries = <MapEntry<String, Holder>>[];
          for (final token in tokens) {
            final holder =
                await _getSolAndTokenBalances(walletAddress, token.address);
            entries.add(MapEntry(token.ticker, holder));
            await Future.delayed(
                const Duration(milliseconds: 200)); // avoid rate limit
          }

          holdersMap.addEntries(entries);
        }

        emit(state.copyWith(
          supportedTokens: () => tokens,
          selectedToken: () => defaultToken,
          holdersMap: () => holdersMap,
          holder: () => holdersMap[defaultToken.ticker],
        ));
        break; // stop after first emission
      }
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

    if (!PrivyService().isAuthenticated()) {
      debugPrint('[PortalBloc] Skipped init: user not ready');
      return;
    }

    //final user = await portalRepository.init();
    if (user == null || user.embeddedSolanaWallets.isEmpty) return;

    final address = user.embeddedSolanaWallets.first.address;
    final userDoc = await UserService().getUser(address);
    final tierString = (userDoc.data()?['tier'] ?? 'Basic') as String;
    final tierEnum = TierStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == tierString.toLowerCase(),
      orElse: () => TierStatus.basic,
    );

    final holdersMap = <String, Holder>{};

    if (state.supportedTokens.isEmpty) {
      emit(state.copyWith(
        user: () => user,
        holdersMap: () => holdersMap,
        tierStatus: tierEnum,
        currentTokenAddress: state.selectedToken.address,
      ));

      return;
    } else {
      emit(state.copyWith(
        user: () => user,
        holdersMap: () => holdersMap,
        tierStatus: tierEnum,
        currentTokenAddress: state.selectedToken.address,
      ));
    }

    add(PortalFetchHoldersCountEvent());

    final dio = Dio();
    final apiKey = dotenv.env['HELIUS_API_KEY'];
    final url = 'https://mainnet.helius-rpc.com/?api-key=$apiKey';
    String? cursor;
    const limit = 5;
    final accountOwners = <String>[];

    while (accountOwners.length < limit) {
      final params = {
        'jsonrpc': '2.0',
        'id': 'helius-test',
        'method': 'getTokenAccounts',
        'params': {
          'limit': 1000,
          'mint': state.selectedToken.address,
          if (cursor != null) 'cursor': cursor,
        },
      };

      try {
        final response = await dio.post(
          url,
          data: jsonEncode(params),
          options: Options(headers: {'Content-Type': 'application/json'}),
        );

        if (response.statusCode == 200) {
          final data = response.data;
          final accounts = data['result']?['token_accounts'] ?? [];
          if (accounts.isEmpty) break;

          for (var account in accounts) {
            final owner = account['owner'];
            if (!accountOwners.contains(owner) &&
                accountOwners.length < limit) {
              accountOwners.add(owner);
            }
          }

          cursor = data['result']['cursor'] as String?;
          if (cursor == null) break;
        } else {
          break;
        }
      } catch (e) {
        break;
      }
    }

    debugPrint('Account owners: $accountOwners');
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

    add(PortalListenSupportedTokensEvent());

    if (PrivyService().isAuthenticated()) {
      add(PortalInitialEvent());
      add(PortalListenSupportedTokensEvent());
    }
  }

  Future<void> _handleRefresh(
      PortalRefreshEvent event, Emitter<PortalState> emit) async {
    try {
      final user = state.user;
      final tokens = state.supportedTokens;
      if (user == null || user.embeddedSolanaWallets.isEmpty || tokens.isEmpty)
        return;

      final address = user.embeddedSolanaWallets.first.address;
      final entries = await Future.wait(tokens.map((token) async {
        final holder = await _getSolAndTokenBalances(address, token.address);
        return MapEntry(token.ticker, holder);
      }));

      final holdersMap = Map<String, Holder>.fromEntries(entries);
      final selectedTicker = state.selectedToken.ticker;

      emit(state.copyWith(
        holdersMap: () => holdersMap,
        holder: () => holdersMap[selectedTicker],
      ));
    } catch (e) {
      debugPrint('[PortalBloc] Refresh failed: $e');
      emit(state.copyWith(holder: () => null));
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

  Future<void> _handleTokenAddress(
      PortalListenTokenAddressEvent event, Emitter<PortalState> emit) async {}

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
