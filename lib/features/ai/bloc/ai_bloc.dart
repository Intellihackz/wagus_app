import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:wagus/features/ai/data/ai_repository.dart';

part 'ai_event.dart';
part 'ai_state.dart';

class AiBloc extends Bloc<AiEvent, AiState> {
  final AIRepository repository;
  AiBloc({required this.repository})
      : super(AiState(
          selectedCrypto: SupportedCryptoPredictions.none,
          response: '',
          predictionType: PredictionType.none,
          predictionState: AIAnalysisPredictionState.initial,
          imageGenerationState: AIImageGenerationState.initial,
          whitePaperFormState: AIWhitePaperFormState.initial,
        )) {
    on<AIGeneratePredictionEvent>((event, emit) async {
      emit(state.copyWith(
        selectedCrypto: event.selectedCrypto,
        predictionState: AIAnalysisPredictionState.loading,
      ));

      // Try to fetch price first (for meme coins or anything we support later)
      double? price;
      if ([
        SupportedCryptoPredictions.buckazoids,
        SupportedCryptoPredictions.lux,
        SupportedCryptoPredictions.snai,
        SupportedCryptoPredictions.collat,
        SupportedCryptoPredictions.gork,
        SupportedCryptoPredictions.pumpswap,
      ].contains(event.selectedCrypto)) {
        final mint = _getMemeCoinMint(event.selectedCrypto);
        price = await repository.getMemeCoinPrice(mint);
      }

      // Ask the AI using price as context
      final prediction = await repository.makeLongOrShortPrediction(
        selectedCrypto: event.selectedCrypto,
        price: price,
      );

      if (prediction != null) {
        emit(state.copyWith(
          response: prediction.$1,
          predictionType: prediction.$2,
          predictionState: AIAnalysisPredictionState.success,
        ));
      } else {
        emit(state.copyWith(
          response: '⚠️ Failed to generate prediction.',
          predictionType: PredictionType.none,
          predictionState: AIAnalysisPredictionState.failure,
        ));
      }
    });

    on<AIGenerateImageEvent>((event, emit) async {
      emit(
          state.copyWith(imageGenerationState: AIImageGenerationState.loading));
      try {
        final image = await repository.generateImage(prompt: event.prompt);

        if (image == null) {
          return;
        }

        emit(state.copyWith(
            imageUrl: () => image,
            imageGenerationState: AIImageGenerationState.success));
      } on Exception catch (e, _) {
        emit(state.copyWith(
            imageGenerationState: AIImageGenerationState.failure,
            errorMessage: () => e.toString()));
      }
    });

    on<AIResetStateEvent>((event, emit) {
      emit(state.copyWith(
          imageUrl: () => null,
          imageGenerationState: AIImageGenerationState.initial,
          errorMessage: () => null));
    });

    on<AISubmitWhitePaperFormEvent>((event, emit) async {
      emit(state.copyWith(
        whitePaperFormState: AIWhitePaperFormState.loading,
        whitePaper: () => null,
        errorMessage: () => null,
      ));

      try {
        final whitePaper = await repository.generateWhitePaper(
          projectName: event.projectName,
          projectDescription: event.projectDescription,
          projectPurpose: event.projectPurpose,
          projectType: event.projectType,
          projectContributors: event.projectContributors,
        );

        if (whitePaper != null) {
          emit(state.copyWith(
            whitePaperFormState: AIWhitePaperFormState.success,
            whitePaper: () => whitePaper,
            errorMessage: () => null,
          ));
        } else {
          emit(state.copyWith(
            whitePaperFormState: AIWhitePaperFormState.failure,
            errorMessage: () => 'Failed to generate white paper',
          ));
        }
      } catch (e) {
        emit(state.copyWith(
          whitePaperFormState: AIWhitePaperFormState.failure,
          errorMessage: () => e.toString(),
        ));
      }
    });
  }

  String _getMemeCoinMint(SupportedCryptoPredictions coin) {
    switch (coin) {
      case SupportedCryptoPredictions.buckazoids:
        return 'BQQzEvYT4knThhkSPBvSKBLg1LEczisWLhx5ydJipump';
      case SupportedCryptoPredictions.lux:
        return 'BmXfbamFqrBzrqihr9hbSmEsfQUXMVaqshAjgvZupump';
      case SupportedCryptoPredictions.snai:
        return 'Hjw6bEcHtbHGpQr8onG3izfJY5DJiWdt7uk2BfdSpump';
      case SupportedCryptoPredictions.collat:
        return 'C7heQqfNzdMbUFQwcHkL9FvdwsFsDRBnfwZDDyWYCLTZ';
      default:
        return '';
    }
  }
}
