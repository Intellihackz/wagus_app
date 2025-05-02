part of 'game_bloc.dart';

class GameState extends Equatable {
  const GameState({this.spygusGameData});

  final SpygusGameData? spygusGameData;

  @override
  List<Object> get props => [];

  GameState copyWith({
    SpygusGameData? Function()? spygusGameData,
  }) {
    return GameState(
      spygusGameData: spygusGameData != null ? spygusGameData() : null,
    );
  }
}
