import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:wagus/features/bank/data/bank_repository.dart';
import 'package:wagus/features/home/data/home_repository.dart';
import 'package:wagus/features/home/domain/chat_command.dart';
import 'package:wagus/features/home/domain/chat_command_parser.dart';
import 'package:wagus/features/home/domain/help_message.dart';
import 'package:wagus/features/home/domain/message.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/features/rpg/domain/afk_training_service.dart';
import 'package:wagus/features/rpg/domain/skill_registry.dart';
import 'package:wagus/services/privy_service.dart';
import 'package:wagus/services/user_service.dart';

part 'home_event.dart';
part 'home_state.dart';

StreamSubscription? giveawaySub;

const List<String> allCommands = [
  '/send',
  '/burn',
  '/flex',
  '/upgrade',
  '/giveaway',
  '/create',
  '/help',
];

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  StreamSubscription? roomSub;

  final Set<String> announcedGiveawayIds = {};

  bool pendingExpired(Map<String, dynamic> data) {
    final updatedAt =
        (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return DateTime.now().difference(updatedAt).inMinutes > 2;
  }

  final HomeRepository homeRepository;
  final BankRepository bankRepository;
  final AfkTrainingService afkService;
  HomeBloc(
      {required this.homeRepository,
      required this.bankRepository,
      required this.afkService})
      : super(HomeState(messages: [], announcedGiveawayIds: {})) {
    on<HomeListenToGiveawayEvent>((event, emit) async {
      await emit.forEach(
        homeRepository.listenToActiveGiveaways(),
        onData: (snapshot) {
          log('[GiveawayListener] 🔍 Fetched ${snapshot.docs.length} docs');

          for (final change in snapshot.docChanges) {
            log('[GiveawayListener] ${change.type}: ${change.doc.id}');
            log('Data: ${change.doc.data()}');
          }

          for (final doc in snapshot.docs) {
            log('[GiveawayListener] Checking doc: ${doc.id}');

            final data = doc.data() as Map<String, dynamic>;
            final winner = data['winner'] as String?;
            final status = data['status'];
            final hasSent = data['hasSent'] ?? false;
            final alreadyAnnounced = data['announced'] ?? false;

            log('[GiveawayListener] winner: $winner | status: $status | hasSent: $hasSent | announced: $alreadyAnnounced');

            final shouldAnnounce = winner != null &&
                winner.isNotEmpty &&
                status == 'ended' &&
                hasSent == false &&
                alreadyAnnounced == false;

            if (shouldAnnounce && !alreadyAnnounced) {
              log('[GiveawayListener] ✅ Triggering announcement');

              add(HomeLaunchGiveawayConfettiEvent(canLaunchConfetti: true));
            }
          }

          return state;
        },
      );
    });

    FutureOr<Message> buildCommandPreview(ChatCommand cmd, Message original,
        String currentTokenAddress, String ticker, int decimals) async {
      switch (cmd.action.toLowerCase()) {
        case '/send':
          final amount = int.tryParse(cmd.args[0]) ?? 0;
          final recipient = cmd.args.length > 1 ? cmd.args[1] : '';

          if (amount <= 0 || recipient.isEmpty) {
            return original.copyWith(
              text: '[SEND] Invalid usage. Try: /send 100 <wallet>',
              sender: 'System',
              tier: TierStatus.system,
            );
          }

          final user = await PrivyService().initialize();
          final wallet = user?.embeddedSolanaWallets.first;
          final mint = currentTokenAddress;

          if (wallet == null) {
            return original.copyWith(
              text: '[SEND] Error: Wallet not connected.',
              sender: 'System',
              tier: TierStatus.system,
            );
          }

          try {
            await bankRepository.withdrawFunds(
              wallet: wallet,
              amount: amount,
              destinationAddress: recipient,
              wagusMint: mint,
              decimals: decimals,
            );

            return original.copyWith(
              text:
                  '[SEND] ${original.sender} has sent $amount \$$ticker to $recipient 📨',
              sender: 'System',
              tier: TierStatus.system,
            );
          } catch (e) {
            return original.copyWith(
              text: '[SEND] ❌ Failed to send tokens: $e',
              sender: 'System',
              tier: TierStatus.system,
            );
          }

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
              decimals: decimals,
            );

            return original.copyWith(
              text:
                  '[BURN] ${original.sender} just burned $amount \$$ticker 🔥\nSometimes destruction is art.',
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
            'room': original.room,
            'pending': false, // ✅
            'tokenId': ticker.toLowerCase(),
            'announced': false, // ✅ ADD THIS
          });

          await FirebaseMessaging.instance.subscribeToTopic('global_users');

          return original.copyWith(
            text:
                '[GIVEAWAY] 🎁 A giveaway has started in **${original.room}**!\n\nPrize: $amount \$$ticker\nKeyword: "$keyword"\nEnds in $duration seconds ⏳',
            sender: 'System',
            tier: TierStatus.system,
          );

        case '/flex':
          return original.copyWith(
            text:
                '[FLEX] ${original.sender} has ${original.solBalance} SOL and ${original.wagBalance} \$$ticker 💼',
            sender: 'System',
            tier: TierStatus.system,
          );

        case '/help':
          return original.copyWith(
            text: helpOutput,
            sender: 'System',
            tier: TierStatus.system,
          );

        case '/afk':
          final skill = cmd.args.firstOrNull;
          if (skill == null || !SkillRegistry.isValid(skill)) {
            return original.copyWith(
              text: '[AFK] Invalid skill. Try: /afk str',
              sender: 'System',
              tier: TierStatus.system,
            );
          }

          try {
            await afkService.startTraining(original.sender, skill);
            final skillName = SkillRegistry.getById(skill)?.name ?? skill;

            return original.copyWith(
              text:
                  '[AFK] Started training $skillName. Come back later to see your gains 💤',
              sender: 'System',
              tier: TierStatus.system,
            );
          } catch (e) {
            return original.copyWith(
              text: '[AFK] ❌ Failed to start training: $e',
              sender: 'System',
              tier: TierStatus.system,
            );
          }

        default:
          return original.copyWith(
            text: 'Unknown command: ${cmd.action}',
            sender: 'System',
            tier: TierStatus.system,
          );
      }
    }

    on<HomeInitialEvent>((event, emit) {
      emit(state.copyWith(
        messages: event.messages,
        currentRoom: event.room,
        lastDocs: event.lastDocs, // <-- This is what you missed
      ));
    });

    on<HomeListenToRoomsEvent>((event, emit) async {
      await emit.forEach(homeRepository.listenToRooms(), onData: (snapshot) {
        final dynamicRooms = snapshot.docs
            .map((doc) => doc['name']?.toString().trim())
            .whereType<String>()
            .where((name) => name.isNotEmpty)
            .toList();

        final allRooms = [
          'General',
          'Support',
          'Games',
          'Ideas',
          'Tier Lounge',
          ...dynamicRooms.where(
            (name) => !['General', 'Support', 'Games', 'Ideas', 'Tier Lounge']
                .contains(name),
          ),
        ];

        return state.copyWith(rooms: allRooms);
      });
    });

    on<HomeSetRoomEvent>((event, emit) async {
      log('Setting room to ${event.room}');
      roomSub?.cancel(); // Always reset

      emit(state.copyWith(
        messages: [],
        currentRoom: event.room,
      ));

      // 1. 🔒 Initial static fetch
      final snapshot = await homeRepository.getInitialMessages(event.room, 50);
      final initialMessages = snapshot.docs
          .map((doc) {
            final msg = doc.data() as Map<String, dynamic>?;
            if (msg == null) return null;

            final sender = msg['sender'] as String?;
            final text = msg['message'] as String?;
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
              likes: msg['likes'] ?? 0,
              id: doc.id,
              gifUrl: msg['gif_url'],
              replyToMessageId: msg['reply_to_id'],
              replyToText: msg['reply_to_text'],
              username: msg['username'],
              likedBy: List<String>.from(msg['liked_by'] ?? []), // ✅ add this
            );
          })
          .whereType<Message>()
          .toList();

      final updatedLastDocs =
          Map<String, DocumentSnapshot>.from(state.lastDocs);
      if (snapshot.docs.isNotEmpty) {
        updatedLastDocs[event.room] = snapshot.docs.last;
      }

      await Future.delayed(const Duration(milliseconds: 100));

      add(HomeInitialEvent(
        messages: initialMessages,
        room: event.room,
        lastDocs: updatedLastDocs,
      ));

      // 2. ✅ Now subscribe to new changes
      roomSub = homeRepository.getMessages(event.room).listen((data) {
        final messages = data.docs
            .map((doc) {
              final msg = doc.data() as Map<String, dynamic>?;
              if (msg == null) return null;

              final sender = msg['sender'] as String?;
              final text = msg['message'] as String?;
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
                likes: msg['likes'] ?? 0,
                id: doc.id,
                gifUrl: msg['gif_url'],
                replyToMessageId: msg['reply_to_id'],
                replyToText: msg['reply_to_text'],
                username: msg['username'],
                likedBy: List<String>.from(msg['liked_by'] ?? []), // ✅ add this
              );
            })
            .whereType<Message>()
            .toList();

        final updatedLastDocs =
            Map<String, DocumentSnapshot>.from(state.lastDocs);

        if (data.docs.isNotEmpty) {
          updatedLastDocs[event.room] = data.docs.last;
        }

        if (event.room == state.currentRoom) {
          add(HomeInitialEvent(
            messages: messages,
            room: event.room,
            lastDocs: updatedLastDocs,
          ));
        } else {
          // Just update messages and lastDocs silently for background room
          emit(state.copyWith(
            messages: [
              ...state.messages,
              ...messages.where((m) => m.room == state.currentRoom)
            ],
            lastDocs: updatedLastDocs,
          ));
        }
      });
    });

    on<HomeSetReplyMessageEvent>((event, emit) {
      emit(state.copyWith(replyingTo: () => event.message));
    });

    on<HomeLiveUpdateEvent>((event, emit) {
      final newMessages = event.docs
          .map((doc) {
            final msg = doc.data() as Map<String, dynamic>?;
            if (msg == null) return null;

            final sender = msg['sender'] as String?;
            final text = msg['message'] as String?;
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
              likes: msg['likes'] ?? 0,
              id: doc.id,
              gifUrl: msg['gif_url'],
              replyToMessageId: msg['reply_to_id'],
              replyToText: msg['reply_to_text'],
              username: msg['username'],
              likedBy: List<String>.from(msg['liked_by'] ?? []), // ✅ add this
            );
          })
          .whereType<Message>()
          .toList();

      final existingIds = state.messages.map((m) => m.id).toSet();
      final newMessagesDiff =
          newMessages.where((m) => !existingIds.contains(m.id)).toList();

      if (newMessagesDiff.isEmpty) return;

      emit(state.copyWith(
        messages: [...state.messages, ...newMessagesDiff],
      ));

      log('[LiveUpdate] Received ${event.docs.length} docs');
    });

    on<HomeLaunchGiveawayConfettiEvent>((event, emit) {
      emit(state.copyWith(canLaunchConfetti: event.canLaunchConfetti));
    });

    on<HomeWatchOnlineUsersEvent>((event, emit) async {
      await emit.forEach(UserService.onlineUsersCollection, onData: (data) {
        final onlineUsers = data.docs
            .map((doc) => doc.data())
            .where((user) => user['wallet'] != null) // skip nulls
            .map((user) => user['wallet'] as String)
            .toList();

        return state.copyWith(activeUsersCount: onlineUsers.length);
      });
    });

    on<HomeCommandPopupTriggered>((event, emit) {
      final search = event.input.trim();
      final closestMatch = allCommands.firstWhere(
        (cmd) => cmd.startsWith(search),
        orElse: () => '',
      );

      emit(state.copyWith(
        commandSearch: () => closestMatch.isEmpty ? null : closestMatch,
        recentCommand: () => state.recentCommand,
      ));
    });

    on<HomeCommandPopupClosed>((event, emit) {
      emit(state.copyWith(
        commandSearch: () => null,
        recentCommand: () => null, // ✅ make sure this is also cleared
      ));
    });

    on<HomeSendMessageEvent>((event, emit) async {
      log('[BLOC] HomeSendMessageEvent received: ${event.message.text}');

      final parsed = ChatCommandParser.parse(event.message.text);

      final xp = await afkService.claimTrainingXP(event.message.sender);
      if (xp > 0) {
        await homeRepository.sendMessage(
          event.message.copyWith(
            text: '[AFK] You gained $xp XP from your training session! 🏆',
            sender: 'System',
            tier: TierStatus.system,
          ),
        );
      }

      if (parsed != null && event.message.text.trim().startsWith('/')) {
        // Debug log to confirm the state update after sending a message
        log('[BLOC] Sending regular message: ${event.message.text}');

        // Message is a command – transform and send only the preview
        final displayMessage = await buildCommandPreview(parsed, event.message,
            event.currentTokenAddress, event.ticker, event.decimals);
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

          final giveawayRoom = doc['room']?.toString() ?? 'General';
          final messageRoom =
              (event.message.room.isNotEmpty) ? event.message.room : 'General';

          if (text == keyword) {
            if (messageRoom == giveawayRoom) {
              final participants = List<String>.from(doc['participants'] ?? []);
              if (!participants.contains(sender)) {
                participants.add(sender);
                await doc.reference.update({'participants': participants});
                log('[Giveaway] ✅ $sender entered in $messageRoom');
              }
            } else if (event.message.room.isEmpty) {
              // TEMP: legacy support
              final participants = List<String>.from(doc['participants'] ?? []);
              if (!participants.contains(sender)) {
                participants.add(sender);
                await doc.reference.update({'participants': participants});
                log('[Giveaway] ⚠️ Legacy user $sender entered without room data');
              }
            } else {
              log('[Giveaway] ❌ $sender tried to enter from $messageRoom, but giveaway is in $giveawayRoom');
            }
          }
        }
      }
    });

    on<HomeLoadMoreMessagesEvent>((event, emit) async {
      final lastDoc = state.lastDocs[event.room];
      if (lastDoc == null) {
        log('[Pagination] ❌ No lastDoc for room: ${event.room}');
        return;
      }

      log('[Pagination] 🔽 Fetching more messages for room: ${event.room}');
      log('[Pagination] 🧾 Last doc ID: ${lastDoc.id}');

      final more = await homeRepository.getMoreMessages(
        event.room,
        50,
        lastDoc,
      );

      log('[Pagination] 📥 Fetched ${more.docs.length} messages');
      log('[Pagination] Doc IDs: ${more.docs.map((d) => d.id).join(', ')}');

      final existingIds = state.messages.map((m) => m.id).toSet();
      final newMessages = more.docs
          .map((doc) {
            final msg = doc.data();
            return Message(
              id: doc.id,
              text: msg['message'],
              sender: msg['sender'],
              room: msg['room'],
              tier: TierStatus.values.firstWhere(
                (t) => t.name == (msg['tier'] ?? 'basic'),
                orElse: () => TierStatus.basic,
              ),
              likes: msg['likes'] ?? 0,
              gifUrl: msg['gif_url'],
              replyToMessageId: msg['reply_to_id'],
              replyToText: msg['reply_to_text'],
              username: msg['username'],
              likedBy: List<String>.from(msg['liked_by'] ?? []), // ✅ add this
            );
          })
          .where((m) => !existingIds.contains(m.id))
          .toList();

      log('[Pagination] 🧹 Filtered ${newMessages.length} new messages (removed duplicates)');

      if (more.docs.isEmpty) {
        log('[Pagination] 🛑 No more docs to paginate.');
        return;
      }

      final updatedLastDocs = Map<String, DocumentSnapshot>.from(state.lastDocs)
        ..[event.room] = more.docs.last;

      emit(state.copyWith(
        messages: [...state.messages, ...newMessages],
        lastDocs: updatedLastDocs,
      ));
    });
  }

  @override
  Future<void> close() {
    roomSub?.cancel();
    return super.close();
  }
}
