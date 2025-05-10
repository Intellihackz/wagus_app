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
        await FirebaseFirestore.instance
            .collection('users')
            .doc(event.address)
            .set({
          'claimed_days': [],
          'claimed_days_reset_at': FieldValue.delete(),
        }, SetOptions(merge: true));
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
        emit(state.copyWith(
          isLoading: false,
          currentlyClaimingDay: () => null,
          errorMessage: () => 'Something went wrong',
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
    final resetAt = (data?['claimed_days_reset_at'] as Timestamp?)?.toDate();
    if (resetAt == null) return false;

    // Use server time
    await FirebaseFirestore.instance.collection('serverTime').doc('now').set(
        {'timestamp': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    final serverNowSnap = await FirebaseFirestore.instance
        .collection('serverTime')
        .doc('now')
        .get();
    final now = (serverNowSnap.data()?['timestamp'] as Timestamp).toDate();

    final resetDate = DateTime(resetAt.year, resetAt.month, resetAt.day);
    final today = DateTime(now.year, now.month, now.day);

    return today.isAfter(resetDate);
  }
}
