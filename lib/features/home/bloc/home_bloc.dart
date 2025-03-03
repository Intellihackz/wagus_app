import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:wagus/features/home/data/home_repository.dart';
import 'package:wagus/shared/transaction/transaction.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository homeRepository;
  HomeBloc({required this.homeRepository})
      : super(HomeState(groupedTransactions: [])) {
    on<HomeInitialEvent>((event, emit) async {
      emit(state.copyWith(
        groupedTransactions: [
          [
            Transaction(
                asset: 'assets/background/large_holder.png',
                amount: Random().nextDouble() * 1000),
            Transaction(
                asset: 'assets/background/large_holder.png',
                amount: Random().nextDouble() * 1000),
            Transaction(
                asset: 'assets/background/large_holder.png',
                amount: Random().nextDouble() * 1000),
          ],
          [
            Transaction(
                asset: 'assets/background/large_holder.png',
                amount: Random().nextDouble() * 1000),
            Transaction(
                asset: 'assets/background/large_holder.png',
                amount: Random().nextDouble() * 1000),
            Transaction(
                asset: 'assets/background/large_holder.png',
                amount: Random().nextDouble() * 1000),
          ],
          [
            Transaction(
                asset: 'assets/background/large_holder.png',
                amount: Random().nextDouble() * 1000),
            Transaction(
                asset: 'assets/background/large_holder.png',
                amount: Random().nextDouble() * 1000),
            Transaction(
                asset: 'assets/background/large_holder.png',
                amount: Random().nextDouble() * 1000),
          ],
          [
            Transaction(
                asset: 'assets/background/large_holder.png',
                amount: Random().nextDouble() * 1000),
            Transaction(
                asset: 'assets/background/large_holder.png',
                amount: Random().nextDouble() * 1000),
          ]
        ],
      ));
    });
  }
}
