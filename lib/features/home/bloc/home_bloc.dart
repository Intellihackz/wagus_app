import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:wagus/features/home/data/home_repository.dart';
import 'package:wagus/features/home/domain/message.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository homeRepository;
  HomeBloc({required this.homeRepository}) : super(HomeState(messages: [])) {
    on<HomeInitialEvent>((event, emit) async {
      await emit.forEach(homeRepository.getMessages(), onData: (data) {
        final messages = data.docs
            .map((doc) => doc.data())
            .toList()
            .cast<Map<String, dynamic>>();

        return state.copyWith(
          messages: messages
              .map((message) => Message(
                    text: message['message'],
                    sender: message['sender'],
                    tier: TierStatus.values.firstWhere(
                      (t) => t.name == (message['tier'] ?? 'Basic'),
                      orElse: () => TierStatus.basic,
                    ),
                  ))
              .toList(),
        );
      });
    });

    on<HomeSendMessageEvent>((event, emit) async {
      await homeRepository.sendMessage(event.message);
    });
  }
}
