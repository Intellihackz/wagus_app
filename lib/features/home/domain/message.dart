import 'package:wagus/features/portal/bloc/portal_bloc.dart';

class Message {
  final String sender;
  final String text;
  final TierStatus tier;
  final String room;
  final double? solBalance;
  final int? wagBalance;
  final int? likes;
  final List<String>? likedBy; // ✅ add this line
  final String? id;
  final String? gifUrl;
  final String? replyToMessageId;
  final String? replyToText;
  final String? username;

  Message({
    required this.sender,
    required this.text,
    required this.room,
    this.id,
    this.likes,
    required this.likedBy, // ✅ add this
    TierStatus? tier,
    this.solBalance,
    this.wagBalance,
    this.gifUrl,
    this.replyToMessageId,
    this.replyToText,
    this.username,
  }) : tier = tier ?? TierStatus.basic;

  Message copyWith({
    String? sender,
    String? text,
    String? room,
    TierStatus? tier,
    double? Function()? solBalance,
    int? Function()? wagBalance,
    int? Function()? likes,
    List<String>? Function()? likedBy, // ✅ add this
    String? Function()? id,
    String? Function()? gifUrl,
    String? Function()? username,
  }) {
    return Message(
      sender: sender ?? this.sender,
      text: text ?? this.text,
      room: room ?? this.room,
      tier: tier ?? this.tier,
      solBalance: solBalance?.call() ?? this.solBalance,
      wagBalance: wagBalance?.call() ?? this.wagBalance,
      likes: likes?.call() ?? this.likes,
      likedBy: likedBy?.call() ?? this.likedBy, // ✅
      id: id?.call() ?? this.id,
      gifUrl: gifUrl?.call() ?? this.gifUrl,
      username: username?.call() ?? this.username,
    );
  }
}
