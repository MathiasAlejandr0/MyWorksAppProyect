import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/models/job_model.dart';
import '../../../../core/database/repositories/reschedule_repository.dart';
import '../../../../core/database/repositories/worker_repository.dart';
import '../../../../core/domain/reschedule_rules.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/utils/santiago_time.dart';

/// Cambiar la hora de un trabajo: una parte propone, la otra acepta o
/// rechaza. El cobro retenido no cambia. La base aplica las reglas.
class RescheduleSection extends StatefulWidget {
  const RescheduleSection({
    super.key,
    required this.job,
    required this.currentUserId,
    required this.onChanged,
    this.repository,
    this.workerRepository,
  });

  final JobModel job;
  final String? currentUserId;
  final Future<void> Function() onChanged;
  final RescheduleRepository? repository;
  final WorkerRepository? workerRepository;

  @override
  State<RescheduleSection> createState() => _RescheduleSectionState();
}

class _RescheduleSectionState extends State<RescheduleSection> {
  late final RescheduleRepository _repo =
      widget.repository ?? RescheduleRepository();
  late final WorkerRepository _workers =
      widget.workerRepository ?? WorkerRepository();
  final _fmt = DateFormat('EEE d MMM · HH:mm', 'es_CL');

  List<RescheduleProposal> _history = const [];
  bool _loaded = false;
  bool _busy = false;

  bool get _canPropose => RescheduleRules.canPropose(
        status: widget.job.status,
        scheduledAt: widget.job.scheduledDate,
        workerId: widget.job.workerId,
      );

  RescheduleProposal? get _pending {
    for (final item in _history) {
      if (item.isPending) return item;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RescheduleSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.job.status != widget.job.status ||
        oldWidget.job.scheduledDate != widget.job.scheduledDate) {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final rows = await _repo.history(widget.job.id);
      if (!mounted) return;
      setState(() {
        _history = rows;
        _loaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loaded = true);
    }
  }

  String _label(DateTime instant) => _fmt.format(SantiagoTime.wall(instant));

  Future<void> _run(Future<String> Function() task) async {
    setState(() => _busy = true);
    try {
      final message = await task();
      await _load();
      await widget.onChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.userMessage(error)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _propose() async {
    final workerId = widget.job.workerId;
    if (workerId == null) return;
    List<DateTime> free;
    try {
      free = await _workers.fetchFreeSlots(workerId);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorHandler.userMessage(error))),
      );
      return;
    }
    final options = RescheduleRules.slotOptions(free, widget.job.scheduledDate);
    if (!mounted) return;
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('No hay otras horas libres en las próximas dos semanas.'),
        ),
      );
      return;
    }
    final reasonCtrl = TextEditingController();
    DateTime? chosen;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Proponer otra hora'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'La otra parte debe aceptarla. El pago retenido no cambia.',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<DateTime>(
                  initialValue: chosen,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Nueva hora'),
                  items: options
                      .map(
                        (slot) => DropdownMenuItem(
                          value: slot,
                          child: Text(_label(slot)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setLocal(() => chosen = value),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonCtrl,
                  maxLength: 300,
                  decoration:
                      const InputDecoration(labelText: 'Motivo (opcional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: chosen == null ? null : () => Navigator.pop(ctx, true),
              child: const Text('Enviar propuesta'),
            ),
          ],
        ),
      ),
    );
    final reason = reasonCtrl.text;
    reasonCtrl.dispose();
    if (confirmed != true || chosen == null) return;
    await _run(() async {
      await _repo.propose(jobId: widget.job.id, at: chosen!, reason: reason);
      return 'Propuesta enviada. Falta que la otra parte la acepte.';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    final pending = _pending;
    final past = _history.where((item) => !item.isPending).toList();
    if (!_canPropose && _history.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final mustRespond =
        RescheduleRules.canRespond(pending, widget.currentUserId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_repeat, color: AppColors.brandOrange),
                const SizedBox(width: 8),
                Text('Cambiar la hora', style: theme.textTheme.titleMedium),
              ],
            ),
            if (widget.job.scheduledDate != null) ...[
              const SizedBox(height: 6),
              Text('Hora actual: ${_label(widget.job.scheduledDate!)}'),
            ],
            if (pending != null) ...[
              const SizedBox(height: 8),
              Text(
                '${pending.proposedBy == widget.currentUserId ? 'Propusiste' : pending.proposerRole == 'cliente' ? 'El cliente propone' : 'El profesional propone'}'
                ' mover la visita al ${_label(pending.proposedAt)}.'
                '${pending.reason != null ? ' Motivo: ${pending.reason}.' : ''}',
              ),
              const SizedBox(height: 8),
              if (mustRespond)
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                                final row = await _repo.respond(pending.id,
                                    accept: true);
                                return row.status == 'aceptada'
                                    ? 'Listo: la visita quedó en la nueva hora.'
                                    : 'La propuesta venció porque el trabajo cambió.';
                              }),
                      child: const Text('Aceptar nueva hora'),
                    ),
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                                await _repo.respond(pending.id, accept: false);
                                return 'Rechazaste el cambio. Se mantiene la hora.';
                              }),
                      child: const Text('Rechazar'),
                    ),
                  ],
                )
              else
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            await _repo.withdraw(pending.id);
                            return 'Retiraste tu propuesta.';
                          }),
                  child: const Text('Retirar mi propuesta'),
                ),
            ] else if (_canPropose) ...[
              const SizedBox(height: 8),
              Text(
                'Puedes proponer otra hora publicada antes de que el profesional salga en camino.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _busy ? null : _propose,
                icon: const Icon(Icons.schedule),
                label: const Text('Reagendar'),
              ),
            ],
            if (past.isNotEmpty) ...[
              const SizedBox(height: 8),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Historial de cambios de hora',
                  style: theme.textTheme.bodyMedium,
                ),
                children: past
                    .map(
                      (item) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${_label(item.previousAt)} → ${_label(item.proposedAt)}',
                        ),
                        subtitle: Text(
                          '${item.proposerRole == 'cliente' ? 'Propuesta del cliente' : 'Propuesta del profesional'}'
                          ' · ${RescheduleRules.statusLabel(item.status)}',
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
