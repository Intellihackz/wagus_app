part of 'ai_bloc.dart';

class AiState {
  final SupportedCryptoPredictions selectedCrypto;
  final String response;
  final PredictionType predictionType;
  final AIState state;

  const AiState({
    required this.selectedCrypto,
    required this.response,
    required this.predictionType,
    required this.state,
  });

  AiState copyWith({
    SupportedCryptoPredictions? selectedCrypto,
    String? response,
    PredictionType? predictionType,
    AIState? state,
  }) {
    return AiState(
      selectedCrypto: selectedCrypto ?? this.selectedCrypto,
      response: response ?? this.response,
      predictionType: predictionType ?? this.predictionType,
      state: state ?? this.state,
    );
  }
}

enum AIState {
  initial,
  loading,
  success,
  failure,
}
