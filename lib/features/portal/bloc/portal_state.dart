part of 'portal_bloc.dart';

class PortalState {
  final int holdersCount;
  final PrivyUser? user;
  final Holder? holder;

  const PortalState({
    this.holdersCount = 1872,
    this.user,
    this.holder,
  });

  PortalState copyWith({
    int? holdersCount,
    PrivyUser? Function()? user,
    Holder? Function()? holder,
  }) {
    return PortalState(
      holdersCount: holdersCount ?? this.holdersCount,
      user: user?.call() ?? this.user,
      holder: holder?.call() ?? this.holder,
    );
  }
}
