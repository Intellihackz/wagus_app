import 'dart:async';
import 'dart:convert';
import 'dart:math' as Math;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'package:solana_web3/solana_web3.dart' as web3;
import 'package:wagus/constants.dart';
import 'package:wagus/services/privy_service.dart';
import 'package:flutter/material.dart';
import 'package:wagus/shared/holder/holder.dart';

class PortalRepository {
  PortalRepository();
  final _privyService = PrivyService();

  Future<PrivyUser?> init() async {
    final user = await PrivyService().initialize();

    return user;
  }

  Future<PrivyUser?> connect() async {
    try {
      final user = _privyService.privy.user;
      if (user != null) {
        var solanaWallet = user.embeddedSolanaWallets;
        if (solanaWallet.isNotEmpty) {
          debugPrint('Solana wallet already exists');
          return user;
        }

        final Completer<PrivyUser?> completer = Completer<PrivyUser?>();

        final walletResult = await user.createSolanaWallet();
        walletResult.fold(
          onSuccess: (wallet) {
            debugPrint('Solana wallet created successfully');
            completer.complete(user);
          },
          onFailure: (error) {
            debugPrint('Error creating Solana wallet: ${error.message}');
            completer.complete(null);
          },
        );

        return completer.future;
      }
    } catch (e) {
      debugPrint('Error connecting wallet: $e');
    }
    return null;
  }

  /// [disconnect] function to disconnect the wallet
  Future<bool?> disconnect() async {
    final success = await _privyService.logout();
    return success ? true : null;
  }

  Future<Holder> getTokenAccounts(String address) async {
    final cluster = web3.Cluster.mainnet;
    final connection = web3.Connection(cluster);
    final publicKey = web3.Pubkey.fromBase58(address);

    // final splTokenKey =
    //     web3.Pubkey.fromBase58('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA');

    final wagusTokenKey = web3.Pubkey.fromBase58(mintToken);

    try {
      // Get SPL Token Accounts
      final tokenAccounts = await connection.getTokenAccountsByOwner(
        publicKey,
        filter: web3.TokenAccountsFilter.mint(wagusTokenKey),
      );

      final tokenKey = web3.Pubkey.fromString(tokenAccounts.first.pubkey);

      final tokenAccountBalance =
          await connection.getTokenAccountBalance(tokenKey);

      final tokensInSol =
          tokenAccounts.first.account.lamports / web3.lamportsPerSol;
      final tokenAmount = double.parse(tokenAccountBalance.uiAmountString);

      // ✅ Get SOL balance in human-readable format
      final solLamports = await connection.getBalance(publicKey);
      final solAmount = solLamports / web3.lamportsPerSol;

      final holderType = determineHolderType(tokenAmount);

      return Holder(
        holderType: holderType,
        holdings: tokensInSol,
        tokenAmount: tokenAmount,
        solanaAmount: solAmount,
      );
    } catch (e) {
      debugPrint('Error in getTokenAccounts: $e');
      return Holder(
        holderType: HolderType.plankton,
        holdings: 0,
        tokenAmount: 0,
        solanaAmount: 0,
      );
    }
  }

  HolderType determineHolderType(double amount) {
    if (amount.abs() >= 10.0) return HolderType.whale;
    if (amount.abs() >= 1.0) return HolderType.shark;
    if (amount.abs() >= 0.1) return HolderType.shrimp;
    return HolderType.plankton;
  }

  /// [getHoldersCount] function to get the number of holders
  Future<int> getHoldersCount() async {
    final dio = Dio();
    final apiKey = dotenv.env['HELIUS_API_KEY'];
    final url = 'https://mainnet.helius-rpc.com/?api-key=$apiKey';
    const tokenAddress = 'YLu5uLRfZTLMCY9m2CBJ1czWuNJCwFkctnXn4zcrGFM';
    final Set<String> allOwners = <String>{};
    String? cursor;
    int page = 1;

    while (true) {
      final params = {
        'jsonrpc': '2.0',
        'id': 'helius-test',
        'method': 'getTokenAccounts',
        'params': {
          'limit': 1000,
          'mint': tokenAddress,
          if (cursor != null) 'cursor': cursor,
        },
      };

      try {
        print('Fetching page $page with cursor: $cursor');
        final response = await dio.post(
          url,
          data: jsonEncode(params),
          options: Options(
            headers: {'Content-Type': 'application/json'},
          ),
        );

        if (response.statusCode == 200) {
          final data = response.data;
          if (data['result'] == null ||
              data['result']['token_accounts'] == null) {
            print('No more results');
            break;
          }

          final accounts = data['result']['token_accounts'] as List<dynamic>;
          if (accounts.isEmpty) {
            print('No more accounts');
            break;
          }

          print('Found ${accounts.length} accounts on page $page');
          for (var account in accounts) {
            final owner = account['owner'] as String;
            allOwners.add(owner);
          }
          print('Total unique holders after page $page: ${allOwners.length}');

          cursor = data['result']['cursor'] as String?;
          if (cursor == null) {
            print('No more pages (cursor is null)');
            break;
          }
          page++;
        } else {
          print('Helius API error: ${response.statusCode} - ${response.data}');
          break;
        }
      } catch (e) {
        print('Error fetching holders from Helius: $e');
        break;
      }
    }

    final holderCount = allOwners.length;
    print(
        'Found $holderCount unique holders for TM/SOL pool LP token via Helius');
    return holderCount;
  }

  /// [getRecentTransactions] function to fetch a few recent transactions for a Solana address
  Future<List<dynamic>> getRecentTransactions(String address,
      {int limit = 5}) async {
    final dio = Dio();
    final apiKey = dotenv.env['HELIUS_API_KEY'];
    final baseUrl =
        'https://api.helius.xyz/v0/addresses/$address/transactions?api-key=$apiKey';
    final url =
        '$baseUrl&limit=$limit&type=SWAP'; // Filter for SWAP transactions

    try {
      debugPrint('Fetching recent transactions for address: $address');
      final response = await dio.get(
        url,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        final transactions = response.data as List<dynamic>;
        if (transactions.isNotEmpty) {
          debugPrint('Fetched ${transactions.length} recent transactions');
          return transactions;
        } else {
          debugPrint('No SWAP transactions found for address: $address');
          return [];
        }
      } else {
        debugPrint(
            'Helius API error: ${response.statusCode} - ${response.data}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching transactions from Helius: $e');
      return [];
    }
  }

  /// [getTotalTokenBalance] function to calculate the total TM balance for an address
  Future<double> getTotalTokenBalance(String address, String tokenMint,
      {int decimals = 6}) async {
    final dio = Dio();
    final apiKey = dotenv.env['HELIUS_API_KEY'];
    final url = 'https://mainnet.helius-rpc.com/?api-key=$apiKey';
    double totalBalance = 0.0;
    String? cursor;

    while (true) {
      final params = {
        'jsonrpc': '2.0',
        'id': 'helius-test',
        'method': 'getTokenAccounts',
        'params': {
          'limit': 1000,
          'mint': tokenMint,
          'owner': address,
          if (cursor != null) 'cursor': cursor,
        },
      };

      try {
        debugPrint(
            'Fetching token accounts for address: $address with cursor: $cursor');
        final response = await dio.post(
          url,
          data: jsonEncode(params),
          options: Options(
            headers: {'Content-Type': 'application/json'},
          ),
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
            final amount = (account['amount'] as num?)?.toDouble() ?? 0.0;
            totalBalance += amount /
                Math.pow(10, decimals); // Convert to human-readable amount
          }
          debugPrint('Current total balance: $totalBalance TM');

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
        debugPrint('Error fetching token balance from Helius: $e');
        break;
      }
    }

    return totalBalance;
  }

  /// [getRecentTokenTransactionValue] function to get the value of the most recent TM transaction
  Future<double?> getRecentTokenTransactionValue(
      String address, String tokenMint,
      {int decimals = 6}) async {
    final transactions = await getRecentTransactions(address,
        limit: 1); // Get the most recent transaction
    if (transactions.isEmpty) {
      debugPrint('No recent transactions found');
      return null;
    }

    final recentTx = transactions.first;
    final tokenTransfers = recentTx['tokenTransfers'] as List<dynamic>? ?? [];

    for (var transfer in tokenTransfers) {
      final mint = transfer['mint'] as String?;
      if (mint == tokenMint) {
        final amount = (transfer['tokenAmount'] as num?)?.toDouble() ?? 0.0;
        return amount /
            Math.pow(10, decimals); // Convert to human-readable amount
      }
    }

    debugPrint('No TM token transfer found in the recent transaction');
    return null;
  }

  // Future<void> _onPortalGetTransactionsEvent(
  //   PortalGetTransactionsEvent event,
  //   Emitter<PortalState> emit,
  // ) async {
  //   final user = state.user;
  //   Holder? holder = state.holder;
  //   List<Transaction> transactions = [];

  //   if (user != null && holder != null) {
  //     final userAddress = user.embeddedSolanaWallets.first.address;

  //     // Fetch holder info for the user (already done, but kept for consistency)
  //     holder = await getTokenAccounts(userAddress);

  //     // Fetch total number of holders for the TM token mint address
  //     final holdersCount = await portalRepository.getHoldersCount();
  //     emit(state.copyWith(holdersCount: holdersCount));

  //     // Fetch token accounts for the TM mint address to get account owners
  //     const tmAddress =
  //         'YLu5uLRfZTLMCY9m2CBJ1czWuNJCwFkctnXn4zcrGFM'; // Verify this is the correct mint address
  //     final dio = Dio();
  //     final apiKey = dotenv.env['HELIUS_API_KEY'];
  //     final url = 'https://mainnet.helius-rpc.com/?api-key=$apiKey';
  //     String? cursor;
  //     const limit = 5; // Limit to 5 accounts for this example

  //     final accountOwners = <String>[];
  //     while (accountOwners.length < limit) {
  //       final params = {
  //         'jsonrpc': '2.0',
  //         'id': 'helius-test',
  //         'method': 'getTokenAccounts',
  //         'params': {
  //           'limit': 1000,
  //           'mint': tmAddress,
  //           if (cursor != null) 'cursor': cursor,
  //         },
  //       };

  //       try {
  //         final response = await dio.post(
  //           url,
  //           data: jsonEncode(params),
  //           options: Options(headers: {'Content-Type': 'application/json'}),
  //         );

  //         if (response.statusCode == 200) {
  //           final data = response.data;
  //           if (data['result'] == null ||
  //               data['result']['token_accounts'] == null) {
  //             debugPrint('No more token accounts');
  //             break;
  //           }

  //           final accounts = data['result']['token_accounts'] as List<dynamic>;
  //           if (accounts.isEmpty) {
  //             break;
  //           }

  //           for (var account in accounts) {
  //             final owner = account['owner'] as String;
  //             if (!accountOwners.contains(owner) &&
  //                 accountOwners.length < limit) {
  //               accountOwners.add(owner);
  //             }
  //             if (accountOwners.length >= limit) break;
  //           }
  //           cursor = data['result']['cursor'] as String?;
  //           if (cursor == null) {
  //             break;
  //           }
  //         } else {
  //           debugPrint(
  //               'Helius API error: ${response.statusCode} - ${response.data}');
  //           break;
  //         }
  //       } catch (e) {
  //         debugPrint('Error fetching token accounts: $e');
  //         break;
  //       }
  //     }

  //     if (accountOwners.isEmpty) {
  //       debugPrint('No account owners found for tmAddress: $tmAddress');
  //     }

  //     // Fetch recent transactions for the sampled account owners
  //     Map<String, Holder> accountHolders = {};
  //     for (var owner in accountOwners) {
  //       final transactionData = await portalRepository
  //           .getRecentTransactions(owner, limit: 10); // Increased limit to 10

  //       for (var tx in transactionData) {
  //         List<Holder> transactionHolders = [];
  //         double solAmount = 0.0; // Track total SOL amount

  //         final tokenTransfers = tx['tokenTransfers'] as List<dynamic>? ?? [];
  //         if (tokenTransfers.isEmpty) {
  //           debugPrint('No token transfers found in this SWAP transaction');
  //         }
  //         for (var transfer in tokenTransfers) {
  //           final mint = transfer['mint'] as String?;
  //           if (mint == tmAddress) {
  //             final amount =
  //                 (transfer['tokenAmount'] as num?)?.toDouble() ?? 0.0;
  //             final humanReadableAmount =
  //                 amount / Math.pow(10, 6); // Assuming 6 decimals for TM

  //             final fromAccount = transfer['fromAccount'] as String?;
  //             final toAccount = transfer['toAccount'] as String?;

  //             // Update or create Holder for fromAccount
  //             if (fromAccount != null) {
  //               final newHolder = accountHolders[fromAccount]?.copyWith(
  //                     tokenAmount:
  //                         (accountHolders[fromAccount]?.tokenAmount ?? 0) -
  //                             humanReadableAmount,
  //                   ) ??
  //                   Holder(
  //                     holderType: determineHolderType(-humanReadableAmount),
  //                     holdings: 0,
  //                     tokenAmount: -humanReadableAmount,
  //                   );
  //               accountHolders[fromAccount] = newHolder;
  //               transactionHolders.add(newHolder);
  //             }

  //             // Update or create Holder for toAccount
  //             if (toAccount != null) {
  //               final newHolder = accountHolders[toAccount]?.copyWith(
  //                     tokenAmount:
  //                         (accountHolders[toAccount]?.tokenAmount ?? 0) +
  //                             humanReadableAmount,
  //                   ) ??
  //                   Holder(
  //                     holderType: determineHolderType(humanReadableAmount),
  //                     holdings: 0,
  //                     tokenAmount: humanReadableAmount,
  //                   );
  //               accountHolders[toAccount] = newHolder;
  //               transactionHolders.add(newHolder);
  //             }
  //           }
  //         }

  //         // Process native transfers (SOL)
  //         final nativeTransfers = tx['nativeTransfers'] as List<dynamic>? ?? [];
  //         double totalSolSent = 0.0; // Track total SOL sent by fromUserAccount
  //         for (var transfer in nativeTransfers) {
  //           final amount = (transfer['amount'] as num?)?.toDouble() ?? 0.0;
  //           final humanReadableAmount =
  //               amount / web3.lamportsPerSol; // Convert lamports to SOL

  //           final fromUserAccount = transfer['fromUserAccount'] as String?;
  //           final toUserAccount = transfer['toUserAccount'] as String?;

  //           // Update or create Holder for fromUserAccount
  //           if (fromUserAccount != null) {
  //             final newHolder = accountHolders[fromUserAccount]?.copyWith(
  //                   holdings: (accountHolders[fromUserAccount]?.holdings ?? 0) -
  //                       humanReadableAmount,
  //                 ) ??
  //                 Holder(
  //                   holderType: determineHolderType(-humanReadableAmount),
  //                   holdings: -humanReadableAmount,
  //                   tokenAmount: 0,
  //                 );
  //             accountHolders[fromUserAccount] = newHolder;
  //             transactionHolders.add(newHolder);
  //             totalSolSent += humanReadableAmount; // Accumulate total SOL sent
  //           }

  //           // Update or create Holder for toUserAccount
  //           if (toUserAccount != null) {
  //             final newHolder = accountHolders[toUserAccount]?.copyWith(
  //                   holdings: (accountHolders[toUserAccount]?.holdings ?? 0) +
  //                       humanReadableAmount,
  //                 ) ??
  //                 Holder(
  //                   holderType: determineHolderType(humanReadableAmount),
  //                   holdings: humanReadableAmount,
  //                   tokenAmount: 0,
  //                 );
  //             accountHolders[toUserAccount] = newHolder;
  //             transactionHolders.add(newHolder);
  //           }
  //         }

  //         // Use the total SOL sent as the transaction amount
  //         solAmount = totalSolSent;

  //         // Fallback: If no transfers, use feePayer or accounts from accountData
  //         if (transactionHolders.isEmpty) {
  //           final accounts = (tx['accountData'] as List<dynamic>?)
  //                   ?.map((account) => account['account'] as String)
  //                   .toList() ??
  //               [];
  //           final feePayer = tx['feePayer'] as String?;
  //           if (feePayer != null && !accounts.contains(feePayer)) {
  //             accounts.insert(0, feePayer);
  //           }

  //           for (var account in accounts) {
  //             accountHolders[account] = accountHolders[account] ??
  //                 Holder(
  //                   holderType: HolderType.plankton,
  //                   holdings: 0,
  //                   tokenAmount: 0,
  //                 );
  //             transactionHolders.add(accountHolders[account]!);
  //           }

  //           final fee = (tx['fee'] as num?)?.toDouble() ?? 0.0;
  //           solAmount = fee / web3.lamportsPerSol;
  //         }

  //         // Process transactions based on solAmount
  //         if (transactionHolders.isNotEmpty && solAmount > 0) {
  //           final transactionAmount =
  //               solAmount; // Use solAmount as the primary metric
  //           final holderType = determineHolderType(
  //               transactionAmount); // Determine based on solAmount
  //           final primaryHolder = holder;
  //           final updatedHolder = primaryHolder.copyWith(
  //             holderType: holderType,
  //           );

  //           transactions.add(Transaction(
  //             holder: updatedHolder,
  //             amount: transactionAmount,
  //           ));
  //         } else {
  //           debugPrint('Skipping transaction: solAmount=$solAmount');
  //         }
  //       }
  //     }
  //   }

  //   final groupedTransactions = groupTransactions(transactions);

  //   emit(state.copyWith(
  //     groupedTransactions: groupedTransactions,
  //   ));
  // }
}
