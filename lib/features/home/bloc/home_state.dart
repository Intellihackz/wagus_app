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
  final Message? replyingTo;
  final Set<String> announcedGiveawayIds;

  HomeState({
    required this.messages,
    required this.announcedGiveawayIds,
    this.currentRoom = 'General',
    this.activeUsersCount = 0,
    this.commandSearch,
    this.recentCommand,
    this.canLaunchConfetti = false,
    this.lastDocs = const {},
    this.rooms = const ['General', 'Support', 'Games', 'Ideas', 'Tier Lounge'],
    this.replyingTo,
  });

  HomeState copyWith({
    List<Message>? messages,
    String? currentRoom,
    int? activeUsersCount,
    String? Function()? commandSearch,
    String? Function()? recentCommand,
    bool? canLaunchConfetti,
    Map<String, DocumentSnapshot>? lastDocs,
    List<String>? rooms,
    Message? Function()? replyingTo,
    Set<String>? announcedGiveawayIds,
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
      replyingTo: replyingTo != null ? replyingTo() : this.replyingTo,
      announcedGiveawayIds: announcedGiveawayIds ?? this.announcedGiveawayIds,
    );
  }
}
