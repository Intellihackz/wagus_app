part of 'lottery_bloc.dart';

@immutable
sealed class LotteryEvent {}

class LotteryAddToPoolEvent extends LotteryEvent {
  final int amount;
  final PrivyUser user;

  LotteryAddToPoolEvent({required this.amount, required this.user});
}
