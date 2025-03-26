part of 'portal_bloc.dart';

class PortalState {
  final int holdersCount;
  final PrivyUser? user;
  final Holder? holder;
  final List<List<Transaction>> groupedTransactions;
  final String currentTokenAddress;

  const PortalState({
    this.holdersCount = 1872,
    this.user,
    this.holder,
    required this.groupedTransactions,
    required this.currentTokenAddress,
  });

  PortalState copyWith({
    int? holdersCount,
    PrivyUser? Function()? user,
    Holder? Function()? holder,
    List<List<Transaction>>? groupedTransactions,
    String? currentTokenAddress,
  }) {
    return PortalState(
      holdersCount: holdersCount ?? this.holdersCount,
      user: user?.call() ?? this.user,
      holder: holder?.call() ?? this.holder,
      groupedTransactions: groupedTransactions ?? this.groupedTransactions,
      currentTokenAddress: currentTokenAddress ?? this.currentTokenAddress,
    );
  }
}
