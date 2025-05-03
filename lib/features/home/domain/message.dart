import 'package:wagus/features/portal/bloc/portal_bloc.dart';

class Message {
  final String sender;
  final String text;
  final TierStatus tier;
  final String room;

  Message({
    required this.sender,
    required this.text,
    required this.room,
    TierStatus? tier,
  }) : tier = tier ?? TierStatus.basic;
}
