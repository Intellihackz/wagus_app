part of 'chat_bloc.dart';

class ChatState {
  final List<String> messages;

  const ChatState({required this.messages});

  ChatState copyWith({List<String>? messages}) {
    return ChatState(
      messages: messages ?? this.messages,
    );
  }
}
