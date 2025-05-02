part of 'portal_bloc.dart';

@immutable
sealed class PortalEvent {}

class PortalInitialEvent extends PortalEvent {}

class PortalAuthorizeEvent extends PortalEvent {
  final BuildContext context;

  PortalAuthorizeEvent(this.context);
}

class PortalRefreshEvent extends PortalEvent {}

class PortalListenTokenAddressEvent extends PortalEvent {}

class PortalClearEvent extends PortalEvent {}

class PortalUpdateTierEvent extends PortalEvent {
  final TierStatus tier;

  PortalUpdateTierEvent(this.tier);
}

class PortalFetchHoldersCountEvent extends PortalEvent {}
