part of 'portal_bloc.dart';

class PortalState {
  final int holdersCount;
  final PrivyUser? user;

  const PortalState({
    this.holdersCount = 1872,
    this.user,
  });

  PortalState copyWith({
    int? holdersCount,
    PrivyUser? Function()? user,
  }) {
    return PortalState(
      holdersCount: holdersCount ?? this.holdersCount,
      user: user?.call() ?? this.user,
    );
  }
}
