import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wagus/features/games/bloc/game_bloc.dart';
import 'package:wagus/features/games/data/game_repository.dart';
import 'package:wagus/features/games/game.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/router.dart';

class GuessTheDrawing extends HookWidget {
  const GuessTheDrawing({super.key, required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    final socket = useMemoized(() {
      final s = IO.io(
          'https://wagus-claim-silnt-a3ca9e3fbf49.herokuapp.com',
          <String, dynamic>{
            'transports': ['websocket'],
            'autoConnect': false,
            'query': {'wallet': address},
          });

      s.connect();
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

      // s.onConnect((_) async {
      //   print('✅ Socket connected: $address');
      //   s.emit('join_game', {'wallet': address}); // socket only
      // });

      s.on('new_stroke', (data) {
        // update canvas
      });

      s.on('guess_result', (data) {
        // show success/failure
      });

      s.on('player_left', (data) {
        // data is a list of removed wallet addresses
        // use this to update the player list UI in real-time
        print("Players left: $data");
      });

      s.onConnectError((err) => print('❌ Socket connect error: $err'));
      s.onError((err) => print('❌ Socket general error: $err'));

      return s;
    });

    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 30), (_) {
        socket.emit('ping_alive', {'wallet': address});
      });

      context
          .read<GameBloc>()
          .add(GameListenGuessDrawingSession('test-session'));

      final locationSub = locationControler.stream.listen((route) {
        if (!route!.startsWith('/guess-the-drawing')) {
          socket.disconnect();
        }
      });

      return () {
        timer.cancel();
        locationSub.cancel();
        socket.disconnect();
        socket.dispose();
      };
    }, [address]);

    return Scaffold(
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

            if (hasNotStarted) {
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

            final wallet = context
                .read<PortalBloc>()
                .state
                .user!
                .embeddedSolanaWallets
                .first
                .address;

            final isDrawer = session.drawer == wallet;

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
                  Expanded(
                    child: isDrawer
                        ? _DrawingCanvas(socket: socket)
                        : _DrawingViewer(socket: socket),
                  ),
                  const Divider(color: Colors.white24),
                  if (!session.isComplete)
                    isDrawer
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Waiting for guesses...',
                                style: TextStyle(color: Colors.white38)),
                          )
                        : _ChatInput(socket: socket)
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
}

class _DrawingViewer extends HookWidget {
  final IO.Socket socket;
  const _DrawingViewer({required this.socket});

  @override
  Widget build(BuildContext context) {
    final strokes = useState<List<Offset>>([]);

    useEffect(() {
      socket.on('new_stroke', (data) {
        final dx = data['dx'] * 1.0;
        final dy = data['dy'] * 1.0;
        strokes.value = [...strokes.value, Offset(dx, dy)];
      });
      return () => socket.off('new_stroke');
    }, []);

    return CustomPaint(
      painter: _CanvasPainter(strokes.value),
      child: Container(color: Colors.black),
    );
  }
}

class _GameHeader extends StatelessWidget {
  final IO.Socket socket;
  const _GameHeader({required this.socket});

  @override
  Widget build(BuildContext context) {
    // replace this with actual state later
    final isDrawer = true;
    final word = "apple";
    final round = 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _GameHeader(socket: socket),
            const SizedBox(height: 12),
            Expanded(child: _DrawingCanvas(socket: socket)),
            const Divider(color: Colors.white24),
            _ChatInput(socket: socket),
          ],
        ),
      ),
    );
  }
}

class _DrawingCanvas extends HookWidget {
  final IO.Socket socket;
  const _DrawingCanvas({required this.socket});

  @override
  Widget build(BuildContext context) {
    final strokes = useState<List<Offset>>([]);

    useEffect(() {
      socket.on('new_stroke', (data) {
        final dx = data['dx'] * 1.0;
        final dy = data['dy'] * 1.0;
        strokes.value = [...strokes.value, Offset(dx, dy)];
      });
      return () => socket.off('new_stroke');
    }, []);

    return GestureDetector(
      onPanUpdate: (details) {
        final local = (context.findRenderObject() as RenderBox)
            .globalToLocal(details.globalPosition);
        strokes.value = [...strokes.value, local];
        socket.emit('send_stroke', {'dx': local.dx, 'dy': local.dy});
      },
      child: CustomPaint(
        painter: _CanvasPainter(strokes.value),
        child: Container(color: Colors.black),
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<Offset> strokes;
  _CanvasPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (final point in strokes) {
      canvas.drawCircle(point, 2, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class _ChatInput extends HookWidget {
  final IO.Socket socket;
  const _ChatInput({required this.socket});

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your guess...',
                hintStyle: const TextStyle(color: Colors.white38),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
              ),
              onSubmitted: (value) {
                socket.emit('send_guess', {'guess': value});
                controller.clear();
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: () {
              socket.emit('send_guess', {'guess': controller.text});
              controller.clear();
            },
          )
        ],
      ),
    );
  }
}
