// Updated CodeNavigator with fog-of-war, pathfinding bots, time limit, and score-based level progression

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wagus/services/user_service.dart';

class CodeNavigator extends StatefulWidget {
  final String walletAddress;
  const CodeNavigator({super.key, required this.walletAddress});

  @override
  State<CodeNavigator> createState() => _CodeNavigatorState();
}

class _CodeNavigatorState extends State<CodeNavigator>
    with TickerProviderStateMixin {
  final int gridSize = 15;
  late AnimationController _glitchController;
  late AnimationController _timerController;

  Point<int> _playerPos = const Point(0, 0);
  late Point<int> _goal;
  Set<Point<int>> _noiseTraps = {};
  Set<Point<int>> _decoys = {};
  int _lives = 1;
  int _level = 1;
  //int _score = 0;
  String _message = '';
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    _glitchController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    _timerController =
        AnimationController(vsync: this, duration: const Duration(seconds: 30))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && !_isGameOver) {
              _gameOver('Time expired');
            }
          });
    _startLevel();
  }

  void _startLevel() {
    _playerPos = const Point(0, 0);
    final rand = Random();

    // Ensure the goal is at least 20 Manhattan units away
    Point<int> goal;
    do {
      goal = Point(rand.nextInt(gridSize), rand.nextInt(gridSize));
    } while (
        (_playerPos - goal).manhattan < 20); // adjust difficulty threshold here

    _goal = goal;

    _noiseTraps = List.generate(
      10 + _level * 2,
      (_) => Point(rand.nextInt(gridSize), rand.nextInt(gridSize)),
    ).toSet();

    _decoys = List.generate(
      3 + _level,
      (_) => Point(rand.nextInt(gridSize), rand.nextInt(gridSize)),
    ).toSet();

    _lives = 1;
    _isGameOver = false;
    _message = 'Find the signal in 30s. Lives: $_lives';
    _timerController.forward(from: 0);
    setState(() {});
  }

  void _move(Point<int> delta) {
    if (_isGameOver) return;
    final newPos = Point(_playerPos.x + delta.x, _playerPos.y + delta.y);
    if (!_inBounds(newPos)) return;
    _glitchController.forward(from: 0);

    _playerPos = newPos;
    if (_noiseTraps.contains(newPos)) {
      _lives--;
      _message = 'Signal disrupted. ($_lives lives left)';
      if (_lives <= 0) return _gameOver('All lives lost');
    } else if (_goal == newPos) {
      _message = 'Signal locked!';
      UserService()
          .markCodeNavigatorFound(widget.walletAddress); // 👈 Mark as found
      _level++;
      Future.delayed(const Duration(seconds: 2), _startLevel);
    } else if (_decoys.contains(newPos)) {
      _message = 'Signal locked...';
      setState(() {});

      Future.delayed(const Duration(seconds: 1), () {
        if (_isGameOver) return;

        final reduction = const Duration(seconds: 5);
        final remainingFraction = 1.0 - _timerController.value;
        final remainingTime = _timerController.duration! * remainingFraction;
        final newRemaining = remainingTime - reduction;

        if (newRemaining <= Duration.zero) {
          if (!_isGameOver) {
            _gameOver('Time expired');
            _timerController.stop();
            _timerController.value = 1.0;
            setState(() {}); // ensure message/timer UI reflects game over
            return;
          }
        } else {
          final newValue = 1.0 -
              (newRemaining.inMilliseconds /
                  _timerController.duration!.inMilliseconds);
          _timerController.value = newValue.clamp(0.0, 1.0);
          _timerController.forward(); // resume ticking
        }

        // Teleport far from goal
        final rand = Random();
        Point<int> teleport;
        do {
          teleport = Point(rand.nextInt(gridSize), rand.nextInt(gridSize));
        } while ((teleport - _goal).manhattan < gridSize ~/ 2 ||
            !_inBounds(teleport));

        _playerPos = teleport;
        _message = '…Error. False signal. You’ve been scrambled.';
        setState(() {});
      });
    } else {
      _message = 'Searching...';
    }
    setState(() {});
  }

  bool _inBounds(Point<int> p) =>
      p.x >= 0 && p.y >= 0 && p.x < gridSize && p.y < gridSize;

  void _gameOver(String reason) {
    _isGameOver = true;
    _timerController.stop();
    _message = 'Game Over: $reason';
    setState(() {});
  }

  Color _getTileColor(Point<int> p) {
    final dist = (_playerPos - p).manhattan;
    if (dist > 2) return Colors.black;
    if (_goal == p || _decoys.contains(p)) {
      return Colors.green; // identical look
    }
    if (_noiseTraps.contains(p)) return Colors.red;
    return Colors.blueGrey;
  }

  @override
  void dispose() {
    _glitchController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BackButton(
                  color: Colors.white,
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _message,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                ),
                SizedBox(
                  width: 48, // Fixed width for consistency
                ),
              ],
            ),
            AnimatedBuilder(
              animation: _timerController,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: 1.0 - _timerController.value,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation(Colors.cyanAccent),
                );
              },
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridSize,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: gridSize * gridSize,
                itemBuilder: (context, index) {
                  final x = index % gridSize;
                  final y = index ~/ gridSize;
                  final p = Point(x, y);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    color:
                        p == _playerPos ? Colors.cyanAccent : _getTileColor(p),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _dirButton('←', const Point(-1, 0)),
                Column(
                  children: [
                    _dirButton('↑', const Point(0, -1)),
                    const SizedBox(height: 4),
                    _dirButton('↓', const Point(0, 1)),
                  ],
                ),
                _dirButton('→', const Point(1, 0)),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _dirButton(String label, Point<int> delta) => Padding(
        padding: const EdgeInsets.all(6),
        child: InkWell(
          onTap: () => _move(delta),
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.cyanAccent.withOpacity(0.3),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.deepPurple[800]!, Colors.deepPurple[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      );
}

extension PointOps on Point<int> {
  int get manhattan => x.abs() + y.abs();
  Point<int> operator -(Point<int> other) => Point(x - other.x, y - other.y);
}
