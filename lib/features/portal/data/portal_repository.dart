import 'dart:async';
import 'dart:convert';
import 'dart:math' as Math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'package:solana_web3/solana_web3.dart' as web3;
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

  final currentTokenAddressCollection =
      FirebaseFirestore.instance.collection('current_token');

  Stream<QuerySnapshot> getCurrentTokenAddress() {
    return currentTokenAddressCollection.snapshots();
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

  Future<Holder> getTokenAccounts(String address, String mintToken) async {
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
  Future<int> getHoldersCount(String tokenAddress) async {
    final dio = Dio();
    final apiKey = dotenv.env['HELIUS_API_KEY'];
    final url = 'https://mainnet.helius-rpc.com/?api-key=$apiKey';
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
        'Found $holderCount unique holders for WAGUS/SOL pool LP token via Helius');
    return holderCount;
  }

  /// [getTotalTokenBalance] function to calculate the total WAGUS balance for an address
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
}
