part of 'portal_bloc.dart';

class PortalState {
  final int holdersCount;
  final PrivyUser? user;
  final Holder? holder;
  final List<List<Transaction>> groupedTransactions;

  const PortalState({
    this.holdersCount = 1872,
    this.user,
    this.holder,
    required this.groupedTransactions,
  });

  PortalState copyWith({
    int? holdersCount,
    PrivyUser? Function()? user,
    Holder? Function()? holder,
    List<List<Transaction>>? groupedTransactions,
  }) {
    return PortalState(
      holdersCount: holdersCount ?? this.holdersCount,
      user: user?.call() ?? this.user,
      holder: holder?.call() ?? this.holder,
      groupedTransactions: groupedTransactions ?? this.groupedTransactions,
    );
  }
}
