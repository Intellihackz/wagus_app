part of 'home_bloc.dart';

class HomeState {
  final List<List<Transaction>> groupedTransactions;

  const HomeState({
    required this.groupedTransactions,
  });

  HomeState copyWith({
    List<List<Transaction>>? groupedTransactions,
  }) {
    return HomeState(
      groupedTransactions: groupedTransactions ?? this.groupedTransactions,
    );
  }
}
