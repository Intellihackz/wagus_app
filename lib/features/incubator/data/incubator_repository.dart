import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'package:privy_flutter/src/models/embedded_solana_wallet/embedded_solana_wallet.dart';
import 'package:solana/base58.dart';
import 'package:solana/solana.dart' as solana;
import 'package:solana_web3/programs.dart';
import 'package:solana_web3/solana_web3.dart' as web3;
import 'package:wagus/core/constants/constants.dart';
import 'package:wagus/core/extensions/extensions.dart';
import 'package:wagus/features/incubator/domain/project.dart';

class IncubatorRepository {
  //static const int wagusDecimals = 6;
  static final web3.Pubkey tokenProgramId = web3.Pubkey.fromBase58(splToken);
  static final web3.Pubkey systemProgramId =
      web3.Pubkey.fromBase58('11111111111111111111111111111111');
  static final web3.Pubkey rentSysvarId =
      web3.Pubkey.fromBase58('SysvarRent111111111111111111111111111111111');

  final CollectionReference projectsCollection =
      FirebaseFirestore.instance.collection('projects');

  Future<String> _uploadPdfToStorage(File file, String fileName) async {
    try {
      final Reference storageRef =
          FirebaseStorage.instance.ref().child('project_pdfs/$fileName');
      final UploadTask uploadTask = storageRef.putFile(file);
      await uploadTask;
      return await storageRef.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload PDF: $e');
    }
  }

  Future<double> getUsdPerToken(String tokenTicker) async {
    final tokenDoc = await FirebaseFirestore.instance
        .collection('supported_tokens')
        .doc(tokenTicker)
        .get();

    if (!tokenDoc.exists) {
      throw Exception('Token not supported or missing usdPerToken');
    }

    final data = tokenDoc.data()!;
    return (data['usdPerToken'] as num).toDouble();
  }

  // Like a project (add user to likes subcollection and increment likesCount)
  Future<void> likeProject(String projectId, String userId) async {
    try {
      final projectRef = projectsCollection.doc(projectId);
      final likeRef = projectRef.collection('likes').doc(userId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final projectSnapshot = await transaction.get(projectRef);
        if (!projectSnapshot.exists) {
          throw Exception('Project does not exist!');
        }

        final data = projectSnapshot.data() as Map<String, dynamic>;
        if (data['id'] != projectId) {
          throw Exception('Project ID mismatch in document data!');
        }

        final currentLikes = data['likesCount'] ?? 0;
        final likeSnapshot = await transaction.get(likeRef);

        if (!likeSnapshot.exists) {
          transaction.set(likeRef, {
            'userId': userId, // Add userId as a field
            'timestamp': FieldValue.serverTimestamp(),
          });
          transaction.update(projectRef, {
            'likesCount': currentLikes + 1,
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to like project: $e');
    }
  }

  // Unlike a project (remove user from likes subcollection and decrement likesCount)
  Future<void> unlikeProject(String projectId, String userId) async {
    try {
      final projectRef = projectsCollection.doc(projectId);
      final likeRef = projectRef.collection('likes').doc(userId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final projectSnapshot = await transaction.get(projectRef);
        if (!projectSnapshot.exists) {
          throw Exception('Project does not exist!');
        }

        final currentLikes =
            (projectSnapshot.data() as Map<String, dynamic>)['likesCount'] ?? 0;
        final likeSnapshot = await transaction.get(likeRef);

        if (likeSnapshot.exists && currentLikes > 0) {
          transaction.delete(likeRef);
          transaction.update(projectRef, {
            'likesCount': currentLikes - 1,
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to unlike project: $e');
    }
  }

  // Check if a user has liked a project
  Future<bool> hasUserLikedProject(String projectId, String userId) async {
    final likeDoc = await projectsCollection
        .doc(projectId)
        .collection('likes')
        .doc(userId)
        .get();
    return likeDoc.exists;
  }

  // Submit a project with PDFs to Firebase
  Future<String> submitProject(
      Project project, File? whitePaperFile, File? roadMapFile) async {
    try {
      // Generate a document reference with an ID upfront
      final docRef = projectsCollection.doc();
      final projectId = docRef.id;

      String? whitePaperUrl;
      if (whitePaperFile != null) {
        whitePaperUrl = await _uploadPdfToStorage(
          whitePaperFile,
          '${project.name}_whitepaper_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
      }

      String? roadMapUrl;
      if (roadMapFile != null) {
        roadMapUrl = await _uploadPdfToStorage(
          roadMapFile,
          '${project.name}_roadmap_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
      }

      // Use set() with the pre-generated ID instead of add()
      await docRef.set({
        'id': projectId, // Store the ID in the document data
        'contactEmail': project.contactEmail,
        'name': project.name,
        'description': project.description,
        'walletAddress': project.walletAddress,
        'gitHubLink': project.gitHubLink,
        'websiteLink': project.websiteLink,
        'whitePaperLink': whitePaperUrl,
        'roadmapLink': roadMapUrl,
        'socialsLink': project.socialsLink,
        'telegramLink': project.telegramLink,
        'fundingProgress': project.fundingProgress,
        'likesCount': 0,
        'addressesFunded': [],
        'launchDate': project.launchDate.toIso8601String(),
        'timestamp': FieldValue.serverTimestamp(),
        'max_allocation': project.maxAllocation,
      });

      return projectId; // Return the ID for use in project.id
    } catch (e) {
      throw Exception('Failed to submit project: $e');
    }
  }

  // Retrieve projects as a stream, ordered by timestamp
  Stream<QuerySnapshot> getProjects() {
    return projectsCollection
        .orderBy('likesCount', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getUserLikedProjects(String userId) {
    print('Querying liked projects for userId: $userId');
    final stream = FirebaseFirestore.instance
        .collectionGroup('likes')
        .where('userId', isEqualTo: userId)
        .snapshots();
    stream.listen((snapshot) {
      print(
          'Liked projects snapshot: ${snapshot.docs.map((doc) => doc.reference.path).toList()}');
      // Log all likes documents to see what's in the subcollections
      FirebaseFirestore.instance
          .collectionGroup('likes')
          .get()
          .then((allLikes) {
        print(
            'All likes documents: ${allLikes.docs.map((doc) => "${doc.reference.path}: ${doc.data()}").toList()}');
      });
    }, onError: (error) {
      print('Error in getUserLikedProjects: $error');
    });
    return stream;
  }

  Future<void> withdrawToProject({
    required EmbeddedSolanaWallet wallet,
    required int amount,
    required String projectId,
    required String userId,
    required String tokenAddress,
    required String tokenTicker,
  }) async {
    debugPrint(
        '[IncubatorRepository] Starting withdrawal to project: $projectId');
    debugPrint('[IncubatorRepository] Sender Wallet: ${wallet.address}');
    debugPrint('[IncubatorRepository] Amount: $amount');

    // Fetch project wallet address from Firestore
    final projectDoc = await projectsCollection.doc(projectId).get();
    if (!projectDoc.exists) throw Exception('Project not found');
    final projectData = projectDoc.data() as Map<String, dynamic>;
    final destinationAddress = projectData['walletAddress'] as String?;

    // Validate destinationAddress
    if (destinationAddress == null || destinationAddress.isEmpty) {
      throw Exception('Project wallet address is null or empty in Firestore');
    }
    debugPrint('[IncubatorRepository] Project Wallet: $destinationAddress');

    // Additional validation for Solana public key length (base58 string typically 43-44 chars)
    try {
      final decoded =
          base58decode(destinationAddress); // From solana package or similar
      if (decoded.length != 32) {
        throw Exception(
            'Invalid public key length: ${decoded.length} bytes, expected 32');
      }
    } catch (e) {
      throw Exception('Invalid walletAddress format: $destinationAddress - $e');
    }

    final rpcUrl = dotenv.env['HELIUS_RPC']!;
    final wsUrl = dotenv.env['HELIUS_WS']!;

    final connection = web3.Connection(
      web3.Cluster(Uri.parse(rpcUrl)),
      websocketCluster: web3.Cluster(Uri.parse(wsUrl)),
    );
    final blockHash = await connection.getLatestBlockhash();

    debugPrint(
        '[IncubatorRepository] Fetched latest blockhash: ${blockHash.blockhash}');

    final decimals = await getTokenDecimals(tokenTicker.toLowerCase());

    final amountInUnits = _calculateAmountInUnits(amount, decimals);
    debugPrint('[IncubatorRepository] Amount in units: $amountInUnits');

    final senderPubkey = _pubkeyFromBase58(wallet.address);
    final destinationPubkey =
        _pubkeyFromBase58(destinationAddress); // Should now work if valid
    final mintPubkey = _pubkeyFromBase58(tokenAddress);

    final sourceAta =
        await _getSenderTokenAccount(connection, senderPubkey, mintPubkey);
    if (sourceAta == null) {
      throw Exception('Sender does not have a Tech Medic token account.');
    }
    debugPrint('[IncubatorRepository] Source ATA: ${sourceAta.toBase58()}');

    final destinationAta =
        await _getAssociatedTokenAddress(destinationPubkey, mintPubkey);
    debugPrint(
        '[IncubatorRepository] Destination ATA: ${destinationAta.toBase58()}');

    final transaction = await _prepareTransaction(
      connection,
      senderPubkey,
      destinationPubkey,
      sourceAta,
      destinationAta,
      mintPubkey,
      amountInUnits,
      blockHash.blockhash,
    );

    debugPrint('[IncubatorRepository] Transaction prepared.');

    await _signAndSendTransaction(wallet, connection, transaction);

    await _updateProjectFunding(projectId, userId, amount, wallet, tokenTicker);
  }

  BigInt _calculateAmountInUnits(int amount, int decimals) {
    return BigInt.from(amount) * BigInt.from(10).pow(decimals);
  }

  Future<int> getTokenDecimals(String tokenTicker) async {
    final tokenDoc = await FirebaseFirestore.instance
        .collection('supported_tokens')
        .doc(tokenTicker)
        .get();

    if (!tokenDoc.exists) {
      throw Exception('Token not supported or missing decimals');
    }

    final data = tokenDoc.data()!;
    return (data['decimals'] as num).toInt();
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

    final pubkey = web3.Pubkey.fromString(tokenAccounts.first.pubkey);
    return pubkey;
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

  Future<web3.Transaction> _prepareTransaction(
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

    final destinationAccountInfo =
        await connection.getAccountInfo(destinationAta);
    if (destinationAccountInfo == null) {
      debugPrint(
          '[IncubatorRepository] Destination ATA does not exist, creating it...');
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
          'ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL'),
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
  ) async {
    final messageBytes = transaction.serializeMessage().asUint8List();
    final base64Message = base64Encode(messageBytes);

    debugPrint('[IncubatorRepository] Requesting signature...');
    final Result<String> result =
        await wallet.provider.signMessage(base64Message);

    if (result.isSuccess) {
      try {
        debugPrint('[IncubatorRepository] Signature success.');
        final signature = base64Decode(result.success);
        transaction.addSignature(_pubkeyFromBase58(wallet.address), signature);

        debugPrint('[IncubatorRepository] Sending transaction...');
        final txId = await connection.sendAndConfirmTransaction(transaction);
        debugPrint('[IncubatorRepository] ✅ Transaction confirmed: $txId');
      } catch (e) {
        debugPrint('[IncubatorRepository] ❌ Error during send: $e');
        rethrow;
      }
    } else {
      debugPrint(
          '[IncubatorRepository] ❌ Failed to sign message: ${result.failure}');
      throw Exception('Failed to sign message');
    }
  }

  Future<void> _updateProjectFunding(String projectId, String userId,
      int amount, EmbeddedSolanaWallet wallet, String tokenTicker) async {
    try {
      final projectRef = projectsCollection.doc(projectId);
      final investorRef = projectRef.collection('investors').doc(userId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Perform all reads first
        final projectSnapshot = await transaction.get(projectRef);
        final investorSnapshot = await transaction.get(investorRef);

        if (!projectSnapshot.exists) throw Exception('Project not found');

        final projectData = projectSnapshot.data() as Map<String, dynamic>;
        final currentTotal =
            (projectData['totalFunded'] as num?)?.toDouble() ?? 0.0;
        final maxCap = projectData['max_allocation'] ?? 20000;

        final usdPerToken = await getUsdPerToken(tokenTicker.toLowerCase());
        final amountInUsd = amount * usdPerToken;

        if ((currentTotal + amountInUsd) > maxCap) {
          throw Exception('Contribution would exceed project funding cap.');
        }

        final newTotal = currentTotal + amountInUsd;

        final fundingProgress = newTotal / maxCap;

        // Now perform writes
        transaction.update(projectRef, {
          'totalFunded': newTotal,
          'fundingProgress': fundingProgress.clamp(0.0, 1.0),
          'addressesFunded': FieldValue.arrayUnion([wallet.address]),
        });

        if (investorSnapshot.exists) {
          final investorData = investorSnapshot.data() as Map<String, dynamic>;
          final currentAmount =
              (investorData['amount'] as num?)?.toDouble() ?? 0.0;
          transaction.update(investorRef, {
            'amount': currentAmount + amountInUsd,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.set(investorRef, {
            'userId': userId,
            'amount': amountInUsd,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to update project funding: $e');
    }
  }
}
