part of 'game_bloc.dart';

class GameState extends Equatable {
  const GameState(
      {this.spygusGameData, this.guessTheDrawingSession, this.chatMessages});

  final SpygusGameData? spygusGameData;
  final GuessTheDrawingSession? guessTheDrawingSession;
  final List<ChatMessageEntry>? chatMessages;

  @override
  List<Object?> get props =>
      [spygusGameData, guessTheDrawingSession, chatMessages];

  GameState copyWith({
    SpygusGameData? Function()? spygusGameData,
    GuessTheDrawingSession? Function()? guessTheDrawingSession,
    List<ChatMessageEntry>? Function()? chatMessages,
  }) {
    return GameState(
      spygusGameData:
          spygusGameData != null ? spygusGameData() : this.spygusGameData,
      guessTheDrawingSession: guessTheDrawingSession != null
          ? guessTheDrawingSession()
          : this.guessTheDrawingSession,
      chatMessages: chatMessages != null ? chatMessages() : this.chatMessages,
    );
  }
}
