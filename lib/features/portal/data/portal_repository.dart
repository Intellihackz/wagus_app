import 'dart:async';
import 'dart:convert';
import 'dart:math' as Math;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'package:wagus/services/privy_service.dart';
import 'package:flutter/material.dart';

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
}
