part of 'lottery_bloc.dart';

class LotteryState {
  final LotteryModel? currentLottery;
  final LotteryModel? lastLottery;

  const LotteryState({this.currentLottery, this.lastLottery});

  LotteryState copyWith({
    LotteryModel? Function()? currentLottery,
    LotteryModel? Function()? lastLottery,
  }) {
    return LotteryState(
      currentLottery:
          currentLottery != null ? currentLottery() : this.currentLottery,
      lastLottery: lastLottery != null ? lastLottery() : this.lastLottery,
    );
  }
}
