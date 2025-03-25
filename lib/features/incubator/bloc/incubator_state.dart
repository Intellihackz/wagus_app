part of 'incubator_bloc.dart';

class IncubatorState {
  final IncubatorSubmissionStatus status;
  final List<Project> projects;
  final Set<String> likedProjectsIds;

  const IncubatorState({
    required this.status,
    required this.projects,
    required this.likedProjectsIds,
  });

  IncubatorState copyWith({
    IncubatorSubmissionStatus? status,
    List<Project>? projects,
    Set<String>? likedProjectIds,
  }) {
    return IncubatorState(
      status: status ?? this.status,
      projects: projects ?? this.projects,
      likedProjectsIds: likedProjectIds ?? likedProjectsIds,
    );
  }
}

enum IncubatorSubmissionStatus { initial, submitting, success, failure }
