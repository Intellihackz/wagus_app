import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wagus/features/games/bloc/game_bloc.dart';

typedef MessageHandler = void Function(String message, Color color);

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  late IO.Socket _socket;
  Timer? _pingTimer;
  StreamSubscription? _locationSub;

  late String _wallet;
  late String _sessionId;
  late BuildContext _context;
  late MessageHandler _onMessage;
  late VoidCallback _onReject;

  SocketService._internal();

  bool _initialized = false;

  DateTime? _lastMessageTime;

  void _safeMessage(String msg, Color color) {
    final now = DateTime.now();
    if (_lastMessageTime == null ||
        now.difference(_lastMessageTime!) > const Duration(seconds: 2)) {
      _lastMessageTime = now;
      _onMessage(msg, color); // ✅ correct call
    }
  }

  void init({
    required String wallet,
    required String sessionId,
    required BuildContext context,
    required MessageHandler onMessage,
    required VoidCallback onReject,
    required Stream<String?> locationStream,
    required ValueNotifier<bool> alreadyHandledRound,
  }) {
    if (_initialized && (_wallet == wallet && _sessionId == sessionId)) {
      if (!_socket.connected) _socket.connect(); // <- Reconnect if needed
      return;
    }

    _initialized = true;

    _wallet = wallet;
    _sessionId = sessionId;
    _context = context;
    _onMessage = onMessage;
    _onReject = onReject;

    _socket = IO.io(
      'https://wagus-claim-silnt-a3ca9e3fbf49.herokuapp.com',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setQuery({'wallet': _wallet, 'sessionId': _sessionId})
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket.connect();

    _socket.offAny();

    _socket.onConnect((_) async {
      context.read<GameBloc>().add(GameListenGuessDrawingSession(_sessionId));
      context.read<GameBloc>().add(GameListenGuessChatMessages(_sessionId));

      final doc = await FirebaseFirestore.instance
          .collection('guess_the_drawing_sessions')
          .doc(_sessionId)
          .get();

      if (doc.exists) {
        _socket.emit('join_game', {'wallet': _wallet, 'sessionId': _sessionId});
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        final retry = await FirebaseFirestore.instance
            .collection('guess_the_drawing_sessions')
            .doc(_sessionId)
            .get();
        if (retry.exists) {
          _socket
              .emit('join_game', {'wallet': _wallet, 'sessionId': _sessionId});
        } else {
          _safeMessage("❌ Session doc still missing", Colors.red);
        }
      }
    });

    _socket.on('reconnect', (_) {
      _socket.emit('join_game', {
        'wallet': _wallet,
        'sessionId': _sessionId,
      });

      // Trigger re-fetch immediately
      _context.read<GameBloc>().add(GameListenGuessDrawingSession(_sessionId));
    });

    _socket.on('guess_result', (data) {
      alreadyHandledRound.value = true;
      final isCorrect = data['correct'] == true;
      final guesser = data['guesser'];
      _safeMessage(
        isCorrect ? '$guesser guessed correctly!' : '$guesser guessed wrong.',
        isCorrect ? Colors.green : Colors.red,
      );
    });

    _socket.on('round_skipped', (data) {
      if (data['reason'] == 'correct') return;
      _safeMessage('⏳ Time’s up! Moving to next round...', Colors.redAccent);
    });

    _socket.on('join_rejected', (data) {
      final reason = data['reason'] ?? 'Join rejected';
      _safeMessage(reason, Colors.red);
      _onReject();
      _socket.disconnect();
    });

    _socket.on('round_advanced', (payload) async {
      context.read<GameBloc>().add(GameListenGuessDrawingSession(sessionId));

      final doc = await FirebaseFirestore.instance
          .collection('guess_the_drawing_sessions')
          .doc(_sessionId)
          .get();
      if (!doc.exists) return;
      final data = doc.data();
      final newDrawer = data?['drawer'] ?? '';
      final roundNum = data?['round'];
      final isMe = newDrawer == _wallet;

      final reason = payload?['reason']; // <- use the socket payload instead

      String? msg;
      if (reason == 'correct_guess') {
        msg =
            '✅ Correct guess! Round $roundNum, ${isMe ? 'you draw' : 'guess'}';
      } else if (reason == 'timeout') {
        msg = '⏳ Time’s up! Round $roundNum, ${isMe ? 'you draw' : 'guess'}';
      } else if (reason == 'forfeit') {
        msg = '🏆 ${payload?['remainingPlayer'] ?? 'someone'} wins by default';
      }

      if (msg != null) {
        _safeMessage(
            msg,
            reason == 'forfeit'
                ? Colors.orange
                : reason == 'correct_guess'
                    ? Colors.green
                    : Colors.redAccent);
      }
    });

    _socket.onConnectError((e) => print('❌ connect error: $e'));
    _socket.onError((e) => print('❌ error: $e'));

    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _socket.emit('ping_alive', {'wallet': _wallet, 'sessionId': _sessionId});
    });

    _locationSub = locationStream.listen((route) {
      if (!(route?.startsWith('/guess-the-drawing') ?? false)) {
        _socket.disconnect();
      }
    });
  }

  IO.Socket get socket => _socket;

  void dispose({bool force = false}) {
    _pingTimer?.cancel();
    _locationSub?.cancel();
    if (force) {
      _socket.disconnect();
      _socket.dispose(); // ✅ REQUIRED for memory cleanup
    }
  }
}
