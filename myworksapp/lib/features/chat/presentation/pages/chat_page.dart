import 'package:flutter/material.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/repositories/message_repository.dart';
import '../../../../core/database/repositories/job_repository.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/database/models/message_model.dart';
import '../../../../core/database/models/job_model.dart';
import '../../../../core/database/models/user_model.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/design_system/empty_state_widget.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String jobId;

  const ChatPage({super.key, required this.jobId});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final MessageRepository _messageRepository = MessageRepository();
  final JobRepository _jobRepository = JobRepository();
  final UserRepository _userRepository = UserRepository();

  List<MessageModel> _messages = [];
  JobModel? _job;
  UserModel? _otherUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final job = await _jobRepository.getJobById(widget.jobId);
      final messages = await _messageRepository.getMessagesByJobId(widget.jobId);
      
      final authState = ref.read(authProvider);
      final currentUser = authState.user;
      
      if (job != null && currentUser != null) {
        final otherUserId = currentUser.id == job.userId ? job.workerId : job.userId;
        if (otherUserId != null) {
          final otherUser = await _userRepository.getUserById(otherUserId);
          
          // Marcar mensajes como leídos
          await _messageRepository.markAllAsRead(widget.jobId, currentUser.id);

          setState(() {
            _job = job;
            _messages = messages;
            _otherUser = otherUser;
            _isLoading = false;
          });

          _scrollToBottom();
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final authState = ref.read(authProvider);
    final currentUser = authState.user;
    if (currentUser == null || _job == null) return;

    final otherUserId = currentUser.id == _job!.userId ? _job!.workerId : _job!.userId;
    if (otherUserId == null) return;

    try {
      final message = MessageModel(
        id: const Uuid().v4(),
        jobId: widget.jobId,
        senderId: currentUser.id,
        receiverId: otherUserId,
        content: _messageController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _messageRepository.createMessage(message);
      
      // Enviar notificación al receptor
      try {
        await NotificationService.instance.showNotification(
          title: 'Nuevo mensaje',
          body: message.content,
          userId: otherUserId,
          type: 'new_message',
          relatedId: widget.jobId,
        );
      } catch (e) {
        // Ignorar errores de notificación
      }
      
      _messageController.clear();
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final authState = ref.watch(authProvider);
    final currentUser = authState.user;

    return Scaffold(
      appBar: AppGradientAppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_otherUser?.name ?? 'Chat'),
            if (_job != null)
              Text(
                _job!.description ?? 'Trabajo',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.chat_bubble_outline,
                    title: 'No hay mensajes aún',
                    message: '¡Envía el primer mensaje para comenzar la conversación!',
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message.senderId == currentUser?.id;
                      return _MessageBubble(
                        message: message,
                        isMe: isMe,
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                    color: Theme.of(context).colorScheme.primary,
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

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMe
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isMe
                    ? Colors.white70
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ayer ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}

