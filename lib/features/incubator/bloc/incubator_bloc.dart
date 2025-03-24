import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:wagus/features/incubator/data/incubator_repository.dart';
import 'package:wagus/features/incubator/domain/project.dart';

part 'incubator_event.dart';
part 'incubator_state.dart';

class IncubatorBloc extends Bloc<IncubatorEvent, IncubatorState> {
  final IncubatorRepository incubatorRepository;
  IncubatorBloc({required this.incubatorRepository})
      : super(IncubatorState(
            status: IncubatorSubmissionStatus.initial,
            projects: [],
            likedProjectsIds: [])) {
    on<IncubatorInitialEvent>((event, emit) async {
      await emit.forEach(incubatorRepository.getProjects(), onData: (data) {
        final projects = data.docs
            .map((doc) => doc.data())
            .toList()
            .cast<Map<String, dynamic>>();

        return state.copyWith(
          projects:
              projects.map((project) => Project.fromJson(project)).toList(),
        );
      });
    });

    on<IncubatorFindLikedProjectsEvent>((event, emit) async {
      await emit.forEach(incubatorRepository.getUserLikedProjects(event.userId),
          onData: (data) {
        final likedProjectIds =
            data.docs.map((doc) => doc.reference.parent.parent!.id).toSet();

        return state.copyWith(
          likedProjectsIds: likedProjectIds.toList(),
        );
      });
    });

    on<IncubatorProjectSubmitEvent>((event, emit) async {
      emit(state.copyWith(status: IncubatorSubmissionStatus.submitting));
      try {
        await incubatorRepository.submitProject(
            event.project, event.whitePaperFile, event.roadMapFile);

        emit(state.copyWith(
          status: IncubatorSubmissionStatus.success,
        ));
      } on Exception catch (e, __) {
        emit(state.copyWith(
          status: IncubatorSubmissionStatus.failure,
        ));
        return;
      }
    });

    on<IncubatorProjectLikeEvent>((event, emit) async {
      try {
        await incubatorRepository.likeProject(event.projectId, event.userId);
      } on Exception catch (e, __) {
        return;
      }
    });
  }
}
