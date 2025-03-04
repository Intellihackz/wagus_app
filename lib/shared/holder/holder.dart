class Holder {
  final HolderType holderType;
  final double holdings;

  Holder({
    required this.holderType,
    required this.holdings,
  });

  Holder copyWith({
    HolderType? holderType,
    double? holdings,
  }) {
    return Holder(
      holderType: holderType ?? this.holderType,
      holdings: holdings ?? this.holdings,
    );
  }
}

enum HolderType {
  plankton(asset: 'assets/icons/plankton.png'),
  shrimp(asset: 'assets/icons/shrimp.png'),
  shark(asset: 'assets/icons/shark.png'),
  whale(asset: 'assets/icons/whale.png');

  final String asset;

  const HolderType({required this.asset});
}
