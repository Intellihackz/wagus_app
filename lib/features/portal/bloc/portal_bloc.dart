import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:flutter/material.dart';
import 'package:wagus/features/portal/data/portal_repository.dart';

part 'portal_event.dart';
part 'portal_state.dart';

class PortalBloc extends Bloc<PortalEvent, PortalState> {
  final PortalRepository portalRepository;

  PortalBloc({required this.portalRepository}) : super(const PortalState()) {
    on<PortalInitialEvent>(_onPortalInitialEvent);

    on<PortalAuthorizeEvent>((event, emit) async {
      await portalRepository.connect(event.context);
    });
  }

  Future<void> _onPortalInitialEvent(
    PortalInitialEvent event,
    Emitter<PortalState> emit,
  ) async {
    // Initialize portal
    await portalRepository.init();

    // You can add more initialization logic here
    emit(state.copyWith(holdersCount: 1000)); // Example data
  }
}
