import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wagus/features/games/data/game_repository.dart';
import 'package:wagus/features/games/domain/spygus_game_data.dart';

part 'game_event.dart';
part 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  final GameRepository gameRepository;
  GameBloc({required this.gameRepository}) : super(GameState()) {
    on<GameSpygusInitializeEvent>((event, emit) async {
      await emit.forEach(gameRepository.getLatestSpygusInfo(), onData: (data) {
        return state.copyWith(spygusGameData: () {
          return data;
        });
      });
    });
  }
}
