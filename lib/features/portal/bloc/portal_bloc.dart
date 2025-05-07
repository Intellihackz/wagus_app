import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'package:solana_web3/solana_web3.dart' as web3;
import 'package:wagus/features/portal/data/portal_repository.dart';
import 'package:wagus/services/privy_service.dart';
import 'package:wagus/services/user_service.dart';
import 'package:wagus/shared/holder/holder.dart';
import 'package:wagus/shared/transaction/transaction.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

part 'portal_event.dart';
part 'portal_state.dart';

class PortalBloc extends Bloc<PortalEvent, PortalState> {
  final PortalRepository portalRepository;

  PortalBloc({required this.portalRepository})
      : super(const PortalState(currentTokenAddress: '')) {
    on<PortalInitialEvent>(_handleInitial);
    on<PortalAuthorizeEvent>(_handleAuthorize);
    on<PortalRefreshEvent>(_handleRefresh);
    on<PortalListenTokenAddressEvent>(_handleTokenAddress);
    on<PortalClearEvent>(_handleClear);
    on<PortalUpdateTierEvent>(_handleUpdateTier);
    on<PortalFetchHoldersCountEvent>(_handleFetchHoldersCount);
  }

  Future<void> _handleInitial(
      PortalInitialEvent event, Emitter<PortalState> emit) async {
    await _setTokenAddress(emit);

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

    // Fetch SOL + token balances
    final holder =
        await _getSolAndTokenBalances(address, state.currentTokenAddress);

    emit(state.copyWith(
      user: () => user,
      holder: () => holder,
      tierStatus: tierEnum,
    ));

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
          'mint': state.currentTokenAddress,
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

    final user = await portalRepository.connect();
    emit(state.copyWith(user: () => user));

    if (user != null && user.embeddedSolanaWallets.isNotEmpty) {
      final wallet = user.embeddedSolanaWallets.first.address;
      await UserService().updateUserLogin(wallet);
    }

    if (PrivyService().isAuthenticated()) {
      add(PortalInitialEvent());
    }
  }

  Future<void> _handleRefresh(
      PortalRefreshEvent event, Emitter<PortalState> emit) async {
    try {
      final user = state.user;
      if (user == null || user.embeddedSolanaWallets.isEmpty) return;

      final address = user.embeddedSolanaWallets.first.address;

      final holder =
          await _getSolAndTokenBalances(address, state.currentTokenAddress);

      final holdersCount =
          await portalRepository.getHoldersCount(state.currentTokenAddress);

      emit(state.copyWith(
        holdersCount: holdersCount,
        holder: () => holder,
      ));
    } catch (e) {
      debugPrint('[PortalBloc] Refresh failed: $e');
      emit(state.copyWith(holder: () => null));
    }
  }

  Future<Holder> _getSolAndTokenBalances(
      String walletAddress, String mintAddress) async {
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
          encoding: web3.AccountEncoding.jsonParsed),
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

    return Holder(
      solanaAmount: solBalance,
      tokenAmount: tokenBalance,
      holderType: HolderType.plankton,
      holdings: tokenBalance,
    );
  }

  Future<void> _handleTokenAddress(
      PortalListenTokenAddressEvent event, Emitter<PortalState> emit) async {
    await emit.forEach(portalRepository.getCurrentTokenAddress(),
        onData: (snapshot) {
      final currentTokenAddress = snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).first['address'];
      debugPrint('Token address updated: $currentTokenAddress');
      return state.copyWith(currentTokenAddress: currentTokenAddress);
    });
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
        await portalRepository.getHoldersCount(state.currentTokenAddress);
    emit(state.copyWith(holdersCount: holdersCount));
  }

  Future<void> _setTokenAddress(Emitter<PortalState> emit) async {
    final tokenAddressSnapshot =
        await portalRepository.getCurrentTokenAddress().first;
    final currentTokenAddress = tokenAddressSnapshot.docs.map((doc) {
      return doc.data() as Map<String, dynamic>;
    }).first['address'];
    emit(state.copyWith(currentTokenAddress: currentTokenAddress));
  }
}
