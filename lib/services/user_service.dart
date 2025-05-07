import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final usersCollection = FirebaseFirestore.instance.collection('users');
  static final onlineUsersCollection = FirebaseFirestore.instance
      .collection('users')
      .where('is_online', isEqualTo: true)
      .snapshots();

  static Stream<int> getLiveUserCount() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('is_online', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> updateUserLogin(String walletAddress) async {
    await usersCollection.doc(walletAddress).set({
      'wallet': walletAddress,
      'last_login': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String walletAddress) {
    return usersCollection.doc(walletAddress).get();
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(
      String walletAddress) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(walletAddress)
        .snapshots();
  }

  Future<void> updateClaimedDay(String walletAddress, int day) async {
    await usersCollection.doc(walletAddress).set({
      'claimed_days': FieldValue.arrayUnion([day]),
      'last_claimed': FieldValue.serverTimestamp(),
      'last_login': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> resetClaims(String walletAddress) async {
    await usersCollection.doc(walletAddress).set({
      'claimed_days': [],
      'last_claimed': null,
      'last_login': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> upgradeTier(String walletAddress, String newTier) async {
    await usersCollection.doc(walletAddress).set({
      'tier': newTier,
      'last_login': FieldValue.serverTimestamp(),
      'wallet': walletAddress,
    }, SetOptions(merge: true));
  }

  Future<void> setSpygusPlayed(String walletAddress) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(walletAddress)
        .set({
      'spygus_played_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> hasPlayedSpygus(String walletAddress) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(walletAddress)
        .get();
    final playedAt = (doc.data()?['spygus_played_at'] as Timestamp?)?.toDate();

    if (playedAt == null) return false;

    final lastPlayed = DateTime(playedAt.year, playedAt.month, playedAt.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return lastPlayed.isAtSameMomentAs(today);
  }

  Future<void> setUserOnline(String walletAddress) async {
    await usersCollection.doc(walletAddress).set({
      'is_online': true,
      'last_active': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setUserOffline(String walletAddress) async {
    await usersCollection.doc(walletAddress).update({'is_online': false});
  }
}
