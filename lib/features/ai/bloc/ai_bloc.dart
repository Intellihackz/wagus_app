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
          state: AIState.initial,
        )) {
    on<AIGeneratePredictionEvent>((event, emit) async {
      emit(state.copyWith(
          selectedCrypto: event.selectedCrypto, state: AIState.loading));
      final prediction = await repository.makeLongOrShortPrediction(
          selectedCrypto: event.selectedCrypto);

      if (prediction == null) {
        return;
      }

      emit(state.copyWith(
          response: prediction.$1,
          predictionType: prediction.$2,
          state: AIState.success));
    });
  }
}
