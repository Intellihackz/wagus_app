import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wagus/features/games/presentation/widgets/glitch_overlay.dart';
import 'package:wagus/services/user_service.dart';
import 'package:wagus/core/theme/app_palette.dart';

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

  bool isProcessingNextRound = false;

  Future<void> _handleInput(String input) async {
    if (_isShowingSequence || _isWaitingToStartInput || isProcessingNextRound)
      return;

    setState(() {
      _message = _fragments[input] ?? '';
    });

    _userInput.add(input);
    final currentIndex = _userInput.length - 1;

    // ❌ If the input is incorrect, reset
    if (_userInput[currentIndex] != _sequence[currentIndex]) {
      setState(() {
        _message = 'Memory corrupted. Reinitializing...';
      });
      await Future.delayed(const Duration(seconds: 2));
      _startGame();
      return;
    }

    // ✅ Only if all inputs were correct
    if (_userInput.length == _sequence.length) {
      isProcessingNextRound = true;

      setState(() {
        _score++;
        _message = 'Memory injection successful. Round $_score';
      });

      await Future.delayed(const Duration(milliseconds: 1000));
      await _userService.updateMemoryBreachScore(widget.walletAddress, _score);

      _addNextInSequence();
      await _playSequence();

      isProcessingNextRound = false;
    }
  }

  Widget _buildButton(String label) {
    final isActive = _isShowingSequence && _sequence[_currentStep] == label;

    return GestureDetector(
      onTap: () => _handleInput(label),
      child: Container(
        //duration: const Duration(milliseconds: 200),
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
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left button
                      Align(
                          alignment: Alignment.topCenter,
                          child: BackButton(
                              color: context.appColors.contrastLight)),

                      // Center content
                      Expanded(
                        child: Center(
                          child: StreamBuilder<
                              QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .where('memory_breach_score', isGreaterThan: 0)
                                .orderBy('memory_breach_score',
                                    descending: true)
                                .limit(3)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const SizedBox();
                              final docs = snapshot.data!.docs;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: docs.map((doc) {
                                  final score =
                                      doc.data()['memory_breach_score'];
                                  final username = doc.data()['username'] ??
                                      '${doc.id.substring(0, 4)}...';
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          username,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white38,
                                          ),
                                        ),
                                        Text(
                                          '$score',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                      ),

                      // Placeholder to balance BackButton width
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
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
                    SizedBox(
                      height: 80,
                      child: Center(
                        child: Text(
                          _message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontFamily: 'Courier',
                          ),
                          overflow: TextOverflow.fade,
                          maxLines: 2,
                        ),
                      ),
                    ),
                    Spacer(),
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
      ),
    );
  }
}
