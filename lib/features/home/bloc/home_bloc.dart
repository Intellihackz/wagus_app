import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:wagus/features/home/data/home_repository.dart';
import 'package:wagus/features/home/domain/message.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  StreamSubscription? roomSub;

  final HomeRepository homeRepository;
  HomeBloc({required this.homeRepository}) : super(HomeState(messages: [])) {
    on<HomeSetRoomEvent>((event, emit) async {
      log('Setting room to ${event.room}');
      if (roomSub != null && event.room == state.currentRoom) return;

      roomSub?.cancel();

      roomSub = homeRepository.getMessages(event.room).listen((data) {
        final messages = data.docs
            .map((doc) => doc.data())
            .toList()
            .cast<Map<String, dynamic>>();

        add(HomeInitialEvent(
          messages: messages
              .map((msg) => Message(
                    text: msg['message'],
                    sender: msg['sender'],
                    room: (msg['room'] as String?)?.trim().isNotEmpty == true
                        ? msg['room']
                        : 'General',
                    tier: TierStatus.values.firstWhere(
                      (t) => t.name == (msg['tier'] ?? 'Basic'),
                      orElse: () => TierStatus.basic,
                    ),
                  ))
              .toList(),
          room: event.room, // 👈 you forgot this before
        ));
      });
    });

    on<HomeInitialEvent>((event, emit) {
      emit(state.copyWith(
        messages: event.messages,
        currentRoom: event.room,
      ));
    });

    on<HomeSendMessageEvent>((event, emit) async {
      await homeRepository.sendMessage(event.message);
    });
  }

  @override
  Future<void> close() {
    roomSub?.cancel();
    return super.close();
  }
}
