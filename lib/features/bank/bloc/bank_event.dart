part of 'bank_bloc.dart';

@immutable
sealed class BankEvent {}

class BankWithdrawEvent extends BankEvent {
  final EmbeddedSolanaWallet senderWallet;
  final int amount;
  final String destinationAddress;

  BankWithdrawEvent(
      {required this.senderWallet,
      required this.amount,
      required this.destinationAddress});
}

class BankWithdrawSolEvent extends BankEvent {
  final EmbeddedSolanaWallet senderWallet;
  final double amount;
  final String destinationAddress;

  BankWithdrawSolEvent(
      {required this.senderWallet,
      required this.amount,
      required this.destinationAddress});
}

class BankResetDialogEvent extends BankEvent {}
