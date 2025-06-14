part of 'portal_bloc.dart';

@immutable
sealed class PortalEvent {}

class PortalInitialEvent extends PortalEvent {}

class PortalAuthorizeEvent extends PortalEvent {
  final BuildContext context;

  PortalAuthorizeEvent(this.context);
}

class PortalRefreshEvent extends PortalEvent {}

class PortalClearEvent extends PortalEvent {}

class PortalUpdateTierEvent extends PortalEvent {
  final TierStatus tier;
  final String walletAddress;

  PortalUpdateTierEvent(this.tier, this.walletAddress);
}

class PortalFetchHoldersCountEvent extends PortalEvent {}

class PortalListenSupportedTokensEvent extends PortalEvent {}

class PortalSetSelectedTokenEvent extends PortalEvent {
  final Token token;
  PortalSetSelectedTokenEvent(this.token);
}
