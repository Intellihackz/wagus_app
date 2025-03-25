import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:wagus/features/bank/data/bank_repository.dart';
import 'package:privy_flutter/src/models/embedded_solana_wallet/embedded_solana_wallet.dart';

part 'bank_event.dart';
part 'bank_state.dart';

class BankBloc extends Bloc<BankEvent, BankState> {
  final BankRepository bankRepository;

  BankBloc({required this.bankRepository})
      : super(const BankState(status: BankStatus.initial)) {
    on<BankWithdrawEvent>((event, emit) async {
      // Show loading in dialog
      emit(state.copyWith(
        status: BankStatus.loading,
        dialogStatus: DialogStatus.loading,
      ));

      try {
        await bankRepository.withdrawFunds(
          wallet: event.senderWallet,
          amount: event.amount,
          destinationAddress: event.destinationAddress,
        );

        // Show success in dialog
        emit(state.copyWith(
          status: BankStatus.success,
          dialogStatus: DialogStatus.success,
        ));

        // Optional: Delay to show success before closing (handled in UI)
      } on Exception catch (e) {
        print("Error: $e");
        emit(state.copyWith(
          status: BankStatus.failure,
          dialogStatus: DialogStatus.input, // Reset to input on failure
        ));
      }
    });

    on<BankResetDialogEvent>((event, emit) {
      emit(state.copyWith(dialogStatus: DialogStatus.input));
    });
  }
}
