part of 'portal_bloc.dart';

class PortalState {
  final SolanaWalletAdapter adapter;
  final AuthorizeResult? authorizeResult;

  const PortalState({
    required this.adapter,
    this.authorizeResult,
  });

  PortalState copyWith({
    SolanaWalletAdapter? adapter,
    AuthorizeResult? Function()? authorizeResult,
  }) {
    return PortalState(
      adapter: adapter ?? this.adapter,
      authorizeResult:
          authorizeResult != null ? authorizeResult() : this.authorizeResult,
    );
  }
}
