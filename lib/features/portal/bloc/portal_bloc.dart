import 'dart:math' as Math;

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'package:wagus/features/portal/data/portal_repository.dart';
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
      : super(const PortalState(groupedTransactions: [])) {
    on<PortalInitialEvent>(_onPortalInitialEvent);

    on<PortalAuthorizeEvent>((event, emit) async {
      final user = await portalRepository.connect();
      emit(state.copyWith(user: () => user));
    });

    on<PortalRefreshEvent>((event, emit) async {
      final holder = await portalRepository
          .getTokenAccounts(state.user!.embeddedSolanaWallets.first.address);
      final holdersCount = await portalRepository.getHoldersCount();

      emit(state.copyWith(
        holdersCount: holdersCount,
        holder: () => holder,
      ));
    });
  }

  Future<void> _onPortalInitialEvent(
    PortalInitialEvent event,
    Emitter<PortalState> emit,
  ) async {
    final user = await portalRepository.init();
    Holder? holder;
    int? holdersCount;

    if (user != null) {
      final userAddress = user.embeddedSolanaWallets.first.address;

      // Fetch holder info for the user
      holder = await portalRepository.getTokenAccounts(userAddress);

      // Fetch total number of holders for the TM token mint address
      holdersCount = await portalRepository.getHoldersCount();

      // Fetch token accounts for the TM mint address to get account owners
      const tmAddress =
          'YLu5uLRfZTLMCY9m2CBJ1czWuNJCwFkctnXn4zcrGFM'; // Verify this is the correct mint address
      final dio = Dio();
      final apiKey = dotenv.env['HELIUS_API_KEY'];
      final url = 'https://mainnet.helius-rpc.com/?api-key=$apiKey';
      String? cursor;
      const limit = 5; // Limit to 5 accounts for this example

      final accountOwners = <String>[];
      while (accountOwners.length < limit) {
        final params = {
          'jsonrpc': '2.0',
          'id': 'helius-test',
          'method': 'getTokenAccounts',
          'params': {
            'limit': 1000,
            'mint': tmAddress,
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
            if (cursor == null) {
              debugPrint('No more pages (cursor is null)');
              break;
            }
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

      if (accountOwners.isEmpty) {
        debugPrint('No account owners found for tmAddress: $tmAddress');
      }
    }

    emit(state.copyWith(
      holdersCount: holdersCount,
      user: () => user,
      holder: () => holder,
    ));
  }

  List<List<Transaction>> groupTransactions(List<Transaction> transactions) {
    final grouped = <List<Transaction>>[];
    for (var i = 0; i < transactions.length; i += 3) {
      final end = Math.min(i + 3, transactions.length);
      grouped.add(transactions.sublist(i, end));
    }
    return grouped;
  }
}
