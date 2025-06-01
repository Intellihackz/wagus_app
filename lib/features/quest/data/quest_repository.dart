import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:wagus/features/home/data/home_repository.dart';
import 'package:wagus/features/home/domain/message.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';

class QuestRepository {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  final Dio _dio = Dio();
  final HomeRepository _homeRepository;

  QuestRepository(this._homeRepository);

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

    if (lastClaimed == null) return true;

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

    return lastClaimedDate.isBefore(currentDate);
  }

  Future<void> claimReward({
    required String userWallet,
    required int day,
    required TierStatus tier, // Inject from PortalBloc
  }) async {
    try {
      final userDoc = await getUser(userWallet);
      final userData = userDoc.data();
      final claimedDays = List<int>.from(userData?['claimed_days'] ?? []);

      if (claimedDays.contains(day)) {
        throw Exception('Reward already claimed for Day $day');
      }

      final expectedDay = claimedDays.length + 1;
      if (day != expectedDay) {
        throw Exception('You must claim in order! (Next up: Day $expectedDay)');
      }

      final canClaim = await canClaimToday(userWallet);
      if (!canClaim) {
        throw Exception('You can only claim one reward per day!');
      }

      final response = await _dio.post(
        'https://wagus-claim-silnt-a3ca9e3fbf49.herokuapp.com/claim',
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
        final updates = {
          'claimed_days': FieldValue.arrayUnion([day]),
          'last_claimed': FieldValue.serverTimestamp(),
          'last_login': FieldValue.serverTimestamp(),
          'rewardNotified':
              false, // ✅ reset so they can get notified again in 24h
        };

        if (day == 7) {
          updates['claimed_days_reset_at'] = FieldValue.serverTimestamp();

          await _homeRepository.sendMessage(Message(
            text:
                '${userWallet.substring(0, 3)}..${userWallet.substring(userWallet.length - 3)} completed all 7 daily rewards! 🎉',
            sender: 'System',
            tier: TierStatus.system,
            room: 'General',
            likedBy: [],
          ));
        } else {
          // ✅ Broadcast regular daily reward claim
          await _homeRepository.sendMessage(Message(
            text:
                '${userWallet.substring(0, 3)}..${userWallet.substring(userWallet.length - 3)} claimed their Day $day reward! 🎁',
            sender: 'System',
            tier: TierStatus.system,
            room: 'General',
            likedBy: [],
          ));
        }

        await usersCollection
            .doc(userWallet)
            .set(updates, SetOptions(merge: true));
      } else {
        throw Exception('Failed to claim reward: ${response.data}');
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
