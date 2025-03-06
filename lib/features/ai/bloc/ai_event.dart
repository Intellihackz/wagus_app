part of 'ai_bloc.dart';

@immutable
sealed class AiEvent {}

class AIGeneratePredictionEvent extends AiEvent {
  final SupportedCryptoPredictions selectedCrypto;

  AIGeneratePredictionEvent(this.selectedCrypto);
}
