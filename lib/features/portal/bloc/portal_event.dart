part of 'portal_bloc.dart';

@immutable
sealed class PortalEvent {}

class PortalInitialEvent extends PortalEvent {}

class PortalAuthorizeEvent extends PortalEvent {
  final BuildContext context;

  PortalAuthorizeEvent(this.context);
}

class PortalGetTransactionsEvent extends PortalEvent {}
