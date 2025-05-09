part of 'ai_bloc.dart';

@immutable
sealed class AiEvent {}

class AIGeneratePredictionEvent extends AiEvent {
  final SupportedCryptoPredictions selectedCrypto;

  AIGeneratePredictionEvent(this.selectedCrypto);
}

class AIGenerateImageEvent extends AiEvent {
  final String prompt;

  AIGenerateImageEvent(this.prompt);
}

class AIResetStateEvent extends AiEvent {}

class AISubmitWhitePaperFormEvent extends AiEvent {
  final String projectName;
  final String projectDescription;
  final String projectPurpose;
  final String projectType;
  final String projectContributors;

  AISubmitWhitePaperFormEvent({
    required this.projectName,
    required this.projectDescription,
    required this.projectPurpose,
    required this.projectType,
    required this.projectContributors,
  });
}

class AISubmitRoadmapFormEvent extends AiEvent {
  final String projectName;
  final String milestones;
  final String duration;

  AISubmitRoadmapFormEvent({
    required this.projectName,
    required this.milestones,
    required this.duration,
  });
}

class AISubmitTokenomicsFormEvent extends AiEvent {
  final String projectName;
  final String tokenSupply;
  final String tokenUtility;
  final String tokenDistribution;

  AISubmitTokenomicsFormEvent({
    required this.projectName,
    required this.tokenSupply,
    required this.tokenUtility,
    required this.tokenDistribution,
  });
}
