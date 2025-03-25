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
