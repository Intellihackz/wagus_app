class Transaction {
  final String asset;
  final double amount;

  Transaction({
    required this.asset,
    required this.amount,
  });

  @override
  String toString() {
    return 'Transaction(asset: $asset, amount: $amount)';
  }
}
