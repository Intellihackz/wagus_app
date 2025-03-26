class Holder {
  final HolderType holderType;
  final double holdings;
  final double tokenAmount;
  final double solanaAmount;

  Holder({
    required this.holderType,
    required this.holdings,
    required this.tokenAmount,
    required this.solanaAmount,
  });

  Holder copyWith({
    HolderType? holderType,
    double? holdings,
    double? tokenAmount,
    double? solanaAmount,
  }) {
    return Holder(
      holderType: holderType ?? this.holderType,
      holdings: holdings ?? this.holdings,
      tokenAmount: tokenAmount ?? this.tokenAmount,
      solanaAmount: solanaAmount ?? this.solanaAmount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'holderType': holderType,
      'holdings': holdings,
      'tokenAmount': tokenAmount,
      'solanaAmount': solanaAmount,
    };
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
