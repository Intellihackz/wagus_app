part of 'portal_bloc.dart';

class PortalState {
  final AuthorizeResult? authorizeResult;
  final int holdersCount;

  const PortalState({
    this.authorizeResult,
    this.holdersCount = 1872,
  });

  PortalState copyWith({
    SolanaWalletAdapter? adapter,
    AuthorizeResult? Function()? authorizeResult,
    int? holdersCount,
  }) {
    return PortalState(
      authorizeResult:
          authorizeResult != null ? authorizeResult() : this.authorizeResult,
      holdersCount: holdersCount ?? this.holdersCount,
    );
  }
}
