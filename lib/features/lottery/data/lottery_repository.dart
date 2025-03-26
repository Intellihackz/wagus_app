import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'package:privy_flutter/src/models/embedded_solana_wallet/embedded_solana_wallet.dart';
import 'package:solana_web3/programs.dart';
import 'package:solana_web3/solana_web3.dart' as web3;
import 'package:wagus/constants.dart';
import 'package:wagus/extensions.dart';
import 'package:wagus/features/lottery/domain/lottery_model.dart';
import 'package:solana/solana.dart' as solana;

class LotteryRepository {
  static const String wagMint = mintToken;
  static const int wagDecimals = 9; // Confirm this matches $WAGUS
  static final web3.Pubkey tokenProgramId = web3.Pubkey.fromBase58(splToken);
  static final web3.Pubkey systemProgramId =
      web3.Pubkey.fromBase58('11111111111111111111111111111111');
  static final web3.Pubkey rentSysvarId =
      web3.Pubkey.fromBase58('SysvarRent111111111111111111111111111111111');

  final lotteryAddressCollection =
      FirebaseFirestore.instance.collection('lottery');

  Stream<QuerySnapshot> getLottery() {
    return lotteryAddressCollection
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> ensureTodayLotteryExists() async {
    final now = DateTime.now();
    final todayReset = DateTime(now.year, now.month, now.day, 18, 0);
    final actualResetTime = now.isBefore(todayReset)
        ? todayReset.subtract(const Duration(days: 1))
        : todayReset;

    final querySnapshot = await lotteryAddressCollection
        .where('timestamp', isEqualTo: Timestamp.fromDate(actualResetTime))
        .get();

    if (querySnapshot.docs.isEmpty) {
      final newDoc = lotteryAddressCollection.doc();
      final model = LotteryModel(
        amount: 0,
        timestamp: Timestamp.fromDate(actualResetTime),
        participants: [],
        winner: null,
      );
      await newDoc.set(model.toJson());
      print('Created empty lottery for ${actualResetTime.toIso8601String()}');
    } else {
      print('Lottery already exists for $actualResetTime');
    }
  }

  Future<void> addToPool({
    required EmbeddedSolanaWallet wallet,
    required int amount,
    required LotteryModel? currentLottery,
  }) async {
    final cluster = web3.Cluster.mainnet;
    final connection = web3.Connection(cluster);
    final blockHash = await connection.getLatestBlockhash();

    final amountInUnits = _calculateAmountInUnits(amount, wagDecimals);

    // Fetch sender and destination ATAs
    final senderPubkey = _pubkeyFromBase58(wallet.address);
    final destinationPubkey =
        _pubkeyFromBase58('4R9rEp5HvMjy8RBBSW7fMBPUkYp34FEbVuctDdVfFYwY');
    final mintPubkey = _pubkeyFromBase58(wagMint);

    final sourceAta =
        await _getSenderTokenAccount(connection, senderPubkey, mintPubkey);
    if (sourceAta == null) {
      throw Exception('Sender does not have a \$WAGUS token account.');
    }
    print('Source ATA: ${sourceAta.toBase58()}');

    final destinationAta =
        await _getAssociatedTokenAddress(destinationPubkey, mintPubkey);
    print('Destination ATA: ${destinationAta.toBase58()}');

    final transaction = await _createTransaction(
      connection,
      senderPubkey,
      destinationPubkey,
      sourceAta,
      destinationAta,
      mintPubkey,
      amountInUnits,
      blockHash.blockhash,
    );
    await _signAndSendTransaction(
        wallet, connection, transaction, amount, currentLottery);
  }

  BigInt _calculateAmountInUnits(int amount, int decimals) {
    return BigInt.from(amount) * BigInt.from(10).pow(decimals);
  }

  Future<web3.Pubkey?> _getSenderTokenAccount(
    web3.Connection connection,
    web3.Pubkey owner,
    web3.Pubkey mint,
  ) async {
    final tokenAccounts = await connection.getTokenAccountsByOwner(
      owner,
      filter: web3.TokenAccountsFilter.mint(mint),
      config: web3.GetTokenAccountsByOwnerConfig(),
    );
    if (tokenAccounts.isEmpty) return null;
    return web3.Pubkey.fromBase58(tokenAccounts.first.pubkey);
  }

  Future<web3.Pubkey> _getAssociatedTokenAddress(
      web3.Pubkey owner, web3.Pubkey mint) async {
    final solanaOwner = solana.Ed25519HDPublicKey.fromBase58(owner.toBase58());
    final solanaMint = solana.Ed25519HDPublicKey.fromBase58(mint.toBase58());
    final tokenProgramId = solana.Ed25519HDPublicKey.fromBase58(
        'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA');

    final seeds = [solanaOwner.bytes, tokenProgramId.bytes, solanaMint.bytes];
    final solanaAta = await solana.Ed25519HDPublicKey.findProgramAddress(
      seeds: seeds,
      programId: solana.AssociatedTokenAccountProgram.id,
    );
    return web3.Pubkey.fromUint8List(solanaAta.bytes);
  }

  Future<web3.Transaction> _createTransaction(
    web3.Connection connection,
    web3.Pubkey senderPubkey,
    web3.Pubkey destinationPubkey,
    web3.Pubkey sourceAta,
    web3.Pubkey destinationAta,
    web3.Pubkey mintPubkey,
    BigInt amountInUnits,
    String blockhash,
  ) async {
    final instructions = <web3.TransactionInstruction>[];

    // Check if destination ATA exists; create it if not
    final destinationAccountInfo =
        await connection.getAccountInfo(destinationAta);
    if (destinationAccountInfo == null) {
      print('Destination ATA does not exist, creating it...');
      instructions.add(
        _createAssociatedTokenAccountInstruction(
          payer: senderPubkey,
          associatedToken: destinationAta,
          owner: destinationPubkey,
          mint: mintPubkey,
        ),
      );
    }

    instructions.add(
      TokenProgram.transfer(
        source: sourceAta,
        destination: destinationAta,
        owner: senderPubkey,
        amount: amountInUnits,
      ),
    );

    return web3.Transaction.v0(
      payer: senderPubkey,
      recentBlockhash: blockhash,
      instructions: instructions,
    );
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
      web3.AccountMeta(systemProgramId, isSigner: false, isWritable: false),
      web3.AccountMeta(tokenProgramId, isSigner: false, isWritable: false),
      web3.AccountMeta(rentSysvarId, isSigner: false, isWritable: false),
    ];

    final data = Uint8List.fromList([1]);
    return web3.TransactionInstruction(
      keys: keys,
      programId: web3.Pubkey.fromBase58(
          'ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL'), // Associated Token Program
      data: data,
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

    final Result<String> result =
        await wallet.provider.signMessage(base64Message);

    if (result.isSuccess) {
      try {
        final signature = base64Decode(result.success);
        transaction.addSignature(_pubkeyFromBase58(wallet.address), signature);

        final txId = await connection.sendAndConfirmTransaction(transaction);
        print('Transaction sent successfully: $txId');

        await _updateLotteryFirestore(wallet.address, amount, currentLottery);
      } catch (e) {
        print('Error during sending: $e');
        rethrow;
      }
    } else {
      print('Error signing message: ${result.failure}');
      throw Exception('Failed to sign message');
    }
  }

  Future<void> _updateLotteryFirestore(
    String participantAddress,
    int amount,
    LotteryModel? currentLottery,
  ) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final QuerySnapshot latestLotterySnapshot =
            await lotteryAddressCollection
                .orderBy('timestamp', descending: true)
                .limit(1)
                .get();

        DocumentReference lotteryRef;
        LotteryModel lotteryData;

        final now = DateTime.now();
        final lotteryStart = DateTime(now.year, now.month, now.day, 18, 0);
        final actualStart = now.hour < 18
            ? lotteryStart.subtract(const Duration(days: 1))
            : lotteryStart;

        if (latestLotterySnapshot.docs.isEmpty ||
            _isNewLotteryNeeded(latestLotterySnapshot.docs.first)) {
          lotteryRef = lotteryAddressCollection.doc();
          lotteryData = LotteryModel(
            amount: amount,
            timestamp: Timestamp.fromDate(actualStart),
            participants: [participantAddress],
            winner: null,
          );
          transaction.set(lotteryRef, lotteryData.toJson());
        } else {
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

  bool _isNewLotteryNeeded(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = (data['timestamp'] as Timestamp).toDate();
    final now = DateTime.now();
    final lotteryStart = DateTime(now.year, now.month, now.day, 18, 0);
    final actualStart = now.hour < 18
        ? lotteryStart.subtract(const Duration(days: 1))
        : lotteryStart;

    return timestamp.isBefore(actualStart);
  }
}
