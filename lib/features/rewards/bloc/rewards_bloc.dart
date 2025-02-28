import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'rewards_event.dart';
part 'rewards_state.dart';

class RewardsBloc extends Bloc<RewardsEvent, RewardsState> {
  RewardsBloc() : super(RewardsInitial()) {
    on<RewardsEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
