import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:flutter/material.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'package:wagus/features/portal/data/portal_repository.dart';

part 'portal_event.dart';
part 'portal_state.dart';

class PortalBloc extends Bloc<PortalEvent, PortalState> {
  final PortalRepository portalRepository;

  PortalBloc({required this.portalRepository}) : super(const PortalState()) {
    on<PortalInitialEvent>(_onPortalInitialEvent);

    on<PortalAuthorizeEvent>((event, emit) async {
      final user = await portalRepository.connect();

      emit(state.copyWith(user: () => user));
    });
  }

  Future<void> _onPortalInitialEvent(
    PortalInitialEvent event,
    Emitter<PortalState> emit,
  ) async {
    // Initialize portal
    final user = await portalRepository.init();

    // You can add more initialization logic here
    emit(state.copyWith(holdersCount: 1000, user: () => user));
  }
}
