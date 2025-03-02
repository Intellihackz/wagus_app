part of 'chat_bloc.dart';

@immutable
sealed class ChatEvent {}

class ChatInitialEvent extends ChatEvent {}

class ChatSendMessageEvent extends ChatEvent {
  final String message;

  ChatSendMessageEvent({required this.message});
}
