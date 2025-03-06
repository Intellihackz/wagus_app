part of 'chat_bloc.dart';

class ChatState {
  final List<Message> messages;

  const ChatState({required this.messages});

  ChatState copyWith({List<Message>? messages}) {
    return ChatState(
      messages: messages ?? this.messages,
    );
  }
}
