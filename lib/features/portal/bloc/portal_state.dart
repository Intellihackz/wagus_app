part of 'portal_bloc.dart';

class PortalState {
  final SolanaWalletAdapter adapter;
  final AuthorizeResult? authorizeResult;
  final int holdersCount;

  const PortalState({
    required this.adapter,
    this.authorizeResult,
    this.holdersCount = 1872,
  });

  PortalState copyWith({
    SolanaWalletAdapter? adapter,
    AuthorizeResult? Function()? authorizeResult,
    int? holdersCount,
  }) {
    return PortalState(
      adapter: adapter ?? this.adapter,
      authorizeResult:
          authorizeResult != null ? authorizeResult() : this.authorizeResult,
      holdersCount: holdersCount ?? this.holdersCount,
    );
  }
}
