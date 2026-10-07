import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/chat_user.dart';
import '../models/message.dart';
import '../services/chat_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String currentUid;
  final ChatUser otherUser;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.currentUid,
    required this.otherUser,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _chatService = ChatService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _sendingMessages = [];
  late final Stream<List<ChatMessage>> _messagesStream;
  int _lastRenderedMessageCount = -1;
  bool _isSending = false;
  bool _updatingReceipts = false;

  @override
  void initState() {
    super.initState();
    _messagesStream = _chatService.watchMessages(widget.conversationId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final optimisticMessage = ChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      senderId: widget.currentUid,
      receiverId: widget.otherUser.uid,
      text: text,
      createdAt: DateTime.now(),
      isSending: true,
    );
    setState(() {
      _isSending = true;
      _sendingMessages.add(optimisticMessage);
      _messageController.clear();
    });
    _scrollToBottom();

    try {
      await _chatService.sendMessage(
        conversationId: widget.conversationId,
        senderId: widget.currentUid,
        receiverId: widget.otherUser.uid,
        text: text,
      );
      if (!mounted) return;
      setState(() {
        _sendingMessages.removeWhere(
          (message) => message.id == optimisticMessage.id,
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sendingMessages.removeWhere(
          (message) => message.id == optimisticMessage.id,
        );
        _messageController.text = text;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message could not be sent: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _syncReceipts(List<ChatMessage> messages) {
    final incoming = messages
        .where((message) => message.receiverId == widget.currentUid)
        .toList();
    if (_updatingReceipts ||
        !incoming.any(
          (message) =>
              !message.deliveredTo.contains(widget.currentUid) ||
              !message.seenBy.contains(widget.currentUid),
        )) {
      return;
    }
    unawaited(_updateReceipts(incoming));
  }

  Future<void> _updateReceipts(List<ChatMessage> incoming) async {
    _updatingReceipts = true;
    try {
      await _chatService.markMessagesDelivered(
        conversationId: widget.conversationId,
        userId: widget.currentUid,
        messages: incoming,
      );
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      await _chatService.markMessagesSeen(
        conversationId: widget.conversationId,
        userId: widget.currentUid,
        messages: incoming,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update message status: $error')),
      );
    } finally {
      _updatingReceipts = false;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
              child: Text(widget.otherUser.initials),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 17),
                  ),
                  Text(
                    widget.otherUser.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load messages: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = [...snapshot.data!, ..._sendingMessages]
                  ..sort((first, second) {
                    final dateOrder = first.createdAt.compareTo(
                      second.createdAt,
                    );
                    return dateOrder != 0
                        ? dateOrder
                        : first.id.compareTo(second.id);
                  });
                _syncReceipts(messages);
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text(
                        'Say hello to ${widget.otherUser.displayName} to start chatting.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (messages.length != _lastRenderedMessageCount) {
                  _lastRenderedMessageCount = messages.length;
                  _scrollToBottom();
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _MessageBubble(
                      key: ValueKey(message.id),
                      message: message,
                      isMine: message.senderId == widget.currentUid,
                      peerUid: widget.otherUser.uid,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 4000,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Write a message...',
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send message',
                    onPressed: _isSending ? null : _sendMessage,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isMine;
  final String peerUid;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.peerUid,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bubbleColor = widget.isMine
        ? colors.primary
        : colors.surfaceContainerHighest;
    final textColor = widget.isMine ? colors.onPrimary : colors.onSurface;
    final time = TimeOfDay.fromDateTime(
      widget.message.createdAt,
    ).format(context);
    final hasBeenSeen = widget.message.seenBy.contains(widget.peerUid);
    final hasBeenDelivered = widget.message.deliveredTo.contains(
      widget.peerUid,
    );

    return FadeTransition(
      opacity: _controller,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(widget.isMine ? 0.08 : -0.08, 0.08),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
        child: Align(
          alignment: widget.isMine
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              padding: const EdgeInsets.fromLTRB(14, 10, 12, 7),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(widget.isMine ? 18 : 5),
                  bottomRight: Radius.circular(widget.isMine ? 5 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.message.text,
                      style: TextStyle(color: textColor, fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                      if (widget.isMine) ...[
                        const SizedBox(width: 5),
                        if (widget.message.isSending)
                          Text(
                            'sending...',
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.78),
                              fontSize: 10,
                            ),
                          )
                        else
                          Semantics(
                            label: hasBeenSeen
                                ? 'Seen'
                                : hasBeenDelivered
                                ? 'Delivered'
                                : 'Sent',
                            child: Icon(
                              hasBeenSeen || hasBeenDelivered
                                  ? Icons.done_all
                                  : Icons.done,
                              size: 15,
                              color: hasBeenSeen
                                  ? Colors.lightBlueAccent
                                  : textColor.withValues(alpha: 0.75),
                            ),
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
