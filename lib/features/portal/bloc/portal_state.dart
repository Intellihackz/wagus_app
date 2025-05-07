part of 'portal_bloc.dart';

class PortalState extends Equatable {
  final int holdersCount;
  final PrivyUser? user;
  final Holder? holder;
  final String currentTokenAddress;
  final TierStatus tierStatus;

  const PortalState({
    this.holdersCount = 0,
    this.user,
    this.holder,
    required this.currentTokenAddress,
    this.tierStatus = TierStatus.none,
  });

  PortalState copyWith({
    int? holdersCount,
    PrivyUser? Function()? user,
    Holder? Function()? holder,
    List<List<Transaction>>? groupedTransactions,
    String? currentTokenAddress,
    TierStatus? tierStatus,
  }) {
    return PortalState(
      holdersCount: holdersCount ?? this.holdersCount,
      user: user?.call() ?? this.user,
      holder: holder?.call() ?? this.holder,
      currentTokenAddress: currentTokenAddress ?? this.currentTokenAddress,
      tierStatus: tierStatus ?? this.tierStatus,
    );
  }

  @override
  List<Object?> get props =>
      [holdersCount, user, holder, currentTokenAddress, tierStatus];
}

enum TierStatus {
  basic("Basic", Colors.yellow),
  adventurer("Adventurer", Colors.red),
  elite("Elite", Colors.green),
  creator("Creator", Colors.purple),
  system("System", Colors.cyan),
  none("", Colors.transparent);

  final String name;
  final Color color;

  const TierStatus(this.name, this.color);
}
