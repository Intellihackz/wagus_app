import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageEntry {
  final String wallet;
  final String text;
  final bool isGuess;
  final DateTime timestamp;

  ChatMessageEntry({
    required this.wallet,
    required this.text,
    required this.isGuess,
    required this.timestamp,
  });

  factory ChatMessageEntry.fromMap(Map<String, dynamic> data) {
    return ChatMessageEntry(
      wallet: data['wallet'],
      text: data['text'],
      isGuess: data['isGuess'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'wallet': wallet,
        'text': text,
        'isGuess': isGuess,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}
