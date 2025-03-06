import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'package:wagus/features/lottery/data/lottery_repository.dart';

part 'lottery_event.dart';
part 'lottery_state.dart';

class LotteryBloc extends Bloc<LotteryEvent, LotteryState> {
  final LotteryRepository lotteryRepository;
  LotteryBloc({required this.lotteryRepository}) : super(LotteryInitial()) {
    on<LotteryAddToPoolEvent>((event, emit) async {
      await lotteryRepository.addToPool(
          wallet: event.user.embeddedSolanaWallets.first, amount: event.amount);
    });
  }
}
