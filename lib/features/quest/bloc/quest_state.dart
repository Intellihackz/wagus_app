part of 'quest_bloc.dart';

class QuestState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final Set<int> claimedDays;
  final int? currentlyClaimingDay;
  final bool claimSuccess;
  final Timestamp? lastClaimed;
  final Timestamp? serverNow;

  const QuestState({
    this.isLoading = false,
    this.errorMessage,
    this.claimedDays = const {},
    this.currentlyClaimingDay,
    this.claimSuccess = false,
    this.lastClaimed,
    this.serverNow,
  });

  QuestState copyWith({
    bool? isLoading,
    String? Function()? errorMessage,
    Set<int>? claimedDays,
    int? Function()? currentlyClaimingDay,
    bool? claimSuccess,
    Timestamp? Function()? lastClaimed,
    Timestamp? Function()? serverNow,
  }) {
    return QuestState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      claimedDays: claimedDays ?? this.claimedDays,
      currentlyClaimingDay: currentlyClaimingDay != null
          ? currentlyClaimingDay()
          : this.currentlyClaimingDay,
      claimSuccess: claimSuccess ?? this.claimSuccess,
      lastClaimed: lastClaimed != null ? lastClaimed() : this.lastClaimed,
      serverNow: serverNow != null ? serverNow() : this.serverNow,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        claimedDays,
        currentlyClaimingDay,
        claimSuccess,
        lastClaimed,
        serverNow,
      ];
}
