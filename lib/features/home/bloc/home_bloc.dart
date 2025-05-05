import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:wagus/features/home/data/home_repository.dart';
import 'package:wagus/features/home/domain/chat_command.dart';
import 'package:wagus/features/home/domain/chat_command_parser.dart';
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

    Message buildCommandPreview(ChatCommand cmd, Message original) {
      switch (cmd.action.toLowerCase()) {
        // case '/burn':
        //   final amount = cmd.args.isNotEmpty ? cmd.args[0] : '?';
        //   return original.copyWith(
        //     text: '[BURN] ${original.sender} has burned $amount \$WAGUS 🔥',
        //     sender: 'System',
        //   );

        case '/send':
          final amount = cmd.args.isNotEmpty ? cmd.args[0] : '?';
          final target = cmd.args.length > 1 ? cmd.args[1] : 'unknown';

          return original.copyWith(
            text:
                '[SEND] ${original.sender} has sent $amount \$WAGUS to $target 📨',
            sender: 'System',
          );

        // case '/giveaway':
        //   final amount = cmd.args.isNotEmpty ? cmd.args[0] : '?';
        //   final keyword = cmd.flags['keyword'] ?? '???';
        //   final duration = cmd.flags['duration'] ?? '1m';
        //   return original.copyWith(
        //     text:
        //         '[GIVEAWAY] ${original.sender} is giving away $amount \$WAGUS\nType "$keyword" to enter. Ends in $duration ⏳',
        //     sender: 'System',
        //   );

        // case '/request':
        //   final amount = cmd.args.isNotEmpty ? cmd.args[0] : '?';
        //   return original.copyWith(
        //     text:
        //         '[REQUEST] ${original.sender} is requesting $amount \$WAGUS 💰',
        //     sender: 'System',
        //   );

        // case '/rain':
        //   final amount = cmd.args.isNotEmpty ? cmd.args[0] : '?';
        //   return original.copyWith(
        //     text:
        //         '[RAIN] ${original.sender} is making it rain! $amount \$WAGUS will be split among online users 🌧️',
        //     sender: 'System',
        //   );

        case '/flex':
          return original.copyWith(
            text:
                '[FLEX] ${original.sender} has ${original.solBalance} SOL and ${original.wagBalance} \$WAGUS 💼',
            sender: 'System',
          );

        default:
          return original.copyWith(
            text: 'Unknown command: ${cmd.action}',
            sender: 'System',
          );
      }
    }

    on<HomeSendMessageEvent>((event, emit) async {
      final parsed = ChatCommandParser.parse(event.message.text);

      if (parsed != null) {
        final displayMessage = buildCommandPreview(parsed, event.message);
        await homeRepository.sendMessage(displayMessage);
      } else {
        await homeRepository.sendMessage(event.message);
      }
    });
  }

  @override
  Future<void> close() {
    roomSub?.cancel();
    return super.close();
  }
}
