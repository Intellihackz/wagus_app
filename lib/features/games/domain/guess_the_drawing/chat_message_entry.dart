import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageEntry {
  final String wallet;
  final String text;
  final bool isGuess;
  final bool isCorrect; // 🔥 ADD THIS
  final DateTime timestamp;

  ChatMessageEntry({
    required this.wallet,
    required this.text,
    required this.isGuess,
    required this.isCorrect,
    required this.timestamp,
  });

  factory ChatMessageEntry.fromMap(Map<String, dynamic> data) {
    return ChatMessageEntry(
      wallet: data['wallet'],
      text: data['text'],
      isGuess: data['isGuess'] ?? false,
      isCorrect: data['isCorrect'] ?? false, // 🔥 fallback false
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'wallet': wallet,
        'text': text,
        'isGuess': isGuess,
        'isCorrect': isCorrect,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}
