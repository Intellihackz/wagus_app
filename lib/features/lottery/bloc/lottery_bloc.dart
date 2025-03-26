import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'package:wagus/features/lottery/data/lottery_repository.dart';
import 'package:wagus/features/lottery/domain/lottery_model.dart';

part 'lottery_event.dart';
part 'lottery_state.dart';

class LotteryBloc extends Bloc<LotteryEvent, LotteryState> {
  final LotteryRepository lotteryRepository;
  LotteryBloc({required this.lotteryRepository})
      : super(LotteryState(
          currentLottery: null,
          lastLottery: null,
          status: LotteryStatus.initial,
        )) {
    on<LotteryInitialEvent>((event, emit) async {
      await lotteryRepository.ensureTodayLotteryExists();

      await emit.forEach(lotteryRepository.getLottery(), onData: (data) {
        print('data: $data');

        final List<LotteryModel> lotteries = data.docs
            .map((doc) =>
                LotteryModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList();

        switch (lotteries.length) {
          case 0:
            return state.copyWith(
              currentLottery: () => null,
              lastLottery: () => null,
            );
          case 1:
            return state.copyWith(
              currentLottery: () => lotteries[0],
              lastLottery: () => null,
            );
          default:
            return state.copyWith(
              currentLottery: () => lotteries[0],
              lastLottery: () => lotteries[1],
            );
        }
      });
    });

    on<LotteryAddToPoolEvent>((event, emit) async {
      emit(state.copyWith(
        status: LotteryStatus.loading,
      ));
      try {
        await lotteryRepository.addToPool(
          wallet: event.user.embeddedSolanaWallets.first,
          amount: event.amount,
          currentLottery: state.currentLottery,
          wagusMint: event.wagusMint,
        );

        emit(state.copyWith(
          status: LotteryStatus.success,
        ));
      } catch (e) {
        emit(state.copyWith(
          status: LotteryStatus.failure,
        ));
      }
    });

    on<LotteryResetStatusEvent>((event, emit) async {
      emit(state.copyWith(status: LotteryStatus.initial));
    });
  }
}
