import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:wagus/features/bank/data/bank_repository.dart';
import 'package:privy_flutter/src/models/embedded_solana_wallet/embedded_solana_wallet.dart';
import 'package:wagus/shared/token/token.dart';

part 'bank_event.dart';
part 'bank_state.dart';

class BankBloc extends Bloc<BankEvent, BankState> {
  final BankRepository bankRepository;

  BankBloc({required this.bankRepository})
      : super(const BankState(status: BankStatus.initial)) {
    on<BankWithdrawEvent>((event, emit) async {
      emit(state.copyWith(
        status: BankStatus.loading,
        dialogStatus: DialogStatus.loading,
      ));

      try {
        await bankRepository.withdrawFunds(
          wallet: event.senderWallet,
          amount: event.amount,
          destinationAddress: event.destinationAddress,
          wagusMint: event.token.address,
        );

        emit(state.copyWith(
          status: BankStatus.success,
          dialogStatus: DialogStatus.success,
        ));
      } catch (e) {
        emit(state.copyWith(
          status: BankStatus.failure,
          dialogStatus: DialogStatus.input,
        ));
      }
    });

    on<BankWithdrawSolEvent>((event, emit) async {
      emit(state.copyWith(
        dialogStatus: DialogStatus.loading,
        status: BankStatus.loading,
      ));
      try {
        await bankRepository.withdrawSol(
          wallet: event.senderWallet,
          solAmount: event.amount,
          destinationAddress: event.destinationAddress,
        );

        emit(state.copyWith(
          status: BankStatus.success,
          dialogStatus: DialogStatus.success,
        ));
      } on Exception catch (e, _) {
        emit(state.copyWith(
          status: BankStatus.failure,
          dialogStatus: DialogStatus.input,
        ));
      }
    });

    on<BankResetDialogEvent>((event, emit) {
      emit(state.copyWith(dialogStatus: DialogStatus.input));
    });
  }
}
