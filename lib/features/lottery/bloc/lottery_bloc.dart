import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'lottery_event.dart';
part 'lottery_state.dart';

class LotteryBloc extends Bloc<LotteryEvent, LotteryState> {
  LotteryBloc() : super(LotteryInitial()) {
    on<LotteryEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
