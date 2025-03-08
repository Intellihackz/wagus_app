part of 'home_bloc.dart';

class HomeState {
  final List<Message> messages;

  const HomeState({
    required this.messages,
  });

  HomeState copyWith({
    List<Message>? messages,
  }) {
    return HomeState(
      messages: messages ?? this.messages,
    );
  }
}
