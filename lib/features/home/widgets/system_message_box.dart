import 'package:flutter/material.dart';
import 'package:wagus/features/home/domain/message.dart' show Message;

class SystemMessageBox extends StatelessWidget {
  const SystemMessageBox({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 217, 246, 255),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            message.text,
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
