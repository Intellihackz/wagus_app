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
        )) {
    on<AIGeneratePredictionEvent>((event, emit) async {
      emit(state.copyWith(
          selectedCrypto: event.selectedCrypto,
          predictionState: AIAnalysisPredictionState.loading));
      final prediction = await repository.makeLongOrShortPrediction(
          selectedCrypto: event.selectedCrypto);

      if (prediction == null) {
        return;
      }

      emit(state.copyWith(
          response: prediction.$1,
          predictionType: prediction.$2,
          predictionState: AIAnalysisPredictionState.success));
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
  }
}
