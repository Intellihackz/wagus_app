import 'dart:async';
import 'dart:convert';
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
}
