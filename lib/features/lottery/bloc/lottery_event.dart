part of 'lottery_bloc.dart';

@immutable
sealed class LotteryEvent {}

class LotteryInitialEvent extends LotteryEvent {}

class LotteryAddToPoolEvent extends LotteryEvent {
  final int amount;
  final PrivyUser user;
  final String wagusMint;

  LotteryAddToPoolEvent(
      {required this.amount, required this.user, required this.wagusMint});
}

class LotteryResetStatusEvent extends LotteryEvent {}
