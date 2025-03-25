part of 'ai_bloc.dart';

class AiState {
  final SupportedCryptoPredictions selectedCrypto;
  final String response;
  final PredictionType predictionType;
  final AIAnalysisPredictionState predictionState;
  final AIImageGenerationState imageGenerationState;
  final AIWhitePaperFormState whitePaperFormState;
  final String? imageUrl;
  final String? errorMessage;
  final String? whitePaper;

  const AiState({
    required this.selectedCrypto,
    required this.response,
    required this.predictionType,
    required this.predictionState,
    required this.imageGenerationState,
    required this.whitePaperFormState,
    this.imageUrl,
    this.errorMessage,
    this.whitePaper,
  });

  AiState copyWith({
    SupportedCryptoPredictions? selectedCrypto,
    String? response,
    PredictionType? predictionType,
    AIAnalysisPredictionState? predictionState,
    AIImageGenerationState? imageGenerationState,
    AIWhitePaperFormState? whitePaperFormState,
    String? Function()? imageUrl,
    String? Function()? errorMessage,
    String? Function()? whitePaper,
  }) {
    return AiState(
      selectedCrypto: selectedCrypto ?? this.selectedCrypto,
      response: response ?? this.response,
      predictionType: predictionType ?? this.predictionType,
      predictionState: predictionState ?? this.predictionState,
      imageGenerationState: imageGenerationState ?? this.imageGenerationState,
      whitePaperFormState: whitePaperFormState ?? this.whitePaperFormState,
      imageUrl: imageUrl != null ? imageUrl() : this.imageUrl,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      whitePaper: whitePaper != null ? whitePaper() : this.whitePaper,
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

enum AIWhitePaperFormState {
  initial,
  loading,
  success,
  failure,
}
