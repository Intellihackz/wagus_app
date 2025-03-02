import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRepository {
  final chatCollection = FirebaseFirestore.instance.collection('chat');

  Stream<QuerySnapshot> getMessages() {
    return chatCollection.orderBy('timestamp', descending: true).snapshots();
  }

  Future<void> sendMessage(String message) async {
    try {
      await chatCollection.add({
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      log('Error sending message: $e');
    }
  }
}
