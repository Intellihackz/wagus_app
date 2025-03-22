import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'incubator_event.dart';
part 'incubator_state.dart';

class IncubatorBloc extends Bloc<IncubatorEvent, IncubatorState> {
  IncubatorBloc() : super(IncubatorState()) {
    on<IncubatorEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
