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
      : super(BankState(status: BankStatus.initial)) {
    on<BankWithdrawEvent>((event, emit) async {
      emit(state.copyWith(status: BankStatus.loading));
      try {
        await bankRepository.withdrawFunds(
            wallet: event.senderWallet,
            amount: event.amount,
            destinationAddress: event.destinationAddress);

        emit(state.copyWith(status: BankStatus.success));
      } on Exception catch (e, __) {
        print("Error: $e");
        emit(state.copyWith(status: BankStatus.failure));
        return;
      }
    });
  }
}
