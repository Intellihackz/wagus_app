// bank_state.dart
part of 'bank_bloc.dart';

enum BankStatus { initial, loading, success, failure }

enum DialogStatus { input, loading, success } // New enum for dialog states

class BankState extends Equatable {
  const BankState({
    required this.status,
    this.dialogStatus = DialogStatus.input, // Default to input state
  });

  final BankStatus status;
  final DialogStatus dialogStatus;

  BankState copyWith({
    BankStatus? status,
    DialogStatus? dialogStatus,
  }) {
    return BankState(
      status: status ?? this.status,
      dialogStatus: dialogStatus ?? this.dialogStatus,
    );
  }

  @override
  List<Object> get props => [status, dialogStatus];
}
