part of 'home_bloc.dart';

class HomeState {
  final List<Message> messages;
  final String currentRoom;
  final int activeUsersCount;
  final String? commandSearch;
  final String? recentCommand;
  final bool canLaunchConfetti;
  final Map<String, DocumentSnapshot> lastDocs;
  final List<String> rooms;

  HomeState(
      {required this.messages,
      this.currentRoom = 'General',
      this.activeUsersCount = 0,
      this.commandSearch,
      this.recentCommand,
      this.canLaunchConfetti = false,
      this.lastDocs = const {},
      this.rooms = const [
        'General',
        'Support',
        'Games',
        'Ideas',
        'Tier Lounge'
      ]});

  HomeState copyWith({
    List<Message>? messages,
    String? currentRoom,
    int? activeUsersCount,
    String? Function()? commandSearch,
    String? Function()? recentCommand,
    bool? canLaunchConfetti,
    Map<String, DocumentSnapshot>? lastDocs,
    List<String>? rooms,
  }) {
    return HomeState(
      messages: messages ?? this.messages,
      currentRoom: currentRoom ?? this.currentRoom,
      activeUsersCount: activeUsersCount ?? this.activeUsersCount,
      commandSearch:
          commandSearch != null ? commandSearch() : this.commandSearch,
      recentCommand:
          recentCommand != null ? recentCommand() : this.recentCommand,
      canLaunchConfetti: canLaunchConfetti ?? this.canLaunchConfetti,
      lastDocs: lastDocs ?? this.lastDocs,
      rooms: rooms ?? this.rooms,
    );
  }
}
