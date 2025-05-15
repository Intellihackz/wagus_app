part of 'incubator_bloc.dart';

@immutable
sealed class IncubatorEvent {}

class IncubatorInitialEvent extends IncubatorEvent {
  final String userId;

  IncubatorInitialEvent({required this.userId});
}

class IncubatorFindLikedProjectsEvent extends IncubatorEvent {
  final String userId;

  IncubatorFindLikedProjectsEvent({required this.userId});
}

class IncubatorProjectSubmitEvent extends IncubatorEvent {
  final Project project;
  final File? whitePaperFile;
  final File? roadMapFile;

  IncubatorProjectSubmitEvent(this.project,
      {this.whitePaperFile, this.roadMapFile});
}

class IncubatorProjectLikeEvent extends IncubatorEvent {
  final String projectId;
  final String userId;

  IncubatorProjectLikeEvent(this.projectId, this.userId);
}

class IncubatorProjectUnlikeEvent extends IncubatorEvent {
  final String projectId;
  final String userId;

  IncubatorProjectUnlikeEvent(this.projectId, this.userId);
}

class IncubatorWithdrawEvent extends IncubatorEvent {
  final String projectId;
  final EmbeddedSolanaWallet wallet;
  final int amount;
  final String userId;

  final String tokenAddress; // ✅ dynamic token mint
  final String tokenTicker;

  IncubatorWithdrawEvent({
    required this.projectId,
    required this.wallet,
    required this.amount,
    required this.userId,
    required this.tokenAddress,
    required this.tokenTicker,
  });
}

class IncubatorResetTransactionStatusEvent extends IncubatorEvent {}
