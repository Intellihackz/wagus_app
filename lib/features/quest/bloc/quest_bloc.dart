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
        emit(state.copyWith(claimedDays: {}));
        await Future.delayed(const Duration(milliseconds: 300));
      }

      final serverNow = await getServerTime();
      if (serverNow == null) {
        print('⚠️ serverNow not available yet, falling back to local time');
      }

      await emit.forEach(
        UserService.getUserStream(event.address),
        onData: (data) {
          final claimedDaysList =
              List<int>.from(data.data()?['claimed_days'] ?? []);
          final lastClaimed = (data.data()?['last_claimed'] as Timestamp?);

          // ✅ Inject serverNow from outer scope each time
          return state.copyWith(
            claimedDays: claimedDaysList.toSet(),
            lastClaimed: () => lastClaimed,
            serverNow: () =>
                serverNow, // ← Make sure it's passed here every time
          );
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
          errorMessage: () => 'Something went wrong. Please try again.',
        ));
      }
    });

    on<QuestClearFeedbackEvent>((event, emit) {
      emit(state.copyWith(claimSuccess: false, errorMessage: null));
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

    final now = (await getServerTime())?.toDate() ?? DateTime.now();

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

  Timestamp? _cachedServerTime;

  Future<Timestamp?> getServerTime() async {
    if (_cachedServerTime != null) return _cachedServerTime;

    final docRef =
        FirebaseFirestore.instance.collection('serverTime').doc('now');
    await docRef.set(
        {'timestamp': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    await Future.delayed(const Duration(milliseconds: 300));
    final snap = await docRef.get();
    _cachedServerTime = snap.data()?['timestamp'] as Timestamp?;
    return _cachedServerTime;
  }
}
