part of 'lottery_bloc.dart';

class LotteryState {
  final LotteryModel? currentLottery;
  final LotteryModel? lastLottery;
  final LotteryStatus status;

  const LotteryState(
      {this.currentLottery, this.lastLottery, required this.status});

  LotteryState copyWith({
    LotteryModel? Function()? currentLottery,
    LotteryModel? Function()? lastLottery,
    LotteryStatus? status,
  }) {
    return LotteryState(
      currentLottery:
          currentLottery != null ? currentLottery() : this.currentLottery,
      lastLottery: lastLottery != null ? lastLottery() : this.lastLottery,
      status: status ?? this.status,
    );
  }
}

enum LotteryStatus {
  initial,
  loading,
  success,
  failure,
}
