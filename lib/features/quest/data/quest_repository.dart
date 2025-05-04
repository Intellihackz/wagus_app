import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class QuestRepository {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  final Dio _dio = Dio();

  Future<void> updateLogin(String wallet) async {
    await usersCollection.doc(wallet).set({
      'wallet': wallet,
      'last_login': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String wallet) {
    return usersCollection
        .doc(wallet)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data()!,
          toFirestore: (data, _) => data,
        )
        .get(const GetOptions(source: Source.server)); // Fetch from server
  }

  Future<bool> canClaimToday(String userWallet) async {
    final userDoc = await getUser(userWallet);
    final userData = userDoc.data();
    final lastClaimed = (userData?['last_claimed'] as Timestamp?)?.toDate();

    if (lastClaimed == null) return true; // No claims yet

    await FirebaseFirestore.instance.collection('serverTime').doc('now').set(
        {'timestamp': FieldValue.serverTimestamp()}, SetOptions(merge: true));

    final serverNowSnap = await FirebaseFirestore.instance
        .collection('serverTime')
        .doc('now')
        .get();

    final serverNow =
        (serverNowSnap.data()?['timestamp'] as Timestamp).toDate();

    final lastClaimedDate = DateTime(
      lastClaimed.year,
      lastClaimed.month,
      lastClaimed.day,
    );

    final currentDate =
        DateTime(serverNow.year, serverNow.month, serverNow.day);

    return lastClaimedDate
        .isBefore(currentDate); // Allow claim if it's a new day
  }

  Future<void> claimReward({
    required String userWallet,
    required int day,
  }) async {
    try {
      // Fetch user data from server
      final userDoc = await getUser(userWallet);
      final userData = userDoc.data();
      final claimedDays = List<int>.from(userData?['claimed_days'] ?? []);

      // Check if reward is already claimed
      if (claimedDays.contains(day)) {
        throw Exception('Reward already claimed for Day $day');
      }

      // Check sequential claiming
      final expectedDay = claimedDays.length + 1;
      if (day != expectedDay) {
        throw Exception('You must claim in order! (Next up: Day $expectedDay)');
      }

      // Check if user can claim today
      final canClaim = await canClaimToday(userWallet);
      if (!canClaim) {
        throw Exception('You can only claim one reward per day!');
      }

      // Call Node.js server to send SOL
      final response = await _dio.post(
        'https://wagus-claim-silnt-a3ca9e3fbf49.herokuapp.com/claim', // Update to real server IP
        data: {
          'userWallet': userWallet,
          'day': day,
        },
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['INTERNAL_API_KEY']}'
        }),
      );

      if (response.statusCode == 200) {
        // Update Firestore with claimed day and last_claimed timestamp
        await usersCollection.doc(userWallet).set({
          'claimed_days': FieldValue.arrayUnion([day]),
          'last_claimed': FieldValue.serverTimestamp(),
          'last_login': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        throw Exception('Claim server returned error: ${response.data}');
      }
    } catch (e) {
      throw Exception('Claim failed: $e');
    }
  }

  Future<List<int>> fetchClaimedDays(String wallet) async {
    final userDoc = await getUser(wallet);
    final userData = userDoc.data();
    return List<int>.from(userData?['claimed_days'] ?? []);
  }
}
