import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wagus/features/games/presentation/widgets/glitch_overlay.dart';
import 'package:wagus/services/user_service.dart';

class MemoryBreach extends StatefulWidget {
  final String walletAddress;
  const MemoryBreach({super.key, required this.walletAddress});

  @override
  State<MemoryBreach> createState() => _MemoryBreachState();
}

class _MemoryBreachState extends State<MemoryBreach>
    with WidgetsBindingObserver {
  final List<String> _availableInputs = ['S', 'U', 'G', 'A', 'W'];
  final Map<String, String> _fragments = {
    'S': 'Signal Override',
    'U': 'Unknown Uplink',
    'G': 'Glitched Data',
    'A': 'Anomaly Detected',
    'W': 'Wipe Attempt',
  };

  final List<String> _sequence = [];
  final List<String> _userInput = [];

  bool _isShowingSequence = false;
  int _score = 0;
  final _userService = UserService();
  String _message = '';
  int _currentStep = 0;
  bool _isWaitingToStartInput = false;
  int _countdown = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startGame();
  }

  void _startGame() {
    _sequence.clear();
    _userInput.clear();
    _score = 0;
    _message = '';
    _addNextInSequence();
    _playSequence();
  }

  void _addNextInSequence() {
    final random = Random();
    final next = _availableInputs[random.nextInt(_availableInputs.length)];
    _sequence.add(next);
  }

  Future<void> _playSequence() async {
    setState(() {
      _isShowingSequence = true;
      _userInput.clear();
      _message = 'Decoding memory...';
    });

    for (var i = 0; i < _sequence.length; i++) {
      final current = _sequence[i];
      _currentStep = i;
      setState(() {
        _message = _fragments[current] ?? '...';
      });
      await Future.delayed(const Duration(milliseconds: 700));
    }

    setState(() {
      _message = 'Begin input in 3...';
      _countdown = 3;
      _isWaitingToStartInput = true;
    });

    // Countdown gate
    for (int i = 2; i >= 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _countdown = i;
        _message = i == 0 ? 'Inject the sequence' : 'Begin input in $i...';
      });
    }

    setState(() {
      _isWaitingToStartInput = false;
      _isShowingSequence = false;
    });
  }

  void _forceReset(String msg) {
    setState(() {
      _message = msg;
      _sequence.clear();
      _userInput.clear();
      _score = 0;
      _isShowingSequence = false;
      _isWaitingToStartInput = false;
    });
    Future.delayed(const Duration(seconds: 2), _startGame);
  }

  void _handleInput(String input) {
    if (_isShowingSequence || _isWaitingToStartInput) return;

    setState(() {
      _message = _fragments[input] ?? '';
    });

    _userInput.add(input);
    final currentIndex = _userInput.length - 1;

    if (_userInput[currentIndex] != _sequence[currentIndex]) {
      setState(() {
        _message = 'Memory corrupted. Reinitializing...';
      });
      Future.delayed(const Duration(seconds: 2), _startGame);
      return;
    }

    if (_userInput.length == _sequence.length) {
      setState(() {
        _score++;
        _message = 'Memory injection successful. Round $_score';
      });

      // 🔥 Save high score to Firebase
      _userService.updateMemoryBreachScore(widget.walletAddress, _score);

      Future.delayed(const Duration(milliseconds: 1500), () {
        _addNextInSequence();
        _playSequence();
      });
    }
  }

  Widget _buildButton(String label) {
    final isActive = _isShowingSequence && _sequence[_currentStep] == label;

    return GestureDetector(
      onTap: () => _handleInput(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 80,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? Colors.pinkAccent : Colors.deepPurple[800],
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: Colors.pinkAccent.withOpacity(0.8), blurRadius: 20)
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier',
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _forceReset("Session interrupted. Reinitializing...");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        textTheme: GoogleFonts.vt323TextTheme(
          Theme.of(context).textTheme.apply(
                bodyColor: Colors.white,
                displayColor: Colors.white,
              ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  Text(
                    'MEMORY BREACH',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.pinkAccent.shade100,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Wallet: ${widget.walletAddress}',
                    style: const TextStyle(
                      color: Colors.white24,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'Courier',
                    ),
                  ),
                  const Spacer(),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: _availableInputs.map(_buildButton).toList(),
                  ),
                  const Spacer(),
                  Text(
                    'Sequence Length: ${_sequence.length}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 24),
                  FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: _userService.getUser(widget.walletAddress),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final highScore =
                          snapshot.data!.data()?['memory_breach_score'] ?? 1;
                      return Text(
                        'High Score: $highScore',
                        style: const TextStyle(color: Colors.white54),
                      );
                    },
                  ),
                ],
              ),
            ),
            const GlitchOverlay(),
            if (_isWaitingToStartInput && _countdown > 0)
              Center(
                child: Text(
                  '$_countdown',
                  style: TextStyle(
                    fontSize: 96,
                    color: Colors.pinkAccent.withOpacity(0.6),
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 24,
                        color: Colors.pinkAccent.withOpacity(0.8),
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
