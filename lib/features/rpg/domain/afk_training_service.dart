import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wagus/features/rpg/domain/skill_registry.dart';

class AfkTrainingService {
  final FirebaseFirestore firestore;

  AfkTrainingService(this.firestore);

  /// Call when user sends /afk str or /afk wis
  Future<void> startTraining(String userId, String stat) async {
    if (!SkillRegistry.isValid(stat)) {
      throw ArgumentError('Invalid skill ID: $stat');
    }

    final now = DateTime.now();
    final userRef = firestore.collection('users').doc(userId);
    final userDoc = await userRef.get();
    final userData = userDoc.data() ?? {};

    // 🧠 Initialize xpMap if missing
    if (userData['xpMap'] is! Map) {
      final defaultXpMap = {
        for (final skill in SkillRegistry.all()) skill.id: 0,
      };
      await userRef.set({'xpMap': defaultXpMap}, SetOptions(merge: true));
    }

    await firestore.collection('afk_sessions').doc(userId).set({
      'stat': stat,
      'startedAt': now.toIso8601String(),
      'lastClaimedAt': now.toIso8601String(),
    });
  }

  /// Call to check XP gain and update user's profile
  Future<int> claimTrainingXP(String userId) async {
    final docRef = firestore.collection('afk_sessions').doc(userId);
    final doc = await docRef.get();

    if (!doc.exists) return 0;

    final data = doc.data()!;
    final lastClaimedAt = DateTime.parse(data['lastClaimedAt']);
    final now = DateTime.now();
    final minutes = now.difference(lastClaimedAt).inMinutes;

    if (minutes <= 0) return 0;

    final xpGained = min(minutes * 2, 500); // cap to prevent abuse
    final stat = data['stat'] as String;

    await firestore.runTransaction((tx) async {
      final userRef = firestore.collection('users').doc(userId);
      tx.update(userRef, {
        'xpMap.$stat': FieldValue.increment(xpGained), // ✅ this line matters
      });
    });

    await docRef.update({'lastClaimedAt': now.toIso8601String()});
    await docRef.delete(); // 🔒 prevent repeat claim

    return xpGained;
  }
}
