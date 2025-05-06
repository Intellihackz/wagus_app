import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'package:wagus/features/bank/data/bank_repository.dart';
import 'package:wagus/features/home/data/home_repository.dart';
import 'package:wagus/features/home/domain/chat_command.dart';
import 'package:wagus/features/home/domain/chat_command_parser.dart';
import 'package:wagus/features/home/domain/message.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';

part 'home_event.dart';
part 'home_state.dart';

StreamSubscription? giveawaySub;

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  StreamSubscription? roomSub;

  void watchGiveaways(String currentUserWallet, EmbeddedSolanaWallet wallet,
      String mint, BankRepository bank) {
    giveawaySub?.cancel(); // cleanup old one if exists

    giveawaySub = homeRepository.listenToActiveGiveaways().listen((snapshot) {
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final winner = data['winner'];
        final hasSent = data['hasSent'] ?? false;
        final amount = data['amount'];
        final id = doc.id;
        log('🔍 Giveaway check: host=${data['host']} winner=$winner hasSent=$hasSent wallet=$currentUserWallet');

        if (!hasSent && winner != null && currentUserWallet == data['host']) {
          log('🎯 Sending giveaway $id to winner=$winner for $amount \$BUCKAZOIDS');

          bank
              .withdrawFunds(
            wallet: wallet,
            destinationAddress: winner, // ✅ SEND TO WINNER
            amount: amount,
            wagusMint: mint,
          )
              .then((_) async {
            await doc.reference.update({'hasSent': true});
            log('✅ Giveaway reward sent and marked for $id');
          }).catchError((e) {
            log('❌ Failed to send giveaway reward for $id: $e');
          });
        }
      }
    });
  }

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
          room: event.room,
        ));
      });
    });

    on<HomeInitialEvent>((event, emit) {
      emit(state.copyWith(
        messages: event.messages,
        currentRoom: event.room,
      ));
    });

    FutureOr<Message> buildCommandPreview(
        ChatCommand cmd, Message original) async {
      switch (cmd.action.toLowerCase()) {
        case '/send':
          final amount = cmd.args.isNotEmpty ? cmd.args[0] : '?';
          final target = cmd.args.length > 1 ? cmd.args[1] : 'unknown';
          return original.copyWith(
            text:
                '[SEND] ${original.sender} has sent $amount \$WAGUS to $target 📨',
            sender: 'System',
          );

        case '/giveaway':
          if (original.tier != TierStatus.adventurer) {
            return original.copyWith(
              text: '[GIVEAWAY] Only Adventurer tier can start giveaways.',
              sender: 'System',
            );
          }

          final amount = int.tryParse(cmd.args[0]) ?? 0;
          final keyword = cmd.flags['keyword'] ?? '???';
          if (keyword.isEmpty || amount <= 0) {
            return original.copyWith(
              text: '[GIVEAWAY] Invalid giveaway parameters.',
              sender: 'System',
            );
          }
          final duration = int.tryParse(cmd.flags['1-60'] ?? "") ?? 60;

          final endTime = DateTime.now().add(Duration(seconds: duration));
          final giveawayDoc =
              FirebaseFirestore.instance.collection('giveaways').doc();

          await giveawayDoc.set({
            'host': original.sender,
            'amount': amount,
            'keyword': keyword.toLowerCase(),
            'endTimestamp': endTime.millisecondsSinceEpoch,
            'participants': [],
            'status': 'started',
            'winner': null,
          });

          await FirebaseMessaging.instance.subscribeToTopic('global_users');

          return original.copyWith(
            text:
                '[GIVEAWAY] ${original.sender} is giving away $amount \$BUCKAZOIDS\nType "$keyword" to enter. Ends in $duration seconds ⏳',
            sender: 'System',
          );

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
        final displayMessage = await buildCommandPreview(parsed, event.message);
        await homeRepository.sendMessage(displayMessage);
      } else {
        await homeRepository.sendMessage(event.message);

        // Check if message is a giveaway entry
        final now = DateTime.now().millisecondsSinceEpoch;
        final giveaways = await FirebaseFirestore.instance
            .collection('giveaways')
            .where('status', isEqualTo: 'started')
            .where('endTimestamp', isGreaterThan: now)
            .get();

        for (final doc in giveaways.docs) {
          final keyword = doc['keyword']?.toString().toLowerCase() ?? '';
          final text = event.message.text.trim().toLowerCase();
          final sender = event.message.sender;

          if (text == keyword) {
            final participants = List<String>.from(doc['participants'] ?? []);
            if (!participants.contains(sender)) {
              participants.add(sender);
              await doc.reference.update({'participants': participants});
              log('[Giveaway] $sender entered with keyword "$keyword"');
            }
          }
        }
      }
    });
  }

  @override
  Future<void> close() {
    roomSub?.cancel();
    return super.close();
  }
}
