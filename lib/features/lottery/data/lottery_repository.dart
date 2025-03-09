import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:privy_flutter/src/models/embedded_solana_wallet/embedded_solana_wallet.dart';
import 'package:solana_web3/programs.dart';
import 'package:solana_web3/solana_web3.dart' as web3;
import 'package:wagus/features/lottery/domain/lottery_model.dart';

class LotteryRepository {
  final lotteryAddressCollection =
      FirebaseFirestore.instance.collection('lottery');

  Stream<QuerySnapshot> getLottery() {
    return lotteryAddressCollection
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> addToPool({
    required EmbeddedSolanaWallet wallet,
    required int amount,
    required LotteryModel? currentLottery,
  }) async {
    final cluster = web3.Cluster.mainnet;
    final connection = web3.Connection(cluster);
    final blockHash = await connection.getLatestBlockhash();

    const int hardcodedDecimals = 9;
    final amountInUnits = _calculateAmountInUnits(amount, hardcodedDecimals);

    final transaction =
        _createTransaction(wallet, blockHash.blockhash, amountInUnits);
    await _signAndSendTransaction(
        wallet, connection, transaction, amount, currentLottery);
  }

  BigInt _calculateAmountInUnits(int amount, int decimals) {
    return BigInt.from(amount) * BigInt.from(10).pow(decimals);
  }

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

  web3.Pubkey _pubkeyFromBase58(String address) {
    return web3.Pubkey.fromBase58(address);
  }

  Future<void> _signAndSendTransaction(
      EmbeddedSolanaWallet wallet,
      web3.Connection connection,
      web3.Transaction transaction,
      int amount,
      LotteryModel? currentLottery) async {
    final messageBytes = transaction.serializeMessage().asUint8List();
    final base64Message = base64Encode(messageBytes);

    final result = await wallet.provider.signMessage(base64Message);

    result.fold(
      onSuccess: (signedMessage) async {
        try {
          final signature = base64Decode(signedMessage);
          transaction.addSignature(
              _pubkeyFromBase58(wallet.address), signature);

          final txId = await connection.sendAndConfirmTransaction(transaction);
          print('Transaction sent successfully: $txId');

          // Firestore update logic
          await _updateLotteryFirestore(wallet.address, amount, currentLottery);
        } catch (e) {
          print('Error during sending: $e');
          rethrow; // Consider rethrowing to handle errors upstream
        }
      },
      onFailure: (error) {
        print('Error signing transaction: $error');
        throw Exception('Failed to sign transaction: $error');
      },
    );
  }

  Future<void> _updateLotteryFirestore(
    String participantAddress,
    int amount,
    LotteryModel? currentLottery,
  ) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Get the latest lottery document reference
        final QuerySnapshot latestLotterySnapshot =
            await lotteryAddressCollection
                .orderBy('timestamp', descending: true)
                .limit(1)
                .get();

        DocumentReference lotteryRef;
        LotteryModel lotteryData;

        // Calculate the correct lottery start time (6:00 PM)
        final now = DateTime.now();
        final lotteryStart =
            DateTime(now.year, now.month, now.day, 18, 0); // 6:00 PM today
        final actualStart = now.hour < 18
            ? lotteryStart.subtract(
                const Duration(days: 1)) // Previous day if before 6 PM
            : lotteryStart;

        if (latestLotterySnapshot.docs.isEmpty ||
            _isNewLotteryNeeded(latestLotterySnapshot.docs.first)) {
          // Create new lottery document with fixed 6:00 PM timestamp
          lotteryRef = lotteryAddressCollection.doc();
          lotteryData = LotteryModel(
            amount: amount,
            timestamp: Timestamp.fromDate(actualStart), // Set to 6:00 PM
            participants: [participantAddress],
            winner: null,
          );
          transaction.set(lotteryRef, lotteryData.toJson());
        } else {
          // Update existing lottery
          lotteryRef = latestLotterySnapshot.docs.first.reference;
          final docData =
              latestLotterySnapshot.docs.first.data() as Map<String, dynamic>;
          lotteryData = LotteryModel.fromJson(docData);

          final updatedParticipants =
              lotteryData.participants.contains(participantAddress)
                  ? lotteryData.participants
                  : [...lotteryData.participants, participantAddress];

          transaction.update(lotteryRef, {
            'amount': lotteryData.amount + amount,
            'participants': updatedParticipants,
          });
        }
      });
    } catch (e) {
      print('Error updating Firestore: $e');
      rethrow;
    }
  }

// Helper method to determine if a new lottery is needed
  bool _isNewLotteryNeeded(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = (data['timestamp'] as Timestamp).toDate();
    final now = DateTime.now();
    final lotteryStart = DateTime(now.year, now.month, now.day, 18, 0);

    // Adjust start time if before 6PM
    final actualStart = now.hour < 18
        ? lotteryStart.subtract(const Duration(days: 1))
        : lotteryStart;

    return timestamp.isBefore(actualStart);
  }
}
