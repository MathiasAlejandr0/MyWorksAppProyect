import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/models/message_model.dart';
import '../../../../core/database/models/payment_model.dart';
import '../../../../core/database/repositories/admin_repository.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/layout_utils.dart';
import '../../../../core/services/admin_notification_service.dart';
import '../../../../core/services/dispute_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AdminJobDetailPage extends ConsumerStatefulWidget {
  const AdminJobDetailPage({super.key, required this.jobId});

  final String jobId;

  @override
  ConsumerState<AdminJobDetailPage> createState() =>
      _AdminJobDetailPageState();
}

class _AdminJobDetailPageState extends ConsumerState<AdminJobDetailPage>
    with SingleTickerProviderStateMixin {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);
  AdminJobDetail? _detail;
  bool _loading = true;
  late final TabController _tabs;
  final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final detail = await _repo.getJobDetail(widget.jobId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _cancelJob() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar trabajo'),
        content: const Text('¿Cancelar este trabajo como administrador?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar trabajo'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _repo.updateJobStatus(widget.jobId, AppConstants.jobStatusCancelled);
    await _load();
  }

  Future<void> _resolveDispute() async {
    final d = _detail?.dispute;
    final admin = ref.read(authProvider).user;
    if (d == null || admin == null) return;

    final resolutionCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolver disputa'),
        content: TextField(
          controller: resolutionCtrl,
          decoration: const InputDecoration(labelText: 'Resolución'),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Resolver'),
          ),
        ],
      ),
    );
    final text = resolutionCtrl.text.trim();
    resolutionCtrl.dispose();
    if (ok != true || !mounted) return;

    await DisputeService.instance.resolveDispute(
      disputeId: d.id,
      resolvedBy: admin.id,
      resolution: text.isEmpty ? 'Resuelta por administrador' : text,
    );
    final job = _detail!.job;
    await AdminNotificationService.instance.notifyDisputeResolved(
      userId: job.userId,
      workerId: job.workerId,
      disputeId: d.id,
      resolution: text,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_detail == null) {
      return const Scaffold(
        appBar: AppGradientAppBar(title: Text('Trabajo')),
        body: Center(child: Text('Trabajo no encontrado')),
      );
    }

    final d = _detail!;
    final job = d.job;
    final canCancel =
        job.status != 'completed' && job.status != 'cancelled';

    return Scaffold(
      appBar: AppGradientAppBar(
        title: Text('Trabajo ${job.id.substring(0, 8)}…'),
        actions: [
          if (canCancel)
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              tooltip: 'Cancelar trabajo',
              onPressed: _cancelJob,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            const Tab(text: 'Resumen'),
            Tab(text: 'Chat (${d.messages.length})'),
            Tab(text: 'Pagos (${d.payments.length})'),
            const Tab(text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _SummaryTab(detail: d, dateFmt: _dateFmt),
          _ChatTab(messages: d.messages, dateFmt: _dateFmt),
          _PaymentsTab(payments: d.payments, dateFmt: _dateFmt),
          _HistoryTab(
            detail: d,
            dateFmt: _dateFmt,
            onResolveDispute: _resolveDispute,
          ),
        ],
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({required this.detail, required this.dateFmt});

  final AdminJobDetail detail;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final job = detail.job;
    return ListView(
      padding: LayoutUtils.scrollPadding(context),
      children: [
        _InfoCard(
          title: 'Estado',
          children: [
            _InfoRow('Estado', job.status),
            _InfoRow('Pago', job.paymentStatus),
            _InfoRow('Modo precio', job.pricingMode),
            _InfoRow('Creado', dateFmt.format(job.createdAt)),
            _InfoRow('Actualizado', dateFmt.format(job.updatedAt)),
          ],
        ),
        _InfoCard(
          title: 'Ubicación y servicio',
          children: [
            _InfoRow('Dirección', job.address),
            if (job.comunaId != null) _InfoRow('Comuna', job.comunaId!),
            _InfoRow('Servicio', detail.serviceName ?? job.serviceId),
            if (job.description != null)
              _InfoRow('Descripción', job.description!),
          ],
        ),
        _InfoCard(
          title: 'Partes',
          children: [
            _InfoRow('Cliente', detail.clientName ?? job.userId),
            if (detail.clientEmail != null)
              _InfoRow('Email cliente', detail.clientEmail!),
            if (job.workerId != null)
              _InfoRow('Trabajador', detail.workerName ?? job.workerId!),
            if (detail.workerEmail != null)
              _InfoRow('Email trabajador', detail.workerEmail!),
          ],
        ),
        if (detail.dispute != null)
          Card(
            color: AppColors.brandOrangeSoft,
            child: ListTile(
              leading: const Icon(Icons.gavel, color: AppColors.brandOrange),
              title: const Text('Disputa activa'),
              subtitle: Text(
                '${detail.dispute!.reason} · ${detail.dispute!.status}',
              ),
            ),
          ),
      ],
    );
  }
}

class _ChatTab extends StatelessWidget {
  const _ChatTab({required this.messages, required this.dateFmt});

  final List<MessageModel> messages;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(child: Text('Sin mensajes en este trabajo'));
    }
    return ListView.builder(
      padding: LayoutUtils.scrollPadding(context),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final m = messages[index];
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.85,
            ),
            decoration: BoxDecoration(
              color: AppColors.brandOrangeSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${m.senderId.substring(0, 8)}… · ${dateFmt.format(m.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  const _PaymentsTab({required this.payments, required this.dateFmt});

  final List<PaymentModel> payments;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return const Center(child: Text('Sin pagos registrados'));
    }
    return ListView.builder(
      padding: LayoutUtils.scrollPadding(context),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final p = payments[index];
        return Card(
          child: ListTile(
            leading: Icon(
              Icons.payments_outlined,
              color: p.status == 'released'
                  ? AppColors.success
                  : AppColors.brandOrange,
            ),
            title: Text(
              '${p.amount.toStringAsFixed(0)} ${p.currency}',
            ),
            subtitle: Text(
              '${p.status} · ${p.paymentType}\n'
              '${p.paymentMethod ?? '—'} · ${dateFmt.format(p.createdAt)}',
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({
    required this.detail,
    required this.dateFmt,
    required this.onResolveDispute,
  });

  final AdminJobDetail detail;
  final DateFormat dateFmt;
  final VoidCallback onResolveDispute;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    if (detail.rating != null) {
      final r = detail.rating!;
      items.add(
        _InfoCard(
          title: 'Calificación',
          children: [
            _InfoRow('Puntuación', '${r.score}/5'),
            if (r.comment != null) _InfoRow('Comentario', r.comment!),
            _InfoRow('Fecha', dateFmt.format(r.createdAt)),
          ],
        ),
      );
    }

    if (detail.dispute != null) {
      final disp = detail.dispute!;
      items.add(
        _InfoCard(
          title: 'Disputa',
          children: [
            _InfoRow('Motivo', disp.reason),
            _InfoRow('Estado', disp.status),
            if (disp.description != null)
              _InfoRow('Descripción', disp.description!),
            if (disp.resolution != null)
              _InfoRow('Resolución', disp.resolution!),
            if (disp.status == 'open' || disp.status == 'under_review')
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: FilledButton(
                  onPressed: onResolveDispute,
                  child: const Text('Resolver disputa'),
                ),
              ),
          ],
        ),
      );
    }

    if (detail.cancellation != null) {
      final c = detail.cancellation!;
      items.add(
        _InfoCard(
          title: 'Cancelación',
          children: [
            _InfoRow('Motivo', c.reason),
            _InfoRow('Cancelado por', c.cancelledBy),
            _InfoRow('Fecha', dateFmt.format(c.cancelledAt)),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return const Center(child: Text('Sin historial adicional'));
    }

    return ListView(
      padding: LayoutUtils.scrollPadding(context),
      children: items,
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grayMedium,
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
