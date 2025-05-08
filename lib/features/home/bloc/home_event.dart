part of 'home_bloc.dart';

@immutable
sealed class HomeEvent {}

class HomeInitialEvent extends HomeEvent {
  final List<Message> messages;
  final String room;

  HomeInitialEvent({required this.messages, required this.room});
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
