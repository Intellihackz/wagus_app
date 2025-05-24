part of 'game_bloc.dart';

class GameState extends Equatable {
  const GameState({this.spygusGameData, this.guessTheDrawingSession});

  final SpygusGameData? spygusGameData;
  final GuessTheDrawingSession? guessTheDrawingSession;

  @override
  List<Object?> get props => [spygusGameData, guessTheDrawingSession];

  GameState copyWith({
    SpygusGameData? Function()? spygusGameData,
    GuessTheDrawingSession? Function()? guessTheDrawingSession,
  }) {
    return GameState(
      spygusGameData: spygusGameData != null ? spygusGameData() : null,
      guessTheDrawingSession:
          guessTheDrawingSession != null ? guessTheDrawingSession() : null,
    );
  }
}
