import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wagus/features/games/domain/guess_the_drawing/guess_entry.dart';

class GuessTheDrawingSession {
  final String id;
  final List<String> players;
  final Map<String, int> scores;
  final int round;
  final int currentDrawerIndex; // <- replace drawer string
  final String word;
  final List<GuessEntry> guesses;
  final bool isComplete;

  GuessTheDrawingSession({
    required this.id,
    required this.players,
    required this.scores,
    required this.round,
    required this.currentDrawerIndex,
    required this.word,
    required this.guesses,
    required this.isComplete,
  });

  GuessTheDrawingSession nextRound(String newWord) {
    final nextIndex = (currentDrawerIndex + 1) % players.length;

    return GuessTheDrawingSession(
      id: id,
      players: players,
      scores: scores,
      round: round + 1,
      currentDrawerIndex: nextIndex,
      word: newWord,
      guesses: [],
      isComplete: false,
    );
  }

  String get drawer => players.isNotEmpty && currentDrawerIndex < players.length
      ? players[currentDrawerIndex]
      : '';

  factory GuessTheDrawingSession.fromFirestore(
      String id, Map<String, dynamic> data) {
    return GuessTheDrawingSession(
      id: id,
      players: List<String>.from(data['players']),
      scores: Map<String, int>.from(data['scores']),
      round: data['round'],
      currentDrawerIndex: data['currentDrawerIndex'],
      word: data['word'],
      guesses: (data['guesses'] as List<dynamic>?)
              ?.map((g) => GuessEntry.fromMap(g))
              .toList() ??
          [],
      isComplete: data['isComplete'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'players': players,
        'scores': scores,
        'round': round,
        'currentDrawerIndex': currentDrawerIndex,
        'word': word,
        'guesses': guesses.map((g) => g.toMap()).toList(),
        'isComplete': isComplete,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
