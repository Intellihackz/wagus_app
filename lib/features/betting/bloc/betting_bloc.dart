import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'betting_event.dart';
part 'betting_state.dart';

class BettingBloc extends Bloc<BettingEvent, BettingState> {
  BettingBloc() : super(BettingInitial()) {
    on<BettingEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
