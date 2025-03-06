import 'dart:convert';

import 'package:solana_web3/programs.dart';
import 'package:solana_web3/solana_web3.dart' as web3;
import 'package:privy_flutter/src/models/embedded_solana_wallet/embedded_solana_wallet.dart';

class LotteryRepository {
  Future<void> addToPool({
    required EmbeddedSolanaWallet wallet,
    required int amount,
  }) async {
    // final address1 = wallet.address;

    // final cluster = web3.Cluster.mainnet;
    // final connection = web3.Connection(cluster);
    // final blockHash = await connection.getLatestBlockhash();
    // final wallet1 = web3.Keypair.generateSync();
    // final transaction = web3.Transaction.v0(
    //   payer: web3.Pubkey.fromBase58(address1),
    //   recentBlockhash: blockHash.blockhash,
    //   instructions: [
    //     TokenProgram.transfer(
    //       source: web3.Pubkey.fromBase58(address1),
    //       destination: web3.Pubkey.fromBase58(
    //
    //       ),
    //       owner: web3.Pubkey.fromBase58(
    //         'BfL1T6JnLbQ52divaJQTNwZTo1W8MTeqb1cbkavfJDu7',
    //       ),
    //       amount: BigInt.from(amount),
    //     ),
    //   ],
    // );

    // // Serialize the transaction
    // final serializedTransaction = transaction.serialize();
    // final transactionList = serializedTransaction.asUint8List();

    // // Debugging: Print the raw serialized transaction before signing
    // print("Serialized Transaction Bytes (Before Signing): $transactionList");

    // // Send the transaction as a Base64-encoded string
    // final base64Transaction = base64Encode(transactionList);

    // // Sign the transaction with the Privy wallet provider
    // final result = await wallet.provider.signMessage(base64Transaction);

    // result.fold(
    //   onSuccess: (signedTransaction) async {
    //     try {
    //       // Convert the signed transaction back from Base64 to bytes
    //       final signedTransactionBytes = base64Decode(signedTransaction);

    //       // Print the length and bytes for debugging purposes
    //       print(
    //           'Signed Transaction Byte Length: ${signedTransactionBytes.length}');
    //       print('Signed Transaction Bytes: $signedTransactionBytes');

    //       // Relax the byte size check to account for extra data
    //       if (signedTransactionBytes.length < 3 ||
    //           signedTransactionBytes.length > 100) {
    //         throw Exception(
    //             'Invalid signed transaction byte size: ${signedTransactionBytes.length}');
    //       }

    //       // Deserialize the signed transaction
    //       final signedTransactionObj =
    //           web3.Transaction.deserialize(signedTransactionBytes);

    //       // Send the signed transaction to the Solana network
    //       final sendResult = await connection.sendTransaction(
    //         signedTransactionObj,
    //         config: web3.SendTransactionConfig(
    //             preflightCommitment: web3.Commitment.confirmed),
    //       );

    //       print('Transaction successfully sent. Transaction ID: $sendResult');
    //     } catch (e) {
    //       print('Error during deserialization or sending: $e');
    //     }
    //   },
    //   onFailure: (error) {
    //     print('Error signing transaction: $error');
    //   },
    // );
  }
}
