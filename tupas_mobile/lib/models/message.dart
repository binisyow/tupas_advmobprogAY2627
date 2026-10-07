import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;
  final List<String> deliveredTo;
  final List<String> seenBy;
  final bool isSending;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    this.deliveredTo = const [],
    this.seenBy = const [],
    this.isSending = false,
  });

  factory ChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    final timestamp = data['createdAt'] as Timestamp?;
    return ChatMessage(
      id: snapshot.id,
      senderId: data['senderId'] as String,
      receiverId: data['receiverId'] as String,
      text: data['text'] as String,
      createdAt: timestamp?.toDate() ?? DateTime.now(),
      deliveredTo: List<String>.from(data['deliveredTo'] as List? ?? const []),
      seenBy: List<String>.from(data['seenBy'] as List? ?? const []),
    );
  }
}
