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

  HomeSendMessageEvent({required this.message});
}

class HomeSetRoomEvent extends HomeEvent {
  final String room;
  HomeSetRoomEvent(this.room);
}
