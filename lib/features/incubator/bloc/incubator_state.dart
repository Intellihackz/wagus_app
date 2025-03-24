part of 'incubator_bloc.dart';

class IncubatorState {
  final IncubatorSubmissionStatus status;
  final List<Project> projects;
  final List<String> likedProjectsIds;

  const IncubatorState({
    required this.status,
    required this.projects,
    required this.likedProjectsIds,
  });

  IncubatorState copyWith({
    IncubatorSubmissionStatus? status,
    List<Project>? projects,
    List<String>? likedProjectsIds,
  }) {
    return IncubatorState(
      status: status ?? this.status,
      projects: projects ?? this.projects,
      likedProjectsIds: likedProjectsIds ?? this.likedProjectsIds,
    );
  }
}

enum IncubatorSubmissionStatus { initial, submitting, success, failure }
