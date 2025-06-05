import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'package:privy_flutter/src/models/embedded_solana_wallet/embedded_solana_wallet.dart';
import 'package:solana/solana.dart' as solana;
import 'package:solana_web3/programs.dart';
import 'package:solana_web3/solana_web3.dart' as web3;
import 'package:wagus/core/extensions/extensions.dart';
import 'package:wagus/services/privy_service.dart';
import 'package:wagus/shared/holder/holder.dart';
import 'package:wagus/shared/token/token.dart';

class PortalRepository {
  PortalRepository();
  final _privyService = PrivyService();

  Future<PrivyUser?> init() async {
    if (!PrivyService().isAuthenticated()) return null;
    return PrivyService().privy.user;
  }

  Stream<List<Token>> getSupportedTokens() {
    return FirebaseFirestore.instance
        .collection('supported_tokens')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Token.fromMap(doc.data())).toList());
  }

  Future<PrivyUser?> connect() async {
    try {
      final user = _privyService.privy.user;
      if (user != null) {
        if (user.embeddedSolanaWallets.isNotEmpty) {
          debugPrint('Solana wallet already exists');
          return user;
        }
        final walletResult = await user.createSolanaWallet();
        if (walletResult.isSuccess) return user;
      }
    } catch (e) {
      debugPrint('Error connecting wallet: $e');
    }
    return null;
  }

  Future<bool?> disconnect(BuildContext context) async {
    final success = await _privyService.logout(context);
    return success ? true : null;
  }

  Future<Holder> getTokenAccounts(String address, String mintToken) async {
    final connection = web3.Connection(web3.Cluster.mainnet);
    final publicKey = web3.Pubkey.fromBase58(address);
    final mintPubkey = web3.Pubkey.fromBase58(mintToken);

    try {
      final tokenAccounts = await connection.getTokenAccountsByOwner(
        publicKey,
        filter: web3.TokenAccountsFilter.mint(mintPubkey),
      );

      final tokenKey = web3.Pubkey.fromString(tokenAccounts.first.pubkey);
      final tokenAccountBalance =
          await connection.getTokenAccountBalance(tokenKey);

      final tokenAmount = double.parse(tokenAccountBalance.uiAmountString);
      final solAmount =
          (await connection.getBalance(publicKey)) / web3.lamportsPerSol;

      final holderType = determineHolderType(tokenAmount);

      return Holder(
        holderType: holderType,
        holdings: tokenAmount,
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
    if (amount >= 10.0) return HolderType.whale;
    if (amount >= 1.0) return HolderType.shark;
    if (amount >= 0.1) return HolderType.shrimp;
    return HolderType.plankton;
  }

  Future<int> getHoldersCount(String tokenAddress) async {
    final dio = Dio();
    final apiKey = dotenv.env['HELIUS_API_KEY'];
    final url = 'https://mainnet.helius-rpc.com/?api-key=$apiKey';
    final allOwners = <String>{};
    String? cursor;

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
        final response = await dio.post(
          url,
          data: jsonEncode(params),
          options: Options(headers: {'Content-Type': 'application/json'}),
        );

        if (response.statusCode == 200) {
          final accounts =
              (response.data['result']['token_accounts'] as List<dynamic>);
          if (accounts.isEmpty) break;

          for (var account in accounts) {
            final owner = account['owner'] as String;
            allOwners.add(owner);
          }
          cursor = response.data['result']['cursor'] as String?;
          if (cursor == null) break;
        } else {
          break;
        }
      } catch (e) {
        break;
      }
    }

    return allOwners.length;
  }

  Future<void> sendTokens({
    required EmbeddedSolanaWallet senderWallet,
    required String fromWalletAddress,
    required String toWalletAddress,
    required String mintAddress,
    required int amount,
    int decimals = 6,
  }) async {
    final rpcUrl = dotenv.env['HELIUS_RPC']!;
    final wsUrl = dotenv.env['HELIUS_WS']!;

    final connection = web3.Connection(
      web3.Cluster(Uri.parse(rpcUrl)),
      websocketCluster: web3.Cluster(Uri.parse(wsUrl)),
    );

    final blockhash = await connection.getLatestBlockhash();

    final senderPubkey = web3.Pubkey.fromBase58(fromWalletAddress);
    final destinationPubkey = web3.Pubkey.fromBase58(toWalletAddress);
    final mintPubkey = web3.Pubkey.fromBase58(mintAddress);

    final sourceAccounts = await connection.getTokenAccountsByOwner(
      senderPubkey,
      filter: web3.TokenAccountsFilter.mint(mintPubkey),
    );
    if (sourceAccounts.isEmpty) throw Exception('No source token account');
    final sourceAta = web3.Pubkey.fromString(sourceAccounts.first.pubkey);

    final destinationAta = await _findAta(destinationPubkey, mintPubkey);

    final instructions = <web3.TransactionInstruction>[];

    final destinationInfo = await connection.getAccountInfo(destinationAta);
    if (destinationInfo == null) {
      instructions.add(_createAssociatedTokenAccountInstruction(
        payer: senderPubkey,
        associatedToken: destinationAta,
        owner: destinationPubkey,
        mint: mintPubkey,
      ));
    }

    final amountInUnits = BigInt.from(amount) * BigInt.from(10).pow(decimals);

    instructions.add(
      TokenProgram.transfer(
        source: sourceAta,
        destination: destinationAta,
        owner: senderPubkey,
        amount: amountInUnits,
      ),
    );

    final transaction = web3.Transaction.v0(
      payer: senderPubkey,
      recentBlockhash: blockhash.blockhash,
      instructions: instructions,
    );

    final messageBytes = transaction.serializeMessage().asUint8List();
    final base64Message = base64Encode(messageBytes);

    final result = await senderWallet.provider.signMessage(base64Message);

    if (result.isSuccess) {
      final signature = base64Decode(result.success);
      transaction.addSignature(senderPubkey, signature);
      await connection.sendAndConfirmTransaction(transaction);
    } else {
      throw Exception('Failed to sign message: ${result.failure}');
    }
  }

  Future<web3.Pubkey> _findAta(web3.Pubkey owner, web3.Pubkey mint) async {
    final solanaOwner = solana.Ed25519HDPublicKey.fromBase58(owner.toBase58());
    final solanaMint = solana.Ed25519HDPublicKey.fromBase58(mint.toBase58());
    final tokenProgramId = solana.Ed25519HDPublicKey.fromBase58(
      'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA',
    );
    final seeds = [solanaOwner.bytes, tokenProgramId.bytes, solanaMint.bytes];
    final ata = await solana.Ed25519HDPublicKey.findProgramAddress(
      seeds: seeds,
      programId: solana.AssociatedTokenAccountProgram.id,
    );
    return web3.Pubkey.fromUint8List(ata.bytes);
  }

  web3.TransactionInstruction _createAssociatedTokenAccountInstruction({
    required web3.Pubkey payer,
    required web3.Pubkey associatedToken,
    required web3.Pubkey owner,
    required web3.Pubkey mint,
  }) {
    final keys = [
      web3.AccountMeta(payer, isSigner: true, isWritable: true),
      web3.AccountMeta(associatedToken, isSigner: false, isWritable: true),
      web3.AccountMeta(owner, isSigner: false, isWritable: false),
      web3.AccountMeta(mint, isSigner: false, isWritable: false),
      web3.AccountMeta(
        web3.Pubkey.fromBase58('11111111111111111111111111111111'),
        isSigner: false,
        isWritable: false,
      ),
      web3.AccountMeta(
        web3.Pubkey.fromBase58('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA'),
        isSigner: false,
        isWritable: false,
      ),
      web3.AccountMeta(
        web3.Pubkey.fromBase58('SysvarRent111111111111111111111111111111111'),
        isSigner: false,
        isWritable: false,
      ),
    ];
    return web3.TransactionInstruction(
      keys: keys,
      programId: web3.Pubkey.fromBase58(
          'ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL'),
      data: Uint8List.fromList([1]),
    );
  }
}
