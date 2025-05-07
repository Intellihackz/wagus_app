part of 'home_bloc.dart';

class HomeState {
  final List<Message> messages;
  final String currentRoom;
  final int activeUsersCount;

  const HomeState({
    required this.messages,
    this.currentRoom = 'General',
    this.activeUsersCount = 0,
  });

  HomeState copyWith({
    List<Message>? messages,
    String? currentRoom,
    int? activeUsersCount,
  }) {
    return HomeState(
      messages: messages ?? this.messages,
      currentRoom: currentRoom ?? this.currentRoom,
      activeUsersCount: activeUsersCount ?? this.activeUsersCount,
    );
  }
}
