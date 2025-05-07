part of 'quest_bloc.dart';

sealed class QuestEvent extends Equatable {
  const QuestEvent();

  @override
  List<Object> get props => [];
}

class QuestInitialEvent extends QuestEvent {
  final String address;
  const QuestInitialEvent({required this.address});

  @override
  List<Object> get props => [];
}

class QuestClaimDailyRewardEvent extends QuestEvent {
  final int day;
  final String userWalletAddress;
  final TierStatus tier;

  const QuestClaimDailyRewardEvent(
      {required this.day, required this.userWalletAddress, required this.tier});

  @override
  List<Object> get props => [day, userWalletAddress];
}

class QuestClaimedDaysSetEvent extends QuestEvent {
  final Set<int> claimedDays;

  const QuestClaimedDaysSetEvent({required this.claimedDays});

  @override
  List<Object> get props => [claimedDays];
}
