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
import 'package:wagus/services/user_service.dart';
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
    final alreadyHandledRound = useState<bool>(false);

    final strokes = useState<List<Offset?>>([]);
    final socketService = useRef<SocketService>(SocketService());

    final currentRound = session?.round;
    final hasStartedTimer = useRef<bool>(false);

    final isDrawing = useState(false);

    void showMessage(String message, Color color) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    }

    final previousTurnKey = useRef<String?>(null);
    final currentTurnKey = '${session?.round}_${session?.drawer}';

    useEffect(() {
      // Exit early if invalid session
      if (session == null || !session.gameStarted || session.isComplete) {
        return null;
      }
      print(
          '[TIMER_EFFECT] Round: $currentRound | Prev: ${previousRound.value}');

      strokes.value = []; // Reset strokes for new round

      // If round is the same, do nothing
      if (previousTurnKey.value == currentTurnKey && hasStartedTimer.value) {
        print('🛑 Already handled this turn');
        return null;
      }

      // Handle new round
      print('✅ Handling new round $currentRound');

      print('✅ Handling new turn $currentTurnKey');
      previousTurnKey.value = currentTurnKey;
      hasStartedTimer.value = true;

      roundTimer.value?.cancel();
      alreadyHandledRound.value = false;

      strokes.value = []; // Reset strokes for new turn

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
    }, [currentTurnKey]);

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
          locationStream: locationControler.stream,
          alreadyHandledRound: alreadyHandledRound);

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
                    final winnerKey = _getWinner(session.scores);
                    final winnerScore = session.scores[winnerKey] ?? 0;

                    return FutureBuilder<String>(
                      future: UserService().getDisplayName(winnerKey),
                      builder: (context, snapshot) {
                        final winnerName = snapshot.data ?? winnerKey;

                        return SizedBox.expand(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.center,
                            color: Colors.black,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.emoji_events,
                                    size: 64, color: Colors.amber),
                                const SizedBox(height: 16),
                                const Text(
                                  '🏆 Winner!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  winnerName,
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$winnerScore Points',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () => context.pop(),
                                  child: const Text('Back to Home'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }

                  // Game can start
                  return SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                              Expanded(
                                child: isDrawer
                                    ? _DrawingCanvas(
                                        socket: socketService.value.socket,
                                        strokes: strokes,
                                        isDrawing: isDrawing,
                                      )
                                    : _DrawingViewer(
                                        socket: socketService.value.socket,
                                        strokes: strokes,
                                        round: session.round,
                                        isDrawing: isDrawing,
                                      ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.white24),
                        Expanded(
                          flex: 1,
                          child: ChatMessageList(isDrawing: isDrawing),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: !isDrawer
                              ? _ChatInput(socket: socketService.value.socket)
                              : const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Waiting for guesses...',
                                    style: TextStyle(color: Colors.white38),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }));
  }

  String _getWinner(Map<String, int> scores) {
    if (scores.isEmpty) return 'Nobody';
    return scores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  Widget _buildScoreboard(Map<String, int> scores) {
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SizedBox(
      height: 60,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(sorted.length, (index) {
            final walletShort = sorted[index].key.substring(0, 4);
            final score = sorted[index].value;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white30),
              ),
              child: Text(
                '$walletShort: $score pts',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _DrawingViewer extends HookWidget {
  final IO.Socket socket;
  final ValueNotifier<List<Offset?>> strokes;
  final int round;
  final ValueNotifier<bool> isDrawing;

  const _DrawingViewer(
      {required this.socket,
      required this.strokes,
      required this.round,
      required this.isDrawing});

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      print("📡 Viewer is setting up listener for round: $round");

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
  final ValueNotifier<bool> isDrawing;
  const _DrawingCanvas(
      {required this.socket, required this.strokes, required this.isDrawing});

  @override
  Widget build(BuildContext context) {
    final throttle = useRef<Timer?>(null); // ✅ persistent reference

    return GestureDetector(
        onPanStart: (_) {
          isDrawing.value = true;
          strokes.value = [...strokes.value, null]; // null separates new stroke
          socket.emit(
              'send_stroke', {'dx': null, 'dy': null}); // signal new stroke
        },
        onPanUpdate: (details) {
          isDrawing.value = false;
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
  final ValueNotifier<bool> isDrawing;
  const ChatMessageList({super.key, required this.isDrawing});

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
      physics: isDrawing.value ? const NeverScrollableScrollPhysics() : null,
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
