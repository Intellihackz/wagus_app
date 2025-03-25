part of 'incubator_bloc.dart';

class IncubatorState {
  final IncubatorSubmissionStatus status;
  final List<Project> projects;
  final Set<String> likedProjectsIds;
  final IncubatorTransactionStatus transactionStatus;

  const IncubatorState({
    required this.status,
    required this.projects,
    required this.likedProjectsIds,
    required this.transactionStatus,
  });

  IncubatorState copyWith({
    IncubatorSubmissionStatus? status,
    List<Project>? projects,
    Set<String>? likedProjectIds,
    IncubatorTransactionStatus? transactionStatus,
  }) {
    return IncubatorState(
      status: status ?? this.status,
      projects: projects ?? this.projects,
      likedProjectsIds: likedProjectIds ?? likedProjectsIds,
      transactionStatus: transactionStatus ?? this.transactionStatus,
    );
  }
}

enum IncubatorSubmissionStatus { initial, submitting, success, failure }

enum IncubatorTransactionStatus { initial, submitting, success, failure }
