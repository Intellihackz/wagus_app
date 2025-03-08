part of 'home_bloc.dart';

@immutable
sealed class HomeEvent {}

class HomeInitialEvent extends HomeEvent {}

class HomeSendMessageEvent extends HomeEvent {
  final Message message;

  HomeSendMessageEvent({required this.message});
}
