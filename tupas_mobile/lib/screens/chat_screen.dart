import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/chat_user.dart';
import '../services/chat_service.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _searchController = TextEditingController();
  final _chatService = ChatService();
  late final String? _currentUid;
  Stream<List<ChatUser>>? _usersStream;

  @override
  void initState() {
    super.initState();
    _currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (_currentUid != null)
      _usersStream = _chatService.watchOtherUsers(_currentUid);
    _searchController.addListener(_filterChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_filterChanged)
      ..dispose();
    super.dispose();
  }

  void _filterChanged() => setState(() {});

  Future<void> _openConversation(ChatUser user) async {
    final currentUid = _currentUid;
    if (currentUid == null) return;
    try {
      final conversationId = await _chatService.getOrCreateConversation(
        currentUid: currentUid,
        otherUid: user.uid,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatDetailScreen(
            conversationId: conversationId,
            currentUid: currentUid,
            otherUser: user,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open conversation: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: _currentUid == null
          ? _FirebaseAccountPrompt(
              onCreateAccount: () => Navigator.pushNamed(context, '/signup'),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search by name or email',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: _searchController.clear,
                              icon: const Icon(Icons.close),
                            ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.45),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<ChatUser>>(
                    stream: _usersStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _ErrorState(
                          message: 'Could not load users: ${snapshot.error}',
                          onRetry: () => setState(() {
                            _usersStream = _chatService.watchOtherUsers(
                              _currentUid,
                            );
                          }),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final query = _searchController.text.trim().toLowerCase();
                      final users = snapshot.data!
                          .where(
                            (user) =>
                                user.displayName.toLowerCase().contains(
                                  query,
                                ) ||
                                user.email.toLowerCase().contains(query),
                          )
                          .toList();
                      if (users.isEmpty) {
                        return _EmptyState(
                          message: query.isEmpty
                              ? 'No other registered users yet.'
                              : 'No users match "$query".',
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: users.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return Material(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(18),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 5,
                              ),
                              leading: _UserAvatar(user: user),
                              title: Text(
                                user.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                user.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _openConversation(user),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final ChatUser user;

  const _UserAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CircleAvatar(
      backgroundColor: colors.primaryContainer,
      foregroundColor: colors.onPrimaryContainer,
      child: Text(
        user.initials,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _FirebaseAccountPrompt extends StatelessWidget {
  final VoidCallback onCreateAccount;

  const _FirebaseAccountPrompt({required this.onCreateAccount});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mark_email_unread_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Chat is available to Firebase accounts.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a Firebase account to find and message other users.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onCreateAccount,
              child: const Text('Create Firebase account'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
