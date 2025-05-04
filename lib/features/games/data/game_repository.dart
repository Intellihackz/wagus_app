import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:wagus/features/games/domain/spygus_game_data.dart';

class GameRepository {
  final _spygusCollection = FirebaseFirestore.instance.collection('spygus');
  final _usersCollection = FirebaseFirestore.instance.collection('users');
  final _storage = FirebaseStorage.instance;
  final Dio _dio = Dio();

  /// Get real-time updates of Spygus metadata
  Stream<SpygusGameData> getLatestSpygusInfo() {
    return _spygusCollection.limit(1).snapshots().map((snapshot) {
      final data = snapshot.docs.first.data();
      return SpygusGameData.fromFirestore(data);
    });
  }

  /// Get one-time fetch of Spygus metadata
  Future<SpygusGameData> fetchLatestSpygus() async {
    final snapshot = await _spygusCollection.limit(1).get();
    final data = snapshot.docs.first.data();
    return SpygusGameData.fromFirestore(data);
  }

  /// Get image URL from Firebase Storage
  Future<String> getImageUrl(String storagePath) async {
    final ref = _storage.ref().child(storagePath);
    return await ref.getDownloadURL();
  }

  /// Claim Spygus reward (calls server and updates Firestore)
  Future<void> claimSpygusReward(String userWallet) async {
    try {
      final response = await _dio.post(
        'https://wagus-claim-silnt-a3ca9e3fbf49.herokuapp.com/claim-spygus',
        data: {
          'userWallet': userWallet,
        },
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['INTERNAL_API_KEY']}'
        }),
      );

      if (response.statusCode == 200) {
        // Mark as claimed in Firestore
        await _usersCollection.doc(userWallet).set({
          'spygus_claimed_at': FieldValue.serverTimestamp(),
          'last_login': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        throw Exception('Claim server returned error: ${response.data}');
      }
    } catch (e) {
      throw Exception('Spygus claim failed: $e');
    }
  }

  Future<bool> canClaimSpygusToday(String wallet) async {
    final userDoc = await _usersCollection.doc(wallet).get();
    final lastPlayed =
        (userDoc.data()?['spygus_claimed_at'] as Timestamp?)?.toDate();

    final serverTimeDoc = FirebaseFirestore.instance
        .collection('serverTime')
        .doc(wallet); // or use a generic 'now' doc

    await serverTimeDoc.set({'now': FieldValue.serverTimestamp()});
    final nowSnap = await serverTimeDoc.get();

    final serverNow = (nowSnap.data()?['now'] as Timestamp).toDate();

    if (lastPlayed == null) return true;

    final lastDate =
        DateTime(lastPlayed.year, lastPlayed.month, lastPlayed.day);
    final nowDate = DateTime(serverNow.year, serverNow.month, serverNow.day);

    return lastDate.isBefore(nowDate); // true = can claim
  }
}
