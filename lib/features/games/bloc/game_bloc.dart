import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wagus/features/games/data/game_repository.dart';
import 'package:wagus/features/games/domain/guess_the_drawing/guess_the_drawing_session.dart';
import 'package:wagus/features/games/domain/spygus_game_data.dart';
import 'package:wagus/features/home/data/home_repository.dart';

part 'game_event.dart';
part 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  final GameRepository gameRepository;
  final HomeRepository homeRepository;
  GameBloc({required this.gameRepository, required this.homeRepository})
      : super(GameState()) {
    on<GameSpygusInitializeEvent>((event, emit) async {
      await emit.forEach(gameRepository.getLatestSpygusInfo(), onData: (data) {
        return state.copyWith(spygusGameData: () {
          return data;
        });
      });
    });

    on<GameListenGuessDrawingSession>((event, emit) async {
      await emit.forEach<GuessTheDrawingSession>(
        gameRepository.streamGuessDrawingSession(event.sessionId),
        onData: (session) => state.copyWith(
          guessTheDrawingSession: () => session,
        ),
      );
    });
  }
}
