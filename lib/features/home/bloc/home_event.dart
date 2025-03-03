part of 'home_bloc.dart';

@immutable
sealed class HomeEvent {}

class HomeInitialEvent extends HomeEvent {}

class HomeTransactionEvent extends HomeEvent {
  // adds a trasaction to the stream
  final Transaction transaction;

  HomeTransactionEvent({required this.transaction});
}
