import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wagus/features/rpg/domain/skill_registry.dart';

class UserService {
  final usersCollection = FirebaseFirestore.instance.collection('users');
  static final onlineUsersCollection = FirebaseFirestore.instance
      .collection('users')
      .where('is_online', isEqualTo: true)
      .snapshots();

  static Stream<int> getLiveUserCount() {
    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(minutes: 2)),
    );

    return FirebaseFirestore.instance
        .collection('users')
        .where('last_active', isGreaterThan: cutoff)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> updateUserLogin(String walletAddress) async {
    final userRef = usersCollection.doc(walletAddress);
    final doc = await userRef.get();
    final data = doc.data() ?? {};

    final isXpMissing = data['xp'] is! Map;

    final Map<String, dynamic> updatePayload = {
      'wallet': walletAddress,
      'last_login': FieldValue.serverTimestamp(),
    };

    if (isXpMissing) {
      updatePayload['xp'] = {
        for (final skill in SkillRegistry.all()) skill.id: 0,
      };
    }

    await userRef.set(updatePayload, SetOptions(merge: true));
  }

  Future<void> ensureXpMapInitialized(String wallet) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(wallet);
    final snapshot = await userRef.get();

    final data = snapshot.data();
    final xpMap = data?['xpMap'] as Map<String, dynamic>?;

    if (xpMap != null && xpMap.isNotEmpty) {
      return; // ✅ Already initialized
    }

    final defaultXpMap = {
      for (final skill in SkillRegistry.all()) skill.id: 0,
    };

    await userRef.set({'xpMap': defaultXpMap}, SetOptions(merge: true));
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
      'adventurer_expires': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 30)),
      ),
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

    final now = DateTime.now();
    final difference = now.difference(playedAt).inDays;

    return difference < 7;
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

  Future<void> setUsername(String walletAddress, String username) async {
    if (username.length > 8) {
      throw Exception("Username must be 8 characters or fewer.");
    }

    await usersCollection.doc(walletAddress).set({
      'username': username,
    }, SetOptions(merge: true));
  }

  Future<void> updateMemoryBreachScore(
      String walletAddress, int newScore) async {
    final doc = await usersCollection.doc(walletAddress).get();
    final existingScore = doc.data()?['memory_breach_score'] ?? 0;

    if (newScore > existingScore) {
      await usersCollection.doc(walletAddress).set({
        'memory_breach_score': newScore,
      }, SetOptions(merge: true));
    }
  }

  Future<String> getDisplayName(String walletAddress) async {
    final doc = await usersCollection.doc(walletAddress).get();
    final data = doc.data();
    final username = data?['username'];

    if (username != null && username.toString().trim().isNotEmpty) {
      return username;
    }

    return '${walletAddress.substring(0, 6)}...';
  }

  Future<String> getEffectiveTier(String walletAddress) async {
    final doc = await usersCollection.doc(walletAddress).get();
    final data = doc.data();
    if (data == null) return 'basic';

    final tier = (data['tier'] ?? 'basic').toString();
    final expires = data['adventurer_expires'];
    DateTime? expiresAt;

    if (expires != null && expires is Timestamp) {
      expiresAt = expires.toDate();
    }

    final isExpired = tier == 'Adventurer' &&
        (expiresAt == null || expiresAt.isBefore(DateTime.now()));
    return isExpired ? 'basic' : tier;
  }

  Future<void> markCodeNavigatorFound(String walletAddress) async {
    await usersCollection.doc(walletAddress).set({
      'code_navigator_found': true,
    }, SetOptions(merge: true));
  }
}
