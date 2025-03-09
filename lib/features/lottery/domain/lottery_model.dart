import 'package:cloud_firestore/cloud_firestore.dart';

class LotteryModel {
  final int amount;
  final dynamic timestamp;
  final List<String> participants;
  final String? winner;

  LotteryModel({
    required this.amount,
    required this.timestamp,
    required this.participants,
    this.winner,
  });

  get currentTimestamp => FieldValue.serverTimestamp();

  factory LotteryModel.fromJson(Map<String, dynamic> json) {
    return LotteryModel(
      amount: json['amount'] ?? 0,
      timestamp: json['timestamp'] ?? FieldValue.serverTimestamp(),
      participants: List<String>.from(json['participants'] ?? []),
      winner: json['winner'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'timestamp': timestamp,
      'participants': participants,
      'winner': winner,
    };
  }
}
