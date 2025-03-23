part of 'incubator_bloc.dart';

class IncubatorState {
  final IncubatorSubmissionStatus status;
  final List<Project> projects;

  const IncubatorState({
    required this.status,
    required this.projects,
  });

  IncubatorState copyWith({
    IncubatorSubmissionStatus? status,
    List<Project>? projects,
  }) {
    return IncubatorState(
      status: status ?? this.status,
      projects: projects ?? this.projects,
    );
  }
}

enum IncubatorSubmissionStatus { initial, submitting, success, failure }
