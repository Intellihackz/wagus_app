import 'package:cloud_firestore/cloud_firestore.dart';

class GuessEntry {
  final String wallet;
  final String guess;
  final DateTime timestamp;
  final bool isCorrect;

  GuessEntry({
    required this.wallet,
    required this.guess,
    required this.timestamp,
    required this.isCorrect,
  });

  factory GuessEntry.fromMap(Map<String, dynamic> data) {
    return GuessEntry(
      wallet: data['wallet'],
      guess: data['guess'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isCorrect: data['isCorrect'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'wallet': wallet,
        'guess': guess,
        'timestamp': Timestamp.fromDate(timestamp),
        'isCorrect': isCorrect,
      };
}
