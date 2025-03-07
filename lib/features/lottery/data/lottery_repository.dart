import 'dart:convert';
import 'package:solana_web3/programs.dart';
import 'package:solana_web3/solana_web3.dart' as web3;
import 'package:privy_flutter/src/models/embedded_solana_wallet/embedded_solana_wallet.dart';

class LotteryRepository {
  Future<void> addToPool({
    required EmbeddedSolanaWallet wallet,
    required int amount,
  }) async {
    final cluster = web3.Cluster.mainnet;
    final connection = web3.Connection(cluster);
    final blockHash = await connection.getLatestBlockhash();

    const int hardcodedDecimals = 9;
    int decimals = hardcodedDecimals;

    final BigInt amountInUnits =
        BigInt.from(amount) * BigInt.from(10).pow(decimals);

    // Create the transaction
    final transaction = web3.Transaction.v0(
      payer: web3.Pubkey.fromBase58(wallet.address),
      recentBlockhash: blockHash.blockhash,
      instructions: [
        TokenProgram.transfer(
          source: web3.Pubkey.fromBase58(
              'Dt9wuYamKHHYtZ8SaENVFPWnd4vnpsPrxvEZhiJNdxrD'),
          destination: web3.Pubkey.fromBase58(
              '7XScwGzZrxogzaJjVMSC5rb5zKMpSonoFbxkEzdA7iVn'),
          owner: web3.Pubkey.fromBase58(wallet.address),
          amount: amountInUnits,
        ),
      ],
    );

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
              web3.Pubkey.fromBase58(wallet.address), signature);

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
