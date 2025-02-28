import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'portal_event.dart';
part 'portal_state.dart';

class PortalBloc extends Bloc<PortalEvent, PortalState> {
  PortalBloc() : super(PortalInitial()) {
    on<PortalEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
