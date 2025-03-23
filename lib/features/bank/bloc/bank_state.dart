part of 'bank_bloc.dart';

class BankState extends Equatable {
  final BankStatus status;

  const BankState({
    required this.status,
  });

  BankState copyWith({
    BankStatus? status,
  }) {
    return BankState(
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [status];
}

enum BankStatus { initial, loading, success, failure }
