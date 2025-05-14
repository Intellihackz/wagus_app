import 'package:wagus/features/portal/bloc/portal_bloc.dart';

class Message {
  final String sender;
  final String text;
  final TierStatus tier;
  final String room;
  final double? solBalance;
  final int? wagBalance;
  final int? likes;
  final String? id;
  final String? gifUrl;
  final String? replyToMessageId;
  final String? replyToText;

  Message({
    required this.sender,
    required this.text,
    required this.room,
    this.id,
    this.likes,
    TierStatus? tier,
    this.solBalance,
    this.wagBalance,
    this.gifUrl,
    this.replyToMessageId,
    this.replyToText,
  }) : tier = tier ?? TierStatus.basic;

  Message copyWith({
    String? sender,
    String? text,
    String? room,
    TierStatus? tier,
    double? Function()? solBalance,
    int? Function()? wagBalance,
    int? Function()? likes,
    String? Function()? id,
    String? Function()? gifUrl,
  }) {
    return Message(
      sender: sender ?? this.sender,
      text: text ?? this.text,
      room: room ?? this.room,
      tier: tier ?? this.tier,
      solBalance: solBalance?.call() ?? this.solBalance,
      wagBalance: wagBalance?.call() ?? this.wagBalance,
      likes: likes?.call() ?? this.likes,
      id: id?.call() ?? this.id,
      gifUrl: gifUrl?.call() ?? this.gifUrl,
    );
  }
}
