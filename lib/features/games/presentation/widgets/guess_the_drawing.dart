import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wagus/features/games/bloc/game_bloc.dart';
import 'package:wagus/features/games/data/game_repository.dart';
import 'package:wagus/features/games/domain/guess_the_drawing/chat_message_entry.dart';
import 'package:wagus/features/games/domain/guess_the_drawing/guess_entry.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/router.dart';
import 'package:wagus/services/socket_service.dart';
import 'package:wagus/theme/app_palette.dart';

class GuessTheDrawing extends HookWidget {
  const GuessTheDrawing(
      {super.key, required this.address, required this.sessionId});

  final String address;
  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<GameBloc>().state.guessTheDrawingSession;
    final timerSeconds = useRef<int>(60); // ⬅️ this holds the value
    final timerUiSeconds = useState<int>(60); // ⬅️ this triggers rebuild

    final roundTimer = useState<Timer?>(null);
    final previousRound = useRef<int?>(null);
    final alreadyHandledRound = useRef<bool>(false);

    final strokes = useState<List<Offset?>>([]);
    final socketService = useRef<SocketService>(SocketService());

    final currentRound = session?.round;
    final hasStartedTimer = useRef<bool>(false);

    void showMessage(String message, Color color) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    }

    useEffect(() {
      print(
          '[TIMER_EFFECT] Round: $currentRound | Prev: ${previousRound.value}');

      // Exit early if invalid session
      if (session == null || !session.gameStarted || session.isComplete) {
        return null;
      }

      // If round is the same, do nothing
      if (previousRound.value == currentRound && hasStartedTimer.value) {
        print('🛑 Already handled this round');
        return null;
      }

      // Handle new round
      print('✅ Handling new round $currentRound');
      previousRound.value = currentRound;
      hasStartedTimer.value = true;

      roundTimer.value?.cancel();
      alreadyHandledRound.value = false;
      strokes.value = [];

      final roundStarted = session.roundStartedAt?.toDate();
      final elapsed = roundStarted != null
          ? DateTime.now().difference(roundStarted).inMilliseconds
          : 0;

      final remaining = (60000 - elapsed).clamp(0, 60000);
      timerSeconds.value = (remaining / 1000).ceil();
      timerUiSeconds.value = timerSeconds.value;
      print('⏱ Initial time: ${timerUiSeconds.value}s');

      roundTimer.value = Timer.periodic(const Duration(seconds: 1), (_) {
        if (timerSeconds.value > 0) {
          timerSeconds.value--;
          timerUiSeconds.value = timerSeconds.value;
          print('⏳ Timer tick: ${timerUiSeconds.value}');
        } else {
          print('⌛ Time expired, emitting round_timeout');
          socketService.value.socket.emit('round_timeout', {
            'wallet': address,
            'sessionId': sessionId,
          });
          roundTimer.value?.cancel();
        }
      });

      return () {
        print('🧹 useEffect cleanup — but only runs on new effect call');
        // Don't cancel here — only cleanup if round actually changes next render
      };
    }, [currentRound]);

    useEffect(() {
      socketService.value.init(
          wallet: address,
          sessionId: sessionId,
          context: context,
          onMessage: showMessage,
          onReject: () {
            if (context.canPop()) {
              context.pop();
            }
          },
          locationStream: locationControler.stream);

      // if (!s.connected) {
      //   s.connect();
      // }

      // s.emit('join_game', {'wallet': address, 'sessionId': sessionId});

      // s.off('connect');
      // s.off('guess_result');
      // s.off('round_skipped');
      // s.off('player_left');
      // s.off('connect_error');
      // s.off('error');

      // s.onConnect((_) async {
      //   print('✅ Socket connected: $address');
      //   final sessionRef = FirebaseFirestore.instance
      //       .collection('guess_the_drawing_sessions')
      //       .doc(sessionId);
      //   final doc = await sessionRef.get();

      //   if (doc.exists) {
      //     s.emit('join_game', {'wallet': address, 'sessionId': sessionId});
      //   } else {
      //     print('⚠️ Session doc not found client-side, delaying join_game...');
      //     await Future.delayed(const Duration(milliseconds: 500));
      //     final retry = await sessionRef.get();
      //     if (retry.exists) {
      //       s.emit('join_game', {'wallet': address, 'sessionId': sessionId});
      //     } else {
      //       print("❌ Session doc still missing after retry");
      //     }
      //   }
      // });

      // s.on('guess_result', (data) {
      //   alreadyHandledRound.value = true;
      //   final isCorrect = data['correct'] == true;
      //   final guesser = data['guesser'];
      //   final message = isCorrect
      //       ? '$guesser guessed correctly!'
      //       : '$guesser guessed wrong.';

      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text(message),
      //       backgroundColor: isCorrect ? Colors.green : Colors.red,
      //     ),
      //   );
      // });

      // s.on('round_skipped', (data) {
      //   if (alreadyHandledRound.value) return;
      //   if (data['reason'] == 'correct')
      //     return; // ✅ ignore if it’s due to correct
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('⏳ Time’s up! Moving to next round...'),
      //       backgroundColor: Colors.redAccent,
      //     ),
      //   );
      // });

      // s.on('player_left', (data) {
      //   // data is a list of removed wallet addresses
      //   // use this to update the player list UI in real-time
      //   print("Players left: $data");
      // });

      // s.on('join_rejected', (data) {
      //   final reason = data['reason'] ?? 'Join rejected';
      //   WidgetsBinding.instance.addPostFrameCallback((_) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(content: Text(reason), backgroundColor: Colors.red),
      //     );
      //   });
      //   s.disconnect();

      //   if (context.canPop()) {
      //     context.pop();
      //   }
      // });

      // // ✅ UPDATED CLIENT PATCH

      // s.on('round_advanced', (data) {
      //   alreadyHandledRound.value = false; // ✅ always reset to allow next round

      //   final reason = data['reason'];
      //   final sessionRef = FirebaseFirestore.instance
      //       .collection('guess_the_drawing_sessions')
      //       .doc(sessionId);

      //   sessionRef.get().then((doc) {
      //     if (!doc.exists) return;

      //     final data = doc.data();
      //     final newDrawer = data?['drawer'] ?? '';
      //     final roundNum = data?['round'];

      //     final isMe = newDrawer == address;
      //     final message = reason == 'correct_guess'
      //         ? '✅ Correct guess! Round $roundNum, ${isMe ? 'you draw' : 'guess'}'
      //         : reason == 'timeout'
      //             ? '⏳ Time’s up! Round $roundNum, ${isMe ? 'you draw' : 'guess'}'
      //             : reason == 'forfeit'
      //                 ? '🏆 ${data?['remainingPlayer'] ?? 'someone'} wins by default'
      //                 : null;

      //     if (message != null) {
      //       ScaffoldMessenger.of(context).showSnackBar(
      //         SnackBar(
      //           content: Text(message),
      //           backgroundColor: reason == 'forfeit'
      //               ? Colors.orange
      //               : reason == 'correct_guess'
      //                   ? Colors.green
      //                   : Colors.redAccent,
      //         ),
      //       );
      //     }
      //   });
      // });

      // s.onConnectError((err) => print('❌ Socket connect error: $err'));
      // s.onError((err) => print('❌ Socket general error: $err'));

      // context.read<GameBloc>().add(GameListenGuessDrawingSession(sessionId));
      // context.read<GameBloc>().add(GameListenGuessChatMessages(sessionId));

      // final pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      //   s.emit('ping_alive',
      //       {'wallet': address, 'sessionId': sessionId}); // ✅ ADD sessionId
      // });

      // final locationSub = locationControler.stream.listen((route) {
      //   if (!route!.startsWith('/guess-the-drawing')) {
      //     s.disconnect();
      //   }
      // });

      return () {
        // pingTimer.cancel();
        // locationSub.cancel();

        // only disconnect if the session is complete or null
        final currentSession =
            context.read<GameBloc>().state.guessTheDrawingSession;
        final isSafeToDisconnect =
            currentSession == null || currentSession.isComplete;

        if (isSafeToDisconnect) {
          // s.disconnect();
          // s.dispose();
        } else {
          print('⚠️ Skipping socket disconnect to preserve connection');
        }
      };
    }, [address]);

    return Scaffold(
        appBar: AppBar(
          title: const Text('Guess the Drawing'),
          centerTitle: true,
          backgroundColor: Colors.white,
          actions: [
            // info icon to show game rules. show dialog explaining the game
            IconButton(
              icon: const Icon(FontAwesomeIcons.info, color: Colors.black),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Game Rules',
                          style: TextStyle(
                            color: context.appColors.contrastDark,
                          )),
                      content: Text(
                        'Guess the Drawing is a multiplayer game where one player draws a word and others try to guess it. '
                        'The drawer has 60 seconds to draw while others can submit guesses using the input box. '
                        'Correct guesses earn points, and the player with the most points at the end wins.',
                        style: TextStyle(
                          color: context.appColors.contrastDark,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => context.pop(),
                          child: const Text('Got it!'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
        backgroundColor: Colors.black,
        body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('guess_the_drawing_sessions')
                .orderBy('updatedAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              return BlocBuilder<GameBloc, GameState>(
                builder: (context, state) {
                  final session = state.guessTheDrawingSession;

                  if (session == null) {
                    return const Center(
                      child: Text(
                        'No active session found',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final hasNotStarted = !session.gameStarted;
                  final hasEnoughPlayers = session.players.length >= 3;

                  final wallet = context
                      .read<PortalBloc>()
                      .state
                      .user!
                      .embeddedSolanaWallets
                      .first
                      .address;

                  final isDrawer = session.drawer == wallet;

                  if (hasNotStarted) {
                    if (!hasEnoughPlayers) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${session.players.length} joined • Not enough players yet',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                context
                                    .read<GameRepository>()
                                    .startGuessDrawingGame(
                                        sessionId: sessionId,
                                        playerWallets: session.players);
                              },
                              child: const Text('Start Game'),
                            ),
                          ],
                        ),
                      );
                    }
                  }

                  if (session.isComplete) {
                    return SizedBox.expand(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            'Game Over!\nWinner: ${_getWinner(session.scores)}',
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }

                  // Game can start
                  return SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final totalHeight = constraints.maxHeight;
                        final keyboardHeight =
                            MediaQuery.of(context).viewInsets.bottom;

                        final drawingHeight = totalHeight * 0.35;

                        return Column(
                          children: [
                            const SizedBox(height: 12),
                            Text(
                              isDrawer
                                  ? 'Draw this: ${session.word}'
                                  : 'Guess the word!',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 18),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              session.drawer.isNotEmpty
                                  ? 'Round ${session.round} • Drawer: ${session.drawer.substring(0, 6)}...'
                                  : 'Round ${session.round} • Waiting for drawer...',
                              style: const TextStyle(color: Colors.white60),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '⏱ ${timerUiSeconds.value}s left',
                              style: const TextStyle(
                                  color: Colors.orangeAccent, fontSize: 16),
                            ),

                            const SizedBox(height: 12),
                            _buildScoreboard(session.scores),
                            const SizedBox(height: 8),

                            // Drawing canvas
                            SizedBox(
                              height: drawingHeight,
                              child: isDrawer
                                  ? _DrawingCanvas(
                                      socket: socketService.value.socket,
                                      strokes: strokes)
                                  : _DrawingViewer(
                                      socket: socketService.value.socket,
                                      strokes: strokes,
                                      round: session.round,
                                    ),
                            ),
                            const Divider(color: Colors.white24),

                            // Chat area
                            Expanded(
                              child: Column(
                                children: [
                                  const Expanded(child: ChatMessageList()),
                                  if (!isDrawer)
                                    _ChatInput(
                                        socket: socketService.value.socket)
                                  else
                                    const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text('Waiting for guesses...',
                                          style:
                                              TextStyle(color: Colors.white38)),
                                    ),
                                  // Padding for keyboard so input doesn't get covered
                                  SizedBox(
                                      height: keyboardHeight > 0
                                          ? keyboardHeight
                                          : 0),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              );
            }));
  }

  String _getWinner(Map<String, int> scores) {
    if (scores.isEmpty) return 'Nobody';
    return scores.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key
        .substring(0, 6);
  }

  Widget _buildScoreboard(Map<String, int> scores) {
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Wrap(
      children: List.generate(sorted.length, (index) {
        return Container(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              Text(
                '${sorted[index].key.substring(0, 4)}: ${sorted[index].value} pts',
                style: const TextStyle(color: Colors.white70),
              ),
              if (index < sorted.length - 1) const Divider(),
            ],
          ),
        );
      }),
    );
  }
}

class _DrawingViewer extends HookWidget {
  final IO.Socket socket;
  final ValueNotifier<List<Offset?>> strokes;
  final int round;

  const _DrawingViewer(
      {required this.socket, required this.strokes, required this.round});

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      print("📡 Viewer is setting up listener for round: $round");

      // socket.emit('join_game', {
      //   'wallet': context
      //       .read<PortalBloc>()
      //       .state
      //       .user!
      //       .embeddedSolanaWallets
      //       .first
      //       .address
      // });

      void handleStroke(data) {
        print("👀 Viewer received stroke: $data");
        final dx = data['dx'];
        final dy = data['dy'];

        if (dx == null || dy == null) {
          strokes.value = [...strokes.value, null];
        } else {
          final size = MediaQuery.of(context).size;
          final canvasHeight = data['canvasHeight'] ?? size.height * 0.35;
          final canvasWidth = data['canvasWidth'] ?? size.width;
          final denormalizedX = dx * canvasWidth;
          final denormalizedY = dy * canvasHeight;

          strokes.value = [
            ...strokes.value,
            Offset(denormalizedX, denormalizedY)
          ];
        }
      }

      socket.off('new_stroke');
      socket.on('new_stroke', handleStroke);

      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   strokes.value = [];
      // });

      return () {
        print("🧹 Cleaning up listener for round: $round");
        socket.off('new_stroke', handleStroke);
      };
    }, [round]);

    return ValueListenableBuilder<List<Offset?>>(
      valueListenable: strokes,
      builder: (_, value, __) {
        return CustomPaint(
          painter: _CanvasPainter(value),
          child: Container(color: Colors.transparent),
        );
      },
    );
  }
}

class _DrawingCanvas extends HookWidget {
  final IO.Socket socket;
  final ValueNotifier<List<Offset?>> strokes;
  const _DrawingCanvas({required this.socket, required this.strokes});

  @override
  Widget build(BuildContext context) {
    final throttle = useRef<Timer?>(null); // ✅ persistent reference

    return GestureDetector(
        onPanStart: (_) {
          strokes.value = [...strokes.value, null]; // null separates new stroke
          socket.emit(
              'send_stroke', {'dx': null, 'dy': null}); // signal new stroke
        },
        onPanUpdate: (details) {
          final box = context.findRenderObject() as RenderBox;
          final local = box.globalToLocal(details.globalPosition);

// Clamp within canvas height
          final clampedDy = local.dy.clamp(0.0, box.size.height);
          final clampedDx = local.dx.clamp(0.0, box.size.width);
          final clampedOffset = Offset(clampedDx, clampedDy);

          strokes.value = [...strokes.value, clampedOffset];

          if (throttle.value?.isActive ?? false) return;

          final normalizedX = clampedDx / box.size.width;
          final normalizedY = clampedDy / box.size.height;

          throttle.value = Timer(const Duration(milliseconds: 16), () {
            print("Drawer stroke emitted: $normalizedX, $normalizedY");
            socket.emit('send_stroke', {
              'dx': normalizedX,
              'dy': normalizedY,
              'canvasHeight': box.size.height,
              'canvasWidth': box.size.width,
            });
          });
        },
        child: ValueListenableBuilder<List<Offset?>>(
          valueListenable: strokes,
          builder: (_, value, __) {
            return CustomPaint(
              painter: _CanvasPainter(value),
              child: Container(color: Colors.transparent),
            );
          },
        ));
  }
}

class _CanvasPainter extends CustomPainter {
  final List<Offset?> strokes;
  _CanvasPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < strokes.length - 1; i++) {
      final p1 = strokes[i];
      final p2 = strokes[i + 1];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) {
    return true; // always repaint
  }
}

class _ChatInput extends HookWidget {
  final IO.Socket socket;
  const _ChatInput({required this.socket});

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final session = context.read<GameBloc>().state.guessTheDrawingSession!;
    final wallet = context
        .read<PortalBloc>()
        .state
        .user!
        .embeddedSolanaWallets
        .first
        .address;
    final isDrawer = session.drawer == wallet;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText:
                    isDrawer ? 'You are drawing...' : 'Type /guess <word>',
                hintStyle: const TextStyle(color: Colors.white38),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: context.appColors.contrastLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: context.appColors.contrastLight),
                ),
              ),
              enabled: !isDrawer,
              onSubmitted: (value) => _handleGuess(context, value, controller),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: isDrawer
                ? null
                : () => _handleGuess(context, controller.text, controller),
          )
        ],
      ),
    );
  }

  void _handleGuess(BuildContext context, String input,
      TextEditingController controller) async {
    input = input.trim();
    final session = context.read<GameBloc>().state.guessTheDrawingSession!;
    final wallet = context
        .read<PortalBloc>()
        .state
        .user!
        .embeddedSolanaWallets
        .first
        .address;

    final isGuess = input.toLowerCase().startsWith('/guess ');
    final guessWord = isGuess ? input.substring(7).trim() : input;

    if (guessWord.isEmpty) {
      controller.clear();
      return;
    }

    if (isGuess) {
      final timestamp = DateTime.now();
      final isCorrect = guessWord.toLowerCase() == session.word.toLowerCase();

      final guessEntry = GuessEntry(
        wallet: wallet,
        guess: guessWord,
        timestamp: timestamp,
        isCorrect: isCorrect,
      );

      await context
          .read<GameRepository>()
          .submitGuessToSession(session.id, guessEntry, socket);

      if (isCorrect) {
        socket.emit('correct_guess', {
          'wallet': wallet,
          'sessionId': session.id, // ✅ pass sessionId here
        });
      }
    }

    final chatMessage = ChatMessageEntry(
      wallet: wallet,
      text: guessWord,
      isGuess: isGuess,
      timestamp: DateTime.now(),
      isCorrect:
          isGuess && guessWord.toLowerCase() == session.word.toLowerCase(),
    );

    await context.read<GameRepository>().sendChatMessage(
          sessionId: session.id,
          message: chatMessage,
        );

    controller.clear();
  }
}

class ChatMessageList extends HookWidget {
  const ChatMessageList({super.key});

  @override
  Widget build(BuildContext context) {
    final messages = context.watch<GameBloc>().state.chatMessages;
    if (messages == null) return const SizedBox(height: 150);

    if (messages.isEmpty) return const SizedBox(height: 150);

    final scrollController = useScrollController();

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.jumpTo(0.0); // scroll to bottom (0.0 if reversed)
        }
      });
      return null;
    }, [messages.length]);

    return ListView.builder(
      itemCount: messages.length,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemBuilder: (context, index) {
        final message = messages[index];
        final isCorrectGuess = message.isGuess && message.isCorrect;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            '${message.wallet.substring(0, 4)}: ${message.text}',
            style: TextStyle(
              color: isCorrectGuess
                  ? Colors.greenAccent
                  : message.isGuess
                      ? Colors.amber
                      : Colors.white70,
              fontWeight: isCorrectGuess ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      },
    );
  }
}
