import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_user.dart';
import '../models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore;

  ChatService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<void> upsertUserProfile({
    required String uid,
    required String displayName,
    required String email,
    bool isNewAccount = false,
  }) {
    final values = <String, dynamic>{
      'uid': uid,
      'displayName': displayName.trim().isEmpty ? email : displayName.trim(),
      'email': email,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (isNewAccount) values['createdAt'] = FieldValue.serverTimestamp();
    return _users.doc(uid).set(values, SetOptions(merge: true));
  }

  Stream<List<ChatUser>> watchOtherUsers(String currentUid) {
    return _users.orderBy('displayName').snapshots().map(
      (snapshot) => snapshot.docs
          .where((document) => document.id != currentUid)
          .map(ChatUser.fromFirestore)
          .toList(),
    );
  }

  Future<String> getOrCreateConversation({
    required String currentUid,
    required String otherUid,
  }) async {
    if (currentUid == otherUid) {
      throw ArgumentError('You cannot start a conversation with yourself.');
    }

    final participants = [currentUid, otherUid]..sort();
    final firstUid = participants.first;
    final secondUid = participants.last;
    final conversationId =
        'chat_${firstUid.length}_$firstUid'
        '_${secondUid.length}_$secondUid';
    final conversation = _firestore.collection('chats').doc(conversationId);
    await conversation.set({
      'participants': participants,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return conversationId;
  }

  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _firestore
        .collection('chats')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ChatMessage.fromFirestore).toList(),
        );
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final conversation = _firestore.collection('chats').doc(conversationId);
    final message = conversation.collection('messages').doc();
    final batch = _firestore.batch();
    batch.set(message, {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'deliveredTo': [senderId],
      'seenBy': [senderId],
    });
    batch.set(
      conversation,
      {
        'participants': [senderId, receiverId]..sort(),
        'lastMessage': text,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> markMessagesDelivered({
    required String conversationId,
    required String userId,
    required Iterable<ChatMessage> messages,
  }) async {
    final batch = _firestore.batch();
    var hasUpdates = false;
    for (final message in messages) {
      if (message.receiverId != userId || message.deliveredTo.contains(userId)) {
        continue;
      }
      final reference = _firestore
          .collection('chats')
          .doc(conversationId)
          .collection('messages')
          .doc(message.id);
      batch.update(reference, {
        'deliveredTo': FieldValue.arrayUnion([userId]),
      });
      hasUpdates = true;
    }
    if (hasUpdates) await batch.commit();
  }

  Future<void> markMessagesSeen({
    required String conversationId,
    required String userId,
    required Iterable<ChatMessage> messages,
  }) async {
    final batch = _firestore.batch();
    var hasUpdates = false;
    for (final message in messages) {
      if (message.receiverId != userId || message.seenBy.contains(userId)) {
        continue;
      }
      final reference = _firestore
          .collection('chats')
          .doc(conversationId)
          .collection('messages')
          .doc(message.id);
      batch.update(reference, {
        'deliveredTo': FieldValue.arrayUnion([userId]),
        'seenBy': FieldValue.arrayUnion([userId]),
      });
      hasUpdates = true;
    }
    if (hasUpdates) await batch.commit();
  }
}
