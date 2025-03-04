part of 'portal_bloc.dart';

class PortalState {
  final int holdersCount;

  const PortalState({
    this.holdersCount = 1872,
  });

  PortalState copyWith({
    int? holdersCount,
  }) {
    return PortalState(
      holdersCount: holdersCount ?? this.holdersCount,
    );
  }
}
