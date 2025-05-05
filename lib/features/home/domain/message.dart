import 'package:wagus/features/portal/bloc/portal_bloc.dart';

class Message {
  final String sender;
  final String text;
  final TierStatus tier;
  final String room;
  final double? solBalance;
  final int? wagBalance;

  Message({
    required this.sender,
    required this.text,
    required this.room,
    TierStatus? tier,
    this.solBalance,
    this.wagBalance,
  }) : tier = tier ?? TierStatus.basic;

  Message copyWith({
    String? sender,
    String? text,
    String? room,
    TierStatus? tier,
    double? Function()? solBalance,
    int? Function()? wagBalance,
  }) {
    return Message(
      sender: sender ?? this.sender,
      text: text ?? this.text,
      room: room ?? this.room,
      tier: tier ?? this.tier,
      solBalance: solBalance?.call() ?? this.solBalance,
      wagBalance: wagBalance?.call() ?? this.wagBalance,
    );
  }
}
