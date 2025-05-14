import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wagus/features/home/domain/message.dart';

class HomeRepository {
  final bool useTestCollection;

  HomeRepository({this.useTestCollection = false});

  CollectionReference<Map<String, dynamic>> get chatCollection =>
      FirebaseFirestore.instance
          .collection(useTestCollection ? 'chat_test' : 'chat')
          .withConverter<Map<String, dynamic>>(
            fromFirestore: (snapshot, _) => snapshot.data()!,
            toFirestore: (data, _) => data,
          );

  CollectionReference get roomCollection =>
      FirebaseFirestore.instance.collection('rooms');

  Stream<QuerySnapshot> getMessages(String room, {int limit = 50}) {
    return chatCollection
        .where('room', isEqualTo: room)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<QuerySnapshot> getInitialMessages(String room, int limit) {
    return chatCollection
        .where('room', isEqualTo: room)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getMoreMessages(
      String room, int limit, DocumentSnapshot lastDoc) async {
    return chatCollection
        .where('room', isEqualTo: room)
        .orderBy('timestamp', descending: true)
        .startAfterDocument(lastDoc)
        .limit(limit)
        .get();
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

  Stream<QuerySnapshot> listenToRooms() {
    return roomCollection.orderBy('createdAt').snapshots();
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
        if (message.gifUrl != null) 'gif_url': message.gifUrl,
        if (message.replyToMessageId != null)
          'reply_to_id': message.replyToMessageId,
        if (message.replyToText != null) 'reply_to_text': message.replyToText,
      });
    } catch (e) {
      log('Error sending message: $e');
    }
  }
}
