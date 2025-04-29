import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:privy_flutter/privy_flutter.dart';
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
    on<PortalInitialEvent>((event, emit) async {
      await _setTokenAddress(emit);

      // Only proceed if user is already authenticated (from email login, for example)
      final alreadyInit = PrivyService().isAuthenticated();
      if (alreadyInit) {
        await _onPortalInitialEvent(event, emit);

        final user = await portalRepository.init();
        if (user != null && user.embeddedSolanaWallets.isNotEmpty) {
          final wallet = user.embeddedSolanaWallets.first.address;
          final userDoc = await UserService().getUser(wallet);
          final userData = userDoc.data();

          final tierString = (userData?['tier'] ?? 'Basic') as String;

          // Convert String -> TierStatus enum
          final tierEnum = TierStatus.values.firstWhere(
            (e) => e.name.toLowerCase() == tierString.toLowerCase(),
            orElse: () => TierStatus.basic, // fallback in case it's invalid
          );

          emit(state.copyWith(tierStatus: tierEnum));
        }
      } else {
        debugPrint(
            '[PortalBloc] Skipped _onPortalInitialEvent: user not ready');
      }
    });

    on<PortalAuthorizeEvent>((event, emit) async {
      final userInit = await portalRepository.init();
      if (userInit == null) {
        debugPrint('Privy initialization failed');
        return;
      }

      final user = await portalRepository.connect();
      emit(state.copyWith(user: () => user));

      if (user != null && user.embeddedSolanaWallets.isNotEmpty) {
        final wallet = user.embeddedSolanaWallets.first.address;
        await UserService().updateUserLogin(wallet);
      }

      if (PrivyService().isAuthenticated()) {
        await _onPortalInitialEvent(PortalInitialEvent(), emit);
      }
    });

    on<PortalRefreshEvent>((event, emit) async {
      final holder = await portalRepository.getTokenAccounts(
          state.user!.embeddedSolanaWallets.first.address,
          state.currentTokenAddress);
      final holdersCount =
          await portalRepository.getHoldersCount(state.currentTokenAddress);
      emit(state.copyWith(
        holdersCount: holdersCount,
        holder: () => holder,
      ));
    });

    on<PortalListenTokenAddressEvent>((event, emit) async {
      await emit.forEach(portalRepository.getCurrentTokenAddress(),
          onData: (tokenAddress) {
        final currentTokenAddress = tokenAddress.docs.map((doc) {
          return doc.data() as Map<String, dynamic>;
        }).first['address'];
        debugPrint('Token address updated: $currentTokenAddress');
        return state.copyWith(currentTokenAddress: currentTokenAddress);
      });
    });

    on<PortalClearEvent>((event, emit) async {
      emit(state.copyWith(
        user: () => null,
        holder: () => null,
      ));
    });

    on<PortalUpdateTierEvent>((event, emit) {
      emit(state.copyWith(tierStatus: event.tier));
    });
  }

  Future<void> _setTokenAddress(Emitter<PortalState> emit) async {
    final tokenAddressSnapshot =
        await portalRepository.getCurrentTokenAddress().first;
    final currentTokenAddress = tokenAddressSnapshot.docs.map((doc) {
      return doc.data() as Map<String, dynamic>;
    }).first['address'];
    emit(state.copyWith(currentTokenAddress: currentTokenAddress));
  }

  Future<void> _onPortalInitialEvent(
    PortalInitialEvent event,
    Emitter<PortalState> emit,
  ) async {
    debugPrint(
        'Starting initial event with token address: ${state.currentTokenAddress}');

    final user = await portalRepository.init();
    Holder? holder;
    int? holdersCount;

    if (user != null) {
      if (user.embeddedSolanaWallets.isEmpty) {
        debugPrint('No embedded wallets found');
        return;
      }

      final userAddress = user.embeddedSolanaWallets.first.address;
      debugPrint('Fetching holder for $userAddress');

      holder = await portalRepository.getTokenAccounts(
          userAddress, state.currentTokenAddress);
      debugPrint('Holder: ${holder.toJson()}');

      holdersCount =
          await portalRepository.getHoldersCount(state.currentTokenAddress);
      debugPrint('Holders count: $holdersCount');

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
          debugPrint('Helius API response: ${response.data}');

          if (response.statusCode == 200) {
            final data = response.data;
            if (data['result'] == null ||
                data['result']['token_accounts'] == null) {
              debugPrint('No more token accounts');
              break;
            }

            final accounts = data['result']['token_accounts'] as List<dynamic>;
            if (accounts.isEmpty) {
              debugPrint('No token accounts found');
              break;
            }

            for (var account in accounts) {
              final owner = account['owner'] as String;
              if (!accountOwners.contains(owner) &&
                  accountOwners.length < limit) {
                accountOwners.add(owner);
              }
              if (accountOwners.length >= limit) break;
            }
            cursor = data['result']['cursor'] as String?;
            if (cursor == null) break;
          } else {
            debugPrint(
                'Helius API error: ${response.statusCode} - ${response.data}');
            break;
          }
        } catch (e) {
          debugPrint('Error fetching token accounts: $e');
          break;
        }
      }
      debugPrint('Account owners: $accountOwners');
    }

    emit(state.copyWith(
      holdersCount: holdersCount,
      user: () => user,
      holder: () => holder,
    ));
  }
}
