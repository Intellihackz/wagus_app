import 'package:bloc/bloc.dart';
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
}
