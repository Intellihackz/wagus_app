part of 'portal_bloc.dart';

class PortalState extends Equatable {
  final int holdersCount;
  final PrivyUser? user;
  final Holder? holder;
  final String currentTokenAddress;

  const PortalState({
    this.holdersCount = 0,
    this.user,
    this.holder,
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
      currentTokenAddress: currentTokenAddress ?? this.currentTokenAddress,
    );
  }

  @override
  List<Object?> get props => [holdersCount, user, holder, currentTokenAddress];
}
