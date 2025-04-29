import 'package:wagus/features/portal/bloc/portal_bloc.dart';

class Message {
  final String sender;
  final String text;
  final TierStatus tier;

  Message({
    required this.sender,
    required this.text,
    TierStatus? tier,
  }) : tier = tier ?? TierStatus.basic; // 👈 default if missing
}
