import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/models/job_model.dart';
import '../../../../core/database/repositories/job_repository.dart';
import '../../../../core/database/repositories/message_repository.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import '../../../../core/widgets/design_system/empty_state_widget.dart';
import '../../../../core/widgets/design_system/error_state_widget.dart';
import '../../../../core/widgets/design_system/loading_skeleton.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/conversation_preview.dart';

/// Bandeja real de chats: un ítem por trabajo, con el último mensaje.
class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({super.key});

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage> {
  final MessageRepository _messages = MessageRepository();
  final JobRepository _jobs = JobRepository();

  List<ConversationPreview> _previews = [];
  Map<String, JobModel> _jobsById = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final user = ref.read(authProvider).user;
    if (user == null) {
      setState(() {
        _loading = false;
        _error = 'Inicia sesión para ver tus mensajes.';
      });
      return;
    }

    try {
      final messages = await _messages.getMessagesByUserId(user.id);
      final clientJobs = await _jobs.getJobsByUserId(user.id);
      final workerJobs = await _jobs.getJobsByWorkerId(user.id);
      if (!mounted) return;
      setState(() {
        _previews = groupConversations(messages, user.id);
        _jobsById = {
          for (final job in [...clientJobs, ...workerJobs]) job.id: job,
        };
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ErrorHandler.getErrorMessage(e);
      });
    }
  }

  String _titleFor(String jobId) {
    final job = _jobsById[jobId];
    final description = job?.description?.trim();
    if (description != null && description.isNotEmpty) return description;
    final address = job?.address.trim();
    if (address != null && address.isNotEmpty) return address;
    final tail = jobId.length > 6 ? jobId.substring(jobId.length - 6) : jobId;
    return 'Trabajo $tail';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppGradientAppBar(title: Text('Mensajes')),
      body: _loading
          ? ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: 4,
              itemBuilder: (_, __) => const ListItemSkeleton(),
            )
          : _error != null
              ? ErrorStateWidget(
                  title: 'No se pudieron cargar los mensajes',
                  message: _error!,
                  onRetry: _load,
                )
              : _previews.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.chat_bubble_outline,
                      title: 'Sin conversaciones',
                      message:
                          'Cuando escribas en un trabajo, el chat aparece aquí.',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _previews.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _previews[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.brandOrangeSoft,
                              child: Icon(
                                Icons.chat_bubble_outline,
                                color: AppColors.brandOrange,
                              ),
                            ),
                            title: Text(
                              _titleFor(item.jobId),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              item.preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: item.unread > 0
                                ? CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppColors.brandOrange,
                                    child: Text(
                                      '${item.unread}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  )
                                : null,
                            onTap: () => context.push(
                              '${AppConstants.routeChat}/${item.jobId}',
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
