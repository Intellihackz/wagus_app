import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:solana_wallet_adapter/solana_wallet_adapter.dart';
import 'package:wagus/features/portal/data/portal_repository.dart';

part 'portal_event.dart';
part 'portal_state.dart';

class PortalBloc extends Bloc<PortalEvent, PortalState> {
  final PortalRepository portalRepository;
  PortalBloc({required this.portalRepository})
      : super(PortalState(adapter: portalRepository.adapter)) {
    on<PortalInitialEvent>((event, emit) async {
      await portalRepository.init();
    });

    on<PortalAuthorizeEvent>((event, emit) async {
      await portalRepository.connect();
    });
  }
}
