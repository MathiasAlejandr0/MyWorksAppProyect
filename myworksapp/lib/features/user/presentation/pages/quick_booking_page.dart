import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/models/job_model.dart';
import '../../../../core/database/models/user_model.dart';
import '../../../../core/database/models/worker_model.dart';
import '../../../../core/database/repositories/job_repository.dart';
import '../../../../core/database/repositories/service_repository.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/database/repositories/worker_repository.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/price_summary_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Reserva rápida: dirección, fecha y confirmación con precio de visita.
class QuickBookingPage extends ConsumerStatefulWidget {
  const QuickBookingPage({
    super.key,
    required this.workerId,
    required this.serviceId,
  });

  final String workerId;
  final String serviceId;

  @override
  ConsumerState<QuickBookingPage> createState() => _QuickBookingPageState();
}

class _QuickBookingPageState extends ConsumerState<QuickBookingPage> {
  final _addressController = TextEditingController(text: 'Av. Providencia 1234, Santiago');
  final _notesController = TextEditingController();
  final _jobRepository = JobRepository();
  final _workerRepository = WorkerRepository();
  final _userRepository = UserRepository();
  final _serviceRepository = ServiceRepository();

  WorkerModel? _worker;
  UserModel? _workerUser;
  String? _serviceName;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final worker = await _workerRepository.getWorkerByUserId(widget.workerId);
    final user = await _userRepository.getUserById(widget.workerId);
    final service = await _serviceRepository.getServiceById(widget.serviceId);
    if (mounted) {
      setState(() {
        _worker = worker;
        _workerUser = user;
        _serviceName = service?.name;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('es', 'CL'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _confirm() async {
    final auth = ref.read(authProvider).user;
    if (auth == null || _worker == null) return;

    final address = _addressController.text.trim();
    if (address.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una dirección válida')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final now = DateTime.now();
      final notes = _notesController.text.trim();
      final description = notes.isNotEmpty
          ? notes
          : 'Visita programada con ${_workerUser?.name ?? 'trabajador'}';

      final job = JobModel(
        id: const Uuid().v4(),
        userId: auth.id,
        workerId: widget.workerId,
        serviceId: widget.serviceId,
        status: AppConstants.jobStatusAccepted,
        address: address,
        description: description,
        scheduledDate: _selectedDate,
        createdAt: now,
        updatedAt: now,
      );

      await _jobRepository.createJob(job);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visita agendada correctamente')),
      );
      context.go('${AppConstants.routeJobDetail}/${job.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: LoadingWidget());
    }

    if (_worker == null) {
      return Scaffold(
        appBar: AppGradientAppBar(title: const Text('Agendar visita')),
        body: const Center(child: Text('Trabajador no encontrado')),
      );
    }

    final dateFmt = DateFormat('EEEE d MMMM', 'es_CL');

    return Scaffold(
      backgroundColor: AppDecorations.screenBackground,
      appBar: AppGradientAppBar(title: const Text('Agendar visita')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PriceSummaryCard(
              visitFee: _worker!.visitFee,
              workerName: _workerUser?.name,
              serviceName: _serviceName,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Dirección',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Fecha de visita'),
              subtitle: Text(dateFmt.format(_selectedDate)),
              trailing: TextButton(onPressed: _pickDate, child: const Text('Cambiar')),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                hintText: 'Ej: enchufe de cocina no funciona',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting ? null : _confirm,
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirmar visita'),
            ),
          ],
        ),
      ),
    );
  }
}
