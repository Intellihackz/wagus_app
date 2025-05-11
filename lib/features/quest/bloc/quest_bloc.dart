import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/features/quest/data/quest_repository.dart';
import 'package:wagus/services/user_service.dart';

part 'quest_event.dart';
part 'quest_state.dart';

class QuestBloc extends Bloc<QuestEvent, QuestState> {
  final QuestRepository questRepository;
  QuestBloc({required this.questRepository}) : super(QuestState()) {
    on<QuestInitialEvent>((event, emit) async {
      final shouldReset = await shouldResetClaimedDays(event.address);

      if (shouldReset) {
        final userRef =
            FirebaseFirestore.instance.collection('users').doc(event.address);
        await userRef.set({
          'claimed_days': [],
          'claimed_days_reset_at': FieldValue.delete(),
        }, SetOptions(merge: true));

        // ✅ Emit manually before listening to stream
        emit(state.copyWith(claimedDays: {}));

        // ⏳ Slight delay to let Firestore process write
        await Future.delayed(const Duration(milliseconds: 300));
      }

      await emit.forEach(
        UserService.getUserStream(event.address),
        onData: (data) {
          final claimedDaysList =
              List<int>.from(data.data()?['claimed_days'] ?? []);
          return state.copyWith(claimedDays: claimedDaysList.toSet());
        },
      );
    });

    on<QuestClaimDailyRewardEvent>((event, emit) async {
      emit(state.copyWith(
        isLoading: true,
        currentlyClaimingDay: () => event.day,
        errorMessage: () => null,
        claimSuccess: false,
      ));

      try {
        // Perform claim (validation happens in repository)
        await questRepository.claimReward(
          userWallet: event.userWalletAddress,
          day: event.day,
          tier: event.tier,
        );

        // Fetch updated claimed days
        final updatedClaimedDays =
            await questRepository.fetchClaimedDays(event.userWalletAddress);

        emit(state.copyWith(
          isLoading: false,
          currentlyClaimingDay: () => null,
          claimedDays: updatedClaimedDays.toSet(),
          claimSuccess: true,
        ));
      } catch (e) {
        print('❌ Claim failed: $e');
        emit(state.copyWith(
          isLoading: false,
          currentlyClaimingDay: () => null,
          errorMessage: () => e.toString(), // ← show real error in snackbar
        ));
      }
    });

    on<QuestClaimedDaysSetEvent>((event, emit) {
      emit(state.copyWith(
        claimedDays: event.claimedDays,
      ));
    });
  }

  Future<bool> shouldResetClaimedDays(String wallet) async {
    final userDoc = await questRepository.getUser(wallet);
    final data = userDoc.data();
    final claimedDays = List<int>.from(data?['claimed_days'] ?? []);
    final lastClaimed = (data?['last_claimed'] as Timestamp?)?.toDate();

    // Get server time
    await FirebaseFirestore.instance.collection('serverTime').doc('now').set(
      {'timestamp': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
    final serverNowSnap = await FirebaseFirestore.instance
        .collection('serverTime')
        .doc('now')
        .get();
    final now = (serverNowSnap.data()?['timestamp'] as Timestamp).toDate();

    final today = DateTime(now.year, now.month, now.day);

    print(
        '📅 Checking reset: days=$claimedDays, lastClaimed=$lastClaimed, today=$today');

    // ✅ Reset if 7 days are claimed and today is after the last claimed day
    if (claimedDays.length == 7 && lastClaimed != null) {
      final lastClaimedDate = DateTime(
        lastClaimed.year,
        lastClaimed.month,
        lastClaimed.day,
      );
      return today.isAfter(lastClaimedDate);
    }

    return false;
  }
}
