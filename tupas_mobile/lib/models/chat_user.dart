import 'package:cloud_firestore/cloud_firestore.dart';

class ChatUser {
  final String uid;
  final String displayName;
  final String email;

  const ChatUser({
    required this.uid,
    required this.displayName,
    required this.email,
  });

  factory ChatUser.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    final email = data['email'] as String? ?? '';
    return ChatUser(
      uid: data['uid'] as String? ?? snapshot.id,
      displayName: (data['displayName'] as String? ?? '').trim().isNotEmpty
          ? (data['displayName'] as String).trim()
          : email,
      email: email,
    );
  }

  String get initials {
    final words = displayName.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '?';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return '${words.first.substring(0, 1)}${words.last.substring(0, 1)}'
        .toUpperCase();
  }
}
