import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wagus/features/home/domain/message.dart';

class HomeRepository {
  final bool useTestCollection;

  HomeRepository({this.useTestCollection = false});

  CollectionReference get chatCollection => FirebaseFirestore.instance
      .collection(useTestCollection ? 'chat_test' : 'chat');

  Stream<QuerySnapshot> getMessages(String room) {
    return chatCollection
        .where('room', isEqualTo: room)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> sendMessage(Message message) async {
    try {
      await chatCollection.add({
        'message': message.text,
        'sender': message.sender,
        'tier': message.tier.name,
        'room': message.room,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      log('Error sending message: $e');
    }
  }
}
