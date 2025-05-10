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

  Stream<DocumentSnapshot> listenToGiveaway(String giveawayId) {
    return FirebaseFirestore.instance
        .collection('giveaways')
        .doc(giveawayId)
        .snapshots();
  }

  Stream<QuerySnapshot> listenToActiveGiveaways(String hostWallet) {
    return FirebaseFirestore.instance
        .collection('giveaways')
        .where('host', isEqualTo: hostWallet)
        .where('status', whereIn: ['started', 'ended']) // ✅
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
        'likes': 0,
      });
    } catch (e) {
      log('Error sending message: $e');
    }
  }
}
