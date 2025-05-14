part of 'home_bloc.dart';

@immutable
sealed class HomeEvent {}

class HomeInitialEvent extends HomeEvent {
  final List<Message> messages;
  final String room;
  final Map<String, DocumentSnapshot> lastDocs;

  HomeInitialEvent({
    required this.messages,
    required this.room,
    required this.lastDocs,
  });
}

class HomeSendMessageEvent extends HomeEvent {
  final Message message;
  final String currentTokenAddress;

  HomeSendMessageEvent(
      {required this.message, required this.currentTokenAddress});
}

class HomeSetRoomEvent extends HomeEvent {
  final String room;
  HomeSetRoomEvent(this.room);
}

class HomeWatchOnlineUsersEvent extends HomeEvent {
  HomeWatchOnlineUsersEvent();
}

class HomeCommandPopupTriggered extends HomeEvent {
  final String input;
  HomeCommandPopupTriggered(this.input);
}

class HomeCommandPopupClosed extends HomeEvent {}

class HomeLaunchGiveawayConfettiEvent extends HomeEvent {
  HomeLaunchGiveawayConfettiEvent();
}

class HomeLoadMoreMessagesEvent extends HomeEvent {
  final String room;
  final DocumentSnapshot lastDoc;

  HomeLoadMoreMessagesEvent(this.room, this.lastDoc);
}

class HomeLiveUpdateEvent extends HomeEvent {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  HomeLiveUpdateEvent(this.docs);
}

class HomeListenToRoomsEvent extends HomeEvent {
  HomeListenToRoomsEvent();
}

class HomeSetReplyMessageEvent extends HomeEvent {
  final Message? message;
  HomeSetReplyMessageEvent(this.message);
}
