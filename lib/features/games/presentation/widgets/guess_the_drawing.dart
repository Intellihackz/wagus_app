import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wagus/features/games/bloc/game_bloc.dart';
import 'package:wagus/features/games/data/game_repository.dart';
import 'package:wagus/features/games/domain/guess_the_drawing/chat_message_entry.dart';
import 'package:wagus/features/games/domain/guess_the_drawing/guess_entry.dart';
import 'package:wagus/features/games/domain/guess_the_drawing/guess_the_drawing_session.dart';
import 'package:wagus/features/games/game.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/router.dart';

class GuessTheDrawing extends HookWidget {
  const GuessTheDrawing({super.key, required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<GameBloc>().state.guessTheDrawingSession;
    final timerSeconds = useState<int>(60);
    final roundTimer = useState<Timer?>(null);
    final previousRound = useState<int?>(null);

    final strokes = useState<List<Offset?>>([]);
    final socket = useRef<IO.Socket>(IO.io(
      'https://wagus-claim-silnt-a3ca9e3fbf49.herokuapp.com',
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'query': {'wallet': address},
      },
    ));

    useEffect(() {
      final s = socket.value;

      if (!s.connected) {
        s.connect();
      }

      s.emit('join_game', {'wallet': address});

      s.off('connect');
      s.off('guess_result');
      s.off('round_skipped');
      s.off('player_left');
      s.off('connect_error');
      s.off('error');

      s.onConnect((_) async {
        print('✅ Socket connected: $address');
        s.emit('join_game', {'wallet': address});

        final sessionRef = FirebaseFirestore.instance
            .collection('guess_the_drawing_sessions')
            .doc('test-session');

        final doc = await sessionRef.get();
        if (!doc.exists) {
          await sessionRef.set({
            'players': [],
            'lastSeen': {},
            'guesses': [],
            'scores': {},
            'round': 0,
            'word': '',
            'currentDrawerIndex': 0,
            'isComplete': false,
            'drawer': address,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print('✅ test-session initialized');
        }
      });

      s.on('guess_result', (data) {
        final isCorrect = data['correct'] == true;
        final guesser = data['guesser'];
        final message = isCorrect
            ? '$guesser guessed correctly!'
            : '$guesser guessed wrong.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isCorrect ? Colors.green : Colors.red,
          ),
        );
      });

      s.on('round_skipped', (data) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⏳ Time’s up! Moving to next round...'),
            backgroundColor: Colors.redAccent,
          ),
        );
      });

      s.on('player_left', (data) {
        // data is a list of removed wallet addresses
        // use this to update the player list UI in real-time
        print("Players left: $data");
      });

      s.onConnectError((err) => print('❌ Socket connect error: $err'));
      s.onError((err) => print('❌ Socket general error: $err'));

      context
          .read<GameBloc>()
          .add(GameListenGuessDrawingSession('test-session'));
      context.read<GameBloc>().add(GameListenGuessChatMessages('test-session'));

      if (session == null || !session.gameStarted || session.isComplete) {
        return null;
      }

      // If the round has changed, reset the timer
      if (previousRound.value != session.round) {
        strokes.value = [];
        previousRound.value = session.round;
        timerSeconds.value = 60;

        roundTimer.value?.cancel();
        roundTimer.value = Timer.periodic(const Duration(seconds: 1), (_) {
          if (timerSeconds.value > 0) {
            timerSeconds.value--;
          } else {
            // Time's up! Emit a timeout event or handle it as needed
            s.emit('round_timeout', {'wallet': address});
            roundTimer.value?.cancel();
          }
        });
      }

      final pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        s.emit('ping_alive', {'wallet': address});
      });

      final locationSub = locationControler.stream.listen((route) {
        if (!route!.startsWith('/guess-the-drawing')) {
          s.disconnect();
        }
      });

      return () {
        pingTimer.cancel();
        locationSub.cancel();
        s.disconnect();
        s.dispose();
      };
    }, [address, session?.round]);

    return Scaffold(
        floatingActionButton: FloatingActionButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('guess_the_drawing_sessions')
                  .doc('test-session')
                  .update({
                'round': 0,
                'gameStarted': false,
                'isComplete': false,
                'word': '',
                'guesses': [],
                'scores': {},
                'currentDrawerIndex': 0,
                'updatedAt': FieldValue.serverTimestamp(),
                'drawer': FieldValue.delete(), // 🔥 KEY FIX
              });
            },
            child: const Icon(FontAwesomeIcons.hourglassStart)),
        backgroundColor: Colors.black,
        body: BlocBuilder<GameBloc, GameState>(
          builder: (context, state) {
            final session = state.guessTheDrawingSession;

            if (session == null) {
              return Center(
                child: ElevatedButton(
                  onPressed: () async {
                    // Temporary debug start
                    await context.read<GameRepository>().startGuessDrawingGame(
                      sessionId: 'test-session',
                      playerWallets: [
                        address
                      ], // force your own wallet as the player
                    );
                  },
                  child: const Text('Force Start Game'),
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
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          context.read<GameRepository>().startGuessDrawingGame(
                                sessionId: 'test-session',
                                playerWallets: session.players.isEmpty
                                    ? [address]
                                    : session.players,
                              );
                        },
                        child: const Text('Force Start Anyway'),
                      ),
                    ],
                  ),
                );
              } else {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<GameRepository>().startGuessDrawingGame(
                            sessionId: 'test-session',
                            playerWallets: session.players.isEmpty
                                ? [address]
                                : session.players,
                          );
                    },
                    child: const Text('🧪 Start Game'),
                  ),
                );
              }
            }

            // Game can start
            return SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Text(
                    isDrawer ? 'Draw this: ${session.word}' : 'Guess the word!',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
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
                    '⏱ ${timerSeconds.value}s left',
                    style: const TextStyle(
                        color: Colors.orangeAccent, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  _buildScoreboard(session.scores),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.45,
                    child: isDrawer
                        ? _DrawingCanvas(socket: socket.value, strokes: strokes)
                        : _DrawingViewer(
                            socket: socket.value,
                            strokes: strokes,
                            round: session.round,
                          ),
                  ),
                  const Divider(color: Colors.white24),
                  if (!session.isComplete)
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(child: ChatMessageList()),
                          if (!isDrawer)
                            _ChatInput(socket: socket.value)
                          else
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Waiting for guesses...',
                                  style: TextStyle(color: Colors.white38)),
                            ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        'Game Over!\nWinner: ${_getWinner(session.scores)}',
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            );
          },
        ));
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
    return Column(
      children: sorted.map((e) {
        return Text(
          '${e.key.substring(0, 4)}: ${e.value} pts',
          style: const TextStyle(color: Colors.white70),
        );
      }).toList(),
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

      socket.emit('join_game', {
        'wallet': context
            .read<PortalBloc>()
            .state
            .user!
            .embeddedSolanaWallets
            .first
            .address
      });

      void handleStroke(data) {
        print("👀 Viewer received stroke: $data");
        final dx = data['dx'];
        final dy = data['dy'];

        if (dx == null || dy == null) {
          strokes.value = [...strokes.value, null];
        } else {
          final size = MediaQuery.of(context).size;
          final canvasHeight = size.height * 0.45;
          final denormalizedX = dx * size.width;
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
            socket.emit('send_stroke', {'dx': normalizedX, 'dy': normalizedY});
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
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
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
      final guessEntry = GuessEntry(
          wallet: wallet, guess: guessWord, timestamp: DateTime.now());
      await context
          .read<GameRepository>()
          .submitGuessToSession(session.id, guessEntry);
    }

    final chatMessage = ChatMessageEntry(
      wallet: wallet,
      text: guessWord,
      isGuess: isGuess,
      timestamp: DateTime.now(),
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
        final isCorrectGuess = message.isGuess &&
            message.text.toLowerCase() ==
                context
                    .read<GameBloc>()
                    .state
                    .guessTheDrawingSession
                    ?.word
                    .toLowerCase();

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
