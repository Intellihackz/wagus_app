part of 'home_bloc.dart';

class HomeState {
  final List<Message> messages;
  final String currentRoom;

  const HomeState({
    required this.messages,
    this.currentRoom = 'General',
  });

  HomeState copyWith({List<Message>? messages, String? currentRoom}) {
    return HomeState(
      messages: messages ?? this.messages,
      currentRoom: currentRoom ?? this.currentRoom,
    );
  }
}
