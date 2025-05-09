part of 'ai_bloc.dart';

class AiState {
  final SupportedCryptoPredictions selectedCrypto;
  final String response;
  final PredictionType predictionType;
  final AIAnalysisPredictionState predictionState;
  final AIImageGenerationState imageGenerationState;
  final AIWhitePaperFormState whitePaperFormState;
  final AIRoadmapFormState roadmapFormState;
  final AITokenomicsFormState tokenomicsFormState;
  final String? imageUrl;
  final String? errorMessage;
  final String? whitePaper;
  final String? tokenomics;
  final String? roadmap;

  const AiState({
    required this.selectedCrypto,
    required this.response,
    required this.predictionType,
    required this.predictionState,
    required this.imageGenerationState,
    required this.whitePaperFormState,
    required this.roadmapFormState,
    required this.tokenomicsFormState,
    this.imageUrl,
    this.errorMessage,
    this.whitePaper,
    this.roadmap,
    this.tokenomics,
  });

  AiState copyWith({
    SupportedCryptoPredictions? selectedCrypto,
    String? response,
    PredictionType? predictionType,
    AIAnalysisPredictionState? predictionState,
    AIImageGenerationState? imageGenerationState,
    AIWhitePaperFormState? whitePaperFormState,
    AIRoadmapFormState? roadmapFormState,
    AITokenomicsFormState? tokenomicsFormState,
    String? Function()? imageUrl,
    String? Function()? errorMessage,
    String? Function()? whitePaper,
    String? Function()? roadmap,
    String? Function()? tokenomics,
  }) {
    return AiState(
      selectedCrypto: selectedCrypto ?? this.selectedCrypto,
      response: response ?? this.response,
      predictionType: predictionType ?? this.predictionType,
      predictionState: predictionState ?? this.predictionState,
      imageGenerationState: imageGenerationState ?? this.imageGenerationState,
      whitePaperFormState: whitePaperFormState ?? this.whitePaperFormState,
      roadmapFormState: roadmapFormState ?? this.roadmapFormState,
      tokenomicsFormState: tokenomicsFormState ?? this.tokenomicsFormState,
      imageUrl: imageUrl != null ? imageUrl() : this.imageUrl,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      whitePaper: whitePaper != null ? whitePaper() : this.whitePaper,
      roadmap: roadmap != null ? roadmap() : this.roadmap,
      tokenomics: tokenomics != null ? tokenomics() : this.tokenomics,
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

enum AIRoadmapFormState {
  initial,
  loading,
  success,
  failure,
}

enum AITokenomicsFormState {
  initial,
  loading,
  success,
  failure,
}
