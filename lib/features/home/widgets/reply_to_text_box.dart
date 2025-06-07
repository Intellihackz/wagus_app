import 'package:flutter/material.dart';
import 'package:wagus/features/home/domain/message.dart' show Message;

class ReplyToTextBox extends StatelessWidget {
  const ReplyToTextBox({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          border: Border(
            left: BorderSide(color: Colors.white30, width: 3),
          ),
        ),
        child: Text(
          message.replyToText!,
          style: const TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
