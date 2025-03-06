import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:wagus/features/home/data/home_repository.dart';
import 'package:wagus/shared/holder/holder.dart';
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
              holder: Holder(
                holderType: HolderType.plankton,
                holdings: 0.15,
                tokenAmount: 0,
              ),
              amount: 0.15,
            ),
            Transaction(
              holder: Holder(
                holderType: HolderType.plankton,
                holdings: 0.30,
                tokenAmount: 0,
              ),
              amount: 0.30,
            ),
            Transaction(
              holder: Holder(
                holderType: HolderType.shark,
                holdings: 412.45,
                tokenAmount: 0,
              ),
              amount: 146.78,
            ),
          ],
          [
            Transaction(
              holder: Holder(
                holderType: HolderType.shark,
                holdings: 620.00,
                tokenAmount: 0,
              ),
              amount: 219.85,
            ),
            Transaction(
              holder: Holder(
                holderType: HolderType.whale,
                holdings: 1023.88,
                tokenAmount: 0,
              ),
              amount: 404.31,
            ),
            Transaction(
              holder: Holder(
                holderType: HolderType.whale,
                holdings: 950.67,
                tokenAmount: 0,
              ),
              amount: 378.92,
            ),
          ],
          [
            Transaction(
              holder: Holder(
                holderType: HolderType.plankton,
                holdings: 0.05,
                tokenAmount: 0,
              ),
              amount: 0.05,
            ),
            Transaction(
              holder: Holder(
                holderType: HolderType.shark,
                holdings: 529.88,
                tokenAmount: 0,
              ),
              amount: 183.45,
            ),
            Transaction(
              holder: Holder(
                holderType: HolderType.whale,
                holdings: 1200.00,
                tokenAmount: 0,
              ),
              amount: 500.12,
            ),
          ],
          [
            Transaction(
              holder: Holder(
                holderType: HolderType.whale,
                holdings: 1105.55,
                tokenAmount: 0,
              ),
              amount: 450.89,
            ),
          ]
        ],
      ));
    });
  }
}
