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
import 'package:wagus/services/privy_service.dart';
import 'package:wagus/services/user_service.dart';

part 'home_event.dart';
part 'home_state.dart';

StreamSubscription? giveawaySub;

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  StreamSubscription? roomSub;

  final Set<String> announcedGiveawayIds = {};

  Future<void> watchGiveaways(
    String currentUserWallet,
    EmbeddedSolanaWallet wallet,
    String mint,
    BankRepository bank,
  ) async {
    giveawaySub?.cancel();

    giveawaySub = homeRepository
        .listenToActiveGiveaways(currentUserWallet)
        .listen((snapshot) async {
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final id = doc.id;

        final winner = data['winner'] as String?;
        final status = data['status'];
        final amount = data['amount'] ?? 0;
        final isPending = data['pending'] ?? false;
        final hasSent = data['hasSent'] ?? false;
        final error = data['error'];
        final updatedAt =
            (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final isStale = DateTime.now().difference(updatedAt).inMinutes > 2;

        // ✅ Skip if not ended or winner missing
        if (winner == null ||
            winner.isEmpty ||
            winner == 'No winner' ||
            status != 'ended') continue;

        // ✅ Only host can send
        if (currentUserWallet != data['host']) continue;

        // ✅ Already sent or already processed this in memory
        if (hasSent || announcedGiveawayIds.contains(id)) continue;

        // ✅ Skip if previously errored and not marked pending (unless stale)
        final shouldRetryErrored = error != null && !isPending && isStale;
        if (error != null && !shouldRetryErrored) continue;

        log('🧪 Evaluating giveaway $id');

        bool markedPending = false;

        try {
          // 🚧 Transactional lock
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            final freshDoc = await transaction.get(doc.reference);
            final freshData = freshDoc.data() as Map<String, dynamic>;

            final alreadySent = freshData['hasSent'] ?? false;
            final isPending = freshData['pending'] ?? false;
            final updatedAt =
                (freshData['updatedAt'] as Timestamp?)?.toDate() ??
                    DateTime.now();
            final isStale = DateTime.now().difference(updatedAt).inMinutes > 2;

            if (!alreadySent && (!isPending || isStale)) {
              transaction.update(doc.reference, {
                'pending': true,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              markedPending = true;
              announcedGiveawayIds.add(id);
              log('✅ Marked $id as pending');
            } else {
              log('⛔️ Skipped $id: already sent or in progress');
            }
          });

          if (!markedPending) continue;

          // ✅ Send tokens
          await bank.withdrawFunds(
            wallet: wallet,
            destinationAddress: winner,
            amount: amount,
            wagusMint: mint,
          );

          // ✅ Mark as sent
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            transaction.update(doc.reference, {
              'hasSent': true,
              'pending': false,
              'status': 'completed',
              'updatedAt': FieldValue.serverTimestamp(),
              'error': FieldValue.delete(),
            });
          });

          log('🎉 Giveaway $id paid out to $winner');

          // ✅ Broadcast system message
          add(HomeSendMessageEvent(
            message: Message(
              text:
                  '[GIVEAWAY] 🎉 $amount \$BUCKAZOIDS was rewarded! Winner: ${winner.substring(0, 4)}...${winner.substring(winner.length - 4)}',
              sender: 'System',
              tier: TierStatus.system,
              room: 'General',
            ),
            currentTokenAddress: mint,
          ));
        } catch (e) {
          log('❌ Failed to process giveaway $id: $e');

          // 🚨 Reset state for retry or manual fix
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            transaction.update(doc.reference, {
              'pending': false,
              'hasSent': false,
              'error': e.toString(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          });
        }
      }
    });
  }

  bool pendingExpired(Map<String, dynamic> data) {
    final updatedAt =
        (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return DateTime.now().difference(updatedAt).inMinutes > 2;
  }

  final HomeRepository homeRepository;
  final BankRepository bankRepository;
  HomeBloc({required this.homeRepository, required this.bankRepository})
      : super(HomeState(messages: [])) {
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
              .map((msg) {
                final sender = msg['sender'] as String?;
                final text = msg['message'] as String?; // 👈 fix here
                if (sender == null || text == null) return null;

                return Message(
                  text: text,
                  sender: sender,
                  room: (msg['room'] as String?)?.trim().isNotEmpty == true
                      ? msg['room']
                      : 'General',
                  tier: TierStatus.values.firstWhere(
                    (t) => t.name == (msg['tier'] ?? 'basic'),
                    orElse: () => TierStatus.basic,
                  ),
                );
              })
              .whereType<Message>()
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

    on<HomeWatchOnlineUsersEvent>((event, emit) async {
      await emit.forEach(UserService.onlineUsersCollection, onData: (data) {
        final onlineUsers = data.docs
            .map((doc) => doc.data())
            .toList()
            .cast<Map<String, dynamic>>()
            .map((user) => user['wallet'] as String)
            .toList();

        return state.copyWith(activeUsersCount: onlineUsers.length);
      });
    });

    FutureOr<Message> buildCommandPreview(
        ChatCommand cmd, Message original, String currentTokenAddress) async {
      switch (cmd.action.toLowerCase()) {
        case '/send':
          final amount = cmd.args.isNotEmpty ? cmd.args[0] : '?';
          final target = cmd.args.length > 1 ? cmd.args[1] : 'unknown';
          return original.copyWith(
            text:
                '[SEND] ${original.sender} has sent $amount \$WAGUS to $target 📨',
            sender: 'System',
            tier: TierStatus.system,
          );

        case '/burn':
          final amount = int.tryParse(cmd.args.firstOrNull ?? '') ?? 0;

          if (amount <= 0) {
            return original.copyWith(
              text: '[BURN] Invalid amount. Usage: /burn 100',
              sender: 'System',
              tier: TierStatus.system,
            );
          }

          final user =
              await PrivyService().initialize(); // ✅ your singleton service

          final wallet = user?.embeddedSolanaWallets.first;
          final mint = currentTokenAddress;

          if (wallet == null) {
            return original.copyWith(
              text: '[BURN] Error: Wallet or mint address not found.',
              sender: 'System',
              tier: TierStatus.system,
            );
          }

          try {
            // Burn = send to black hole
            const blackHoleAddress = '11111111111111111111111111111111';
            await bankRepository.withdrawFunds(
              wallet: wallet,
              amount: amount,
              destinationAddress: blackHoleAddress,
              wagusMint: mint,
            );

            return original.copyWith(
              text:
                  '[BURN] ${original.sender} just burned $amount \$BUCKAZOIDS 🔥\nSometimes destruction is art.',
              sender: 'System',
              tier: TierStatus.system,
            );
          } catch (e) {
            return original.copyWith(
              text: '[BURN] Failed to burn tokens: $e',
              sender: 'System',
              tier: TierStatus.system,
            );
          }

        case '/giveaway':
          if (original.tier != TierStatus.adventurer) {
            return original.copyWith(
              text: '[GIVEAWAY] Only Adventurer tier can start giveaways.',
              sender: 'System',
              tier: TierStatus.system,
            );
          }

          final amount = int.tryParse(cmd.args[0]) ?? 0;
          final keyword = cmd.flags['keyword'] ?? '???';
          if (keyword.isEmpty || amount <= 0) {
            return original.copyWith(
              text: '[GIVEAWAY] Invalid giveaway parameters.',
              sender: 'System',
              tier: TierStatus.system,
            );
          }
          final duration =
              int.tryParse(cmd.flags['duration'] ?? cmd.flags['1-60'] ?? '') ??
                  60;

          final now = DateTime.now();
          final endTime = now.add(Duration(seconds: duration));

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
            'hasSent': false,
            'pending': false, // ✅
          });

          await FirebaseMessaging.instance.subscribeToTopic('global_users');

          return original.copyWith(
            text:
                '[GIVEAWAY] ${original.sender} is giving away $amount \$BUCKAZOIDS\nType "$keyword" to enter. Ends in $duration seconds ⏳',
            sender: 'System',
            tier: TierStatus.system,
          );

        case '/flex':
          return original.copyWith(
            text:
                '[FLEX] ${original.sender} has ${original.solBalance} SOL and ${original.wagBalance} \$WAGUS 💼',
            sender: 'System',
            tier: TierStatus.system,
          );

        default:
          return original.copyWith(
            text: 'Unknown command: ${cmd.action}',
            sender: 'System',
            tier: TierStatus.system,
          );
      }
    }

    on<HomeSendMessageEvent>((event, emit) async {
      log('[BLOC] HomeSendMessageEvent received: ${event.message.text}');

      final parsed = ChatCommandParser.parse(event.message.text);

      if (parsed != null && event.message.text.trim().startsWith('/')) {
        // Message is a command – transform and send only the preview
        final displayMessage = await buildCommandPreview(
            parsed, event.message, event.currentTokenAddress);
        await homeRepository.sendMessage(displayMessage);
        return;
      }

      // Regular or system message – send as-is
      await homeRepository.sendMessage(event.message);

      // Giveaway keyword detection logic (only for user messages)
      if (event.message.tier != TierStatus.system) {
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
