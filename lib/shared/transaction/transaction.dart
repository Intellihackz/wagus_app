import 'package:wagus/shared/holder/holder.dart';

class Transaction {
  final Holder holder;
  final double amount;

  Transaction({
    required this.holder,
    required this.amount,
  });

  @override
  String toString() {
    return 'Transaction(asset: $holder, amount: $amount)';
  }
}
