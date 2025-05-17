part of 'portal_bloc.dart';

class PortalState extends Equatable {
  final int holdersCount;
  final PrivyUser? user;
  final Holder? holder;
  final TierStatus tierStatus;
  final List<Token> supportedTokens;
  final Token selectedToken;
  final Map<String, Holder>? holdersMap;

  const PortalState({
    this.holdersCount = 0,
    this.user,
    this.holder,
    this.tierStatus = TierStatus.none,
    this.supportedTokens = const [],
    required this.selectedToken,
    this.holdersMap = const {},
  });

  PortalState copyWith({
    int? holdersCount,
    PrivyUser? Function()? user,
    Holder? Function()? holder,
    List<List<Transaction>>? groupedTransactions,
    String? currentTokenAddress,
    TierStatus? tierStatus,
    List<Token>? Function()? supportedTokens,
    Token? Function()? selectedToken,
    Map<String, Holder>? Function()? holdersMap,
  }) {
    return PortalState(
      holdersCount: holdersCount ?? this.holdersCount,
      user: user?.call() ?? this.user,
      holder: holder?.call() ?? this.holder,
      tierStatus: tierStatus ?? this.tierStatus,
      supportedTokens: supportedTokens?.call() ?? this.supportedTokens,
      selectedToken: selectedToken?.call() ?? this.selectedToken,
      holdersMap: holdersMap?.call() ?? this.holdersMap,
    );
  }

  @override
  List<Object?> get props => [
        holdersCount,
        user,
        holder,
        tierStatus,
        supportedTokens,
        selectedToken,
        holdersMap
      ];
}

enum TierStatus {
  basic("Basic", Colors.yellow),
  adventurer("Adventurer", Color.fromARGB(255, 226, 76, 26)),
  elite("Elite", Colors.green),
  creator("Creator", Colors.purple),
  system("System", Colors.cyan),
  none("", Colors.transparent);

  final String name;
  final Color color;

  const TierStatus(this.name, this.color);
}
