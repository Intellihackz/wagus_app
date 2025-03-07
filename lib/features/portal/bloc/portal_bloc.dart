import 'dart:math' as Math;

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:flutter/material.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'package:solana_web3/solana_web3.dart' as web3;
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

    on<PortalGetTransactionsEvent>(_onPortalGetTransactionsEvent);
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
      holder = await getTokenAccounts(userAddress);

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

  Future<void> _onPortalGetTransactionsEvent(
    PortalGetTransactionsEvent event,
    Emitter<PortalState> emit,
  ) async {
    final user = state.user;
    Holder? holder = state.holder;
    List<Transaction> transactions = [];

    if (user != null && holder != null) {
      final userAddress = user.embeddedSolanaWallets.first.address;

      // Fetch holder info for the user (already done, but kept for consistency)
      holder = await getTokenAccounts(userAddress);

      // Fetch total number of holders for the TM token mint address
      final holdersCount = await portalRepository.getHoldersCount();
      emit(state.copyWith(holdersCount: holdersCount));

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

      // Fetch recent transactions for the sampled account owners
      Map<String, Holder> accountHolders = {};
      for (var owner in accountOwners) {
        final transactionData = await portalRepository
            .getRecentTransactions(owner, limit: 10); // Increased limit to 10

        for (var tx in transactionData) {
          List<Holder> transactionHolders = [];
          double solAmount = 0.0; // Track total SOL amount

          final tokenTransfers = tx['tokenTransfers'] as List<dynamic>? ?? [];
          if (tokenTransfers.isEmpty) {
            debugPrint('No token transfers found in this SWAP transaction');
          }
          for (var transfer in tokenTransfers) {
            final mint = transfer['mint'] as String?;
            if (mint == tmAddress) {
              final amount =
                  (transfer['tokenAmount'] as num?)?.toDouble() ?? 0.0;
              final humanReadableAmount =
                  amount / Math.pow(10, 6); // Assuming 6 decimals for TM

              final fromAccount = transfer['fromAccount'] as String?;
              final toAccount = transfer['toAccount'] as String?;

              // Update or create Holder for fromAccount
              if (fromAccount != null) {
                final newHolder = accountHolders[fromAccount]?.copyWith(
                      tokenAmount:
                          (accountHolders[fromAccount]?.tokenAmount ?? 0) -
                              humanReadableAmount,
                    ) ??
                    Holder(
                      holderType: determineHolderType(-humanReadableAmount),
                      holdings: 0,
                      tokenAmount: -humanReadableAmount,
                    );
                accountHolders[fromAccount] = newHolder;
                transactionHolders.add(newHolder);
              }

              // Update or create Holder for toAccount
              if (toAccount != null) {
                final newHolder = accountHolders[toAccount]?.copyWith(
                      tokenAmount:
                          (accountHolders[toAccount]?.tokenAmount ?? 0) +
                              humanReadableAmount,
                    ) ??
                    Holder(
                      holderType: determineHolderType(humanReadableAmount),
                      holdings: 0,
                      tokenAmount: humanReadableAmount,
                    );
                accountHolders[toAccount] = newHolder;
                transactionHolders.add(newHolder);
              }
            }
          }

          // Process native transfers (SOL)
          final nativeTransfers = tx['nativeTransfers'] as List<dynamic>? ?? [];
          double totalSolSent = 0.0; // Track total SOL sent by fromUserAccount
          for (var transfer in nativeTransfers) {
            final amount = (transfer['amount'] as num?)?.toDouble() ?? 0.0;
            final humanReadableAmount =
                amount / web3.lamportsPerSol; // Convert lamports to SOL

            final fromUserAccount = transfer['fromUserAccount'] as String?;
            final toUserAccount = transfer['toUserAccount'] as String?;

            // Update or create Holder for fromUserAccount
            if (fromUserAccount != null) {
              final newHolder = accountHolders[fromUserAccount]?.copyWith(
                    holdings: (accountHolders[fromUserAccount]?.holdings ?? 0) -
                        humanReadableAmount,
                  ) ??
                  Holder(
                    holderType: determineHolderType(-humanReadableAmount),
                    holdings: -humanReadableAmount,
                    tokenAmount: 0,
                  );
              accountHolders[fromUserAccount] = newHolder;
              transactionHolders.add(newHolder);
              totalSolSent += humanReadableAmount; // Accumulate total SOL sent
            }

            // Update or create Holder for toUserAccount
            if (toUserAccount != null) {
              final newHolder = accountHolders[toUserAccount]?.copyWith(
                    holdings: (accountHolders[toUserAccount]?.holdings ?? 0) +
                        humanReadableAmount,
                  ) ??
                  Holder(
                    holderType: determineHolderType(humanReadableAmount),
                    holdings: humanReadableAmount,
                    tokenAmount: 0,
                  );
              accountHolders[toUserAccount] = newHolder;
              transactionHolders.add(newHolder);
            }
          }

          // Use the total SOL sent as the transaction amount
          solAmount = totalSolSent;

          // Fallback: If no transfers, use feePayer or accounts from accountData
          if (transactionHolders.isEmpty) {
            final accounts = (tx['accountData'] as List<dynamic>?)
                    ?.map((account) => account['account'] as String)
                    .toList() ??
                [];
            final feePayer = tx['feePayer'] as String?;
            if (feePayer != null && !accounts.contains(feePayer)) {
              accounts.insert(0, feePayer);
            }

            for (var account in accounts) {
              accountHolders[account] = accountHolders[account] ??
                  Holder(
                    holderType: HolderType.plankton,
                    holdings: 0,
                    tokenAmount: 0,
                  );
              transactionHolders.add(accountHolders[account]!);
            }

            final fee = (tx['fee'] as num?)?.toDouble() ?? 0.0;
            solAmount = fee / web3.lamportsPerSol;
          }

          // Process transactions based on solAmount
          if (transactionHolders.isNotEmpty && solAmount > 0) {
            final transactionAmount =
                solAmount; // Use solAmount as the primary metric
            final holderType = determineHolderType(
                transactionAmount); // Determine based on solAmount
            final primaryHolder = holder;
            final updatedHolder = primaryHolder.copyWith(
              holderType: holderType,
            );

            transactions.add(Transaction(
              holder: updatedHolder,
              amount: transactionAmount,
            ));
          } else {
            debugPrint('Skipping transaction: solAmount=$solAmount');
          }
        }
      }
    }

    final groupedTransactions = groupTransactions(transactions);

    emit(state.copyWith(
      groupedTransactions: groupedTransactions,
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

  HolderType determineHolderType(double amount) {
    if (amount.abs() >= 10.0) return HolderType.whale;
    if (amount.abs() >= 1.0) return HolderType.shark;
    if (amount.abs() >= 0.1) return HolderType.shrimp;
    return HolderType.plankton;
  }

  Future<Holder> getTokenAccounts(String address) async {
    final cluster = web3.Cluster.mainnet;
    final connection = web3.Connection(cluster);
    final publicKey = web3.Pubkey.fromBase58(address);

    final splTokenKey =
        web3.Pubkey.fromBase58('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA');

    try {
      final tokenAccounts = await connection.getTokenAccountsByOwner(
        publicKey,
        filter: web3.TokenAccountsFilter.programId(splTokenKey),
      );

      final tokenKey = web3.Pubkey.fromString(tokenAccounts.first.pubkey);

      final tokenAccountBalance = await connection.getTokenAccountBalance(
        tokenKey,
      );

      final tokensInSol =
          tokenAccounts.first.account.lamports / web3.lamportsPerSol;
      final tokenAmount = double.parse(tokenAccountBalance.uiAmountString);

      final holderType = determineHolderType(tokenAmount);

      return Holder(
        holderType: holderType,
        holdings: tokensInSol,
        tokenAmount: tokenAmount,
      );
    } catch (e) {
      debugPrint('Error in getTokenAccounts: $e');
      return Holder(
        holderType: HolderType.plankton,
        holdings: 0,
        tokenAmount: 0,
      );
    }
  }
}
