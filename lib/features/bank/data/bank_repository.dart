import 'dart:convert';
import 'package:flutter/foundation.dart'; // for debugPrint
import 'package:privy_flutter/privy_flutter.dart';
import 'package:privy_flutter/src/models/embedded_solana_wallet/embedded_solana_wallet.dart';
import 'package:solana_web3/programs.dart';
import 'package:solana_web3/solana_web3.dart' as web3;
import 'package:wagus/extensions.dart';

class BankRepository {
  Future<void> withdrawFunds({
    required EmbeddedSolanaWallet wallet,
    required int amount,
    required String destinationAddress,
  }) async {
    debugPrint('[BankRepository] Starting withdrawal...');
    // debugPrint('[BankRepository] Wallet Address: ${wallet.address}');
    // debugPrint('[BankRepository] Destination: $destinationAddress');
    // debugPrint('[BankRepository] Amount: $amount');

    final cluster = web3.Cluster.mainnet;
    final connection = web3.Connection(cluster);
    final blockHash = await connection.getLatestBlockhash();

    debugPrint(
        '[BankRepository] Fetched latest blockhash: ${blockHash.blockhash}');

    const int hardcodedDecimals = 9;
    final amountInUnits = _calculateAmountInUnits(amount, hardcodedDecimals);

    debugPrint(
        '[BankRepository] Calculated amount in base units: $amountInUnits');

    final transaction = _createTransaction(
      wallet,
      blockHash.blockhash,
      amountInUnits,
      destinationAddress,
    );

    debugPrint('[BankRepository] Transaction created.');

    await _signAndSendTransaction(wallet, connection, transaction, amount);
  }

  BigInt _calculateAmountInUnits(int amount, int decimals) {
    return BigInt.from(amount) * BigInt.from(10).pow(decimals);
  }

  web3.Transaction _createTransaction(
    EmbeddedSolanaWallet wallet,
    String blockhash,
    BigInt amountInUnits,
    String destinationAddress,
  ) {
    debugPrint('[BankRepository] Building transfer instruction.');
    return web3.Transaction.v0(
      payer: _pubkeyFromBase58(wallet.address),
      recentBlockhash: blockhash,
      instructions: [
        TokenProgram.transfer(
          source:
              _pubkeyFromBase58('Dt9wuYamKHHYtZ8SaENVFPWnd4vnpsPrxvEZhiJNdxrD'),
          destination: _pubkeyFromBase58(destinationAddress),
          owner: _pubkeyFromBase58(wallet.address),
          amount: amountInUnits,
        ),
      ],
    );
  }

  web3.Pubkey _pubkeyFromBase58(String address) {
    return web3.Pubkey.fromBase58(address);
  }

  Future<void> _signAndSendTransaction(
    EmbeddedSolanaWallet wallet,
    web3.Connection connection,
    web3.Transaction transaction,
    int amount,
  ) async {
    final messageBytes = transaction.serializeMessage().asUint8List();
    final base64Message = base64Encode(messageBytes);

    debugPrint('[BankRepository] Requesting signature...');
    final Result<String> result =
        await wallet.provider.signMessage(base64Message);

    if (result.isSuccess) {
      try {
        debugPrint('[BankRepository] Signature success.');
        final signature = base64Decode(result.success);
        transaction.addSignature(_pubkeyFromBase58(wallet.address), signature);

        debugPrint('[BankRepository] Sending transaction...');
        final txId = await connection.sendAndConfirmTransaction(transaction);
        debugPrint('[BankRepository] ✅ Transaction confirmed: $txId');
      } catch (e) {
        debugPrint('[BankRepository] ❌ Error during send: $e');
        rethrow;
      }
    } else {
      debugPrint(
          '[BankRepository] ❌ Failed to sign message: ${result.failure}');
      throw Exception('Failed to sign message');
    }
  }
}
