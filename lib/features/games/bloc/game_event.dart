part of 'game_bloc.dart';

sealed class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object> get props => [];
}

class GameSpygusInitializeEvent extends GameEvent {
  const GameSpygusInitializeEvent();
}

class GameListenGuessDrawingSession extends GameEvent {
  final String sessionId;
  const GameListenGuessDrawingSession(this.sessionId);

  @override
  List<Object> get props => [sessionId];
}
