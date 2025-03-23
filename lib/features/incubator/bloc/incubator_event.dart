part of 'incubator_bloc.dart';

@immutable
sealed class IncubatorEvent {}

class IncubatorInitialEvent extends IncubatorEvent {}

class IncubatorProjectSubmitEvent extends IncubatorEvent {
  final Project project;
  final File? whitePaperFile;
  final File? roadMapFile;

  IncubatorProjectSubmitEvent(this.project,
      {this.whitePaperFile, this.roadMapFile});
}
