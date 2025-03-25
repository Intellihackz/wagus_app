part of 'ai_bloc.dart';

class AiState {
  final SupportedCryptoPredictions selectedCrypto;
  final String response;
  final PredictionType predictionType;
  final AIAnalysisPredictionState predictionState;
  final AIImageGenerationState imageGenerationState;
  final String? imageUrl;
  final String? errorMessage;

  const AiState({
    required this.selectedCrypto,
    required this.response,
    required this.predictionType,
    required this.predictionState,
    required this.imageGenerationState,
    this.imageUrl,
    this.errorMessage,
  });

  AiState copyWith({
    SupportedCryptoPredictions? selectedCrypto,
    String? response,
    PredictionType? predictionType,
    AIAnalysisPredictionState? predictionState,
    AIImageGenerationState? imageGenerationState,
    String? Function()? imageUrl,
    String? Function()? errorMessage,
  }) {
    return AiState(
      selectedCrypto: selectedCrypto ?? this.selectedCrypto,
      response: response ?? this.response,
      predictionType: predictionType ?? this.predictionType,
      predictionState: predictionState ?? this.predictionState,
      imageGenerationState: imageGenerationState ?? this.imageGenerationState,
      imageUrl: imageUrl != null ? imageUrl() : this.imageUrl,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

enum AIAnalysisPredictionState {
  initial,
  loading,
  success,
  failure,
}

enum AIImageGenerationState {
  initial,
  loading,
  success,
  failure,
}
