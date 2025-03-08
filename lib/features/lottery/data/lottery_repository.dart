import 'dart:convert';

import 'package:privy_flutter/src/models/embedded_solana_wallet/embedded_solana_wallet.dart';
import 'package:solana_web3/programs.dart';
import 'package:solana_web3/solana_web3.dart' as web3;

class LotteryRepository {
  Future<void> addToPool({
    required EmbeddedSolanaWallet wallet,
    required int amount,
  }) async {
    final cluster = web3.Cluster.mainnet;
    final connection = web3.Connection(cluster);
    final blockHash = await connection.getLatestBlockhash();

    const int hardcodedDecimals = 9;
    final amountInUnits = _calculateAmountInUnits(amount, hardcodedDecimals);

    final transaction =
        _createTransaction(wallet, blockHash.blockhash, amountInUnits);

    await _signAndSendTransaction(wallet, connection, transaction);
  }

  // Helper to calculate amount in units
  BigInt _calculateAmountInUnits(int amount, int decimals) {
    return BigInt.from(amount) * BigInt.from(10).pow(decimals);
  }

  // Helper to create the transaction
  web3.Transaction _createTransaction(
      EmbeddedSolanaWallet wallet, String blockhash, BigInt amountInUnits) {
    return web3.Transaction.v0(
      payer: _pubkeyFromBase58(wallet.address),
      recentBlockhash: blockhash,
      instructions: [
        TokenProgram.transfer(
          source:
              _pubkeyFromBase58('Dt9wuYamKHHYtZ8SaENVFPWnd4vnpsPrxvEZhiJNdxrD'),
          destination:
              _pubkeyFromBase58('7XScwGzZrxogzaJjVMSC5rb5zKMpSonoFbxkEzdA7iVn'),
          owner: _pubkeyFromBase58(wallet.address),
          amount: amountInUnits,
        ),
      ],
    );
  }

  // Helper to extract pubkey from Base58 string
  web3.Pubkey _pubkeyFromBase58(String address) {
    return web3.Pubkey.fromBase58(address);
  }

  // Helper to serialize, sign, and send transaction
  Future<void> _signAndSendTransaction(EmbeddedSolanaWallet wallet,
      web3.Connection connection, web3.Transaction transaction) async {
    // Step 1: Get the serialized message (this is what needs to be signed)
    final messageBytes = transaction.serializeMessage().asUint8List();
    final base64Message = base64Encode(messageBytes);

    // Step 2: Sign the message with Privy
    final result = await wallet.provider.signMessage(base64Message);

    result.fold(
      onSuccess: (signedMessage) async {
        try {
          print('Signed message: $signedMessage');
          final signature = base64Decode(signedMessage);

          // Step 3: Add the signature to the transaction
          transaction.addSignature(
              _pubkeyFromBase58(wallet.address), signature);

          // Step 4: Send the signed transaction
          final txId = await connection.sendAndConfirmTransaction(transaction);
          print('Transaction sent successfully: $txId');
        } catch (e) {
          print('Error during sending: $e');
        }
      },
      onFailure: (error) {
        print('Error signing transaction: $error');
      },
    );
  }
}
