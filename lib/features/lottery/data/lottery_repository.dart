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
    final transaction = web3.Transaction.v0(
      payer: web3.Pubkey.fromBase58(wallet.address),
      recentBlockhash: blockHash.blockhash,
      instructions: [
        TokenProgram.transfer(
          source: web3.Pubkey.fromBase58(wallet.address),
          destination: web3.Pubkey.fromBase58(
              'DZuJUNmVxNQwq55wrrrpFeE4PES1cyBv2bxuSqm7UXdj'),
          owner: web3.Pubkey.fromBase58(
            'BfL1T6JnLbQ52divaJQTNwZTo1W8MTeqb1cbkavfJDu7',
          ),
          amount: BigInt.from(amount),
        ),
      ],
    );

    // Serialize the transaction (This is before signing)
    final serializedTransaction = transaction.serialize();
    final transactionList = serializedTransaction.asUint8List();

    // Debugging: Print the raw serialized transaction before signing
    print("Serialized Transaction Bytes (Before Signing): $transactionList");

    // Send the transaction as a Base64-encoded string for signing
    final base64Transaction = base64Encode(transactionList);

    // Sign the transaction with the Privy wallet provider
    final result = await wallet.provider.signMessage(base64Transaction);

    result.fold(
      onSuccess: (signedMessage) async {
        try {
          print('Signed message: $signedMessage');

          // Decode the base64 signature received from Privy
          final signature = base64Decode(signedMessage);

          // After obtaining the signature, add it to the transaction
          transaction.addSignature(
            web3.Pubkey.fromBase58(wallet.address), // Address of the signer
            signature,
          );

          // Finalize the transaction by serializing it again
          final finalSerializedTransaction = transaction.serialize();
          final finalTransactionList = finalSerializedTransaction.asUint8List();

          // Send the final signed transaction
          final txId = await connection.sendTransaction(
            web3.Transaction.fromBase64(base64Encode(finalTransactionList)),
            config: web3.SendTransactionConfig(skipPreflight: true),
          );

          // Handle the response after sending the transaction
          print('Transaction sent successfully. Tx ID: $txId');
        } catch (e) {
          print('Error during deserialization or sending: $e');
        }
      },
      onFailure: (error) {
        print('Error signing transaction: $error');
      },
    );
  }
}
