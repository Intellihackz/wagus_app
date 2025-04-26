import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final usersCollection = FirebaseFirestore.instance.collection('users');

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
}
