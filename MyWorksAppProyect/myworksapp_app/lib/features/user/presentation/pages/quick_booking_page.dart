import 'package:myworksapp/core/utils/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/models/user_model.dart';
import '../../../../core/database/models/worker_model.dart';
import '../../../../core/database/repositories/service_repository.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/database/repositories/worker_repository.dart';
import '../../../../core/providers/service_providers.dart';
import '../../../../core/services/pricing_service.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/utils/comuna_utils.dart';
import '../../../../core/design_system/layout_utils.dart';
import '../../../../core/domain/booking_schedule.dart';
import '../../../../core/domain/worker_hours.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/mock_reserved_slots.dart';
import '../../../../utils/content_filter.dart';
import '../widgets/time_slot_selector.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import '../../../../core/widgets/escrow_checkout_sheet.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/pricing_quote_card.dart';
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
  final _addressController =
      TextEditingController(text: 'Av. Diego Portales 860, Puerto Montt');
  final _notesController = TextEditingController();
  final _workerRepository = WorkerRepository();
  final _userRepository = UserRepository();
  final _serviceRepository = ServiceRepository();

  WorkerModel? _worker;
  UserModel? _workerUser;
  String? _serviceName;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay? _selectedTime;
  List<DateTime> _freeSlots = [];
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final worker = await _workerRepository.getWorkerByUserId(widget.workerId);
    final user = await _userRepository.getPublicProfile(widget.workerId);
    final service = await _serviceRepository.getServiceById(widget.serviceId);
    List<DateTime> slots = const [];
    try {
      slots = await _workerRepository.fetchFreeSlots(widget.workerId);
    } catch (_) {
      slots = const [];
    }
    if (mounted) {
      setState(() {
        _worker = worker;
        _workerUser = user;
        _serviceName = service?.name;
        _freeSlots = slots;
        _loading = false;
      });
    }
  }

  List<String> get _hoursForSelectedDate => openSlotsOnDate(_freeSlots, _selectedDate)
      .map((slot) => MockReservedSlots.format(TimeOfDay.fromDateTime(slot.toLocal())))
      .toList();

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await pickBookingDate(
      context,
      selected: _selectedDate,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
      });
    }
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
    if (ContentFilter.hasSensitiveData(_notesController.text)) {
      await ContentFilter.showBlockedDialog(context);
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un horario disponible')),
      );
      return;
    }

    final scheduledDate = matchingFreeSlot(
      freeSlots: _freeSlots,
      date: _selectedDate,
      hour: _selectedTime!.hour,
      minute: _selectedTime!.minute,
    );
    if (scheduledDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(WorkerHourSlot.slotTakenMessage),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final notes = _notesController.text.trim();
      final description = notes.isNotEmpty
          ? notes
          : 'Visita programada con ${_workerUser?.name ?? 'trabajador'}';

      final bookingService = ref.read(jobBookingServiceProvider);
      final booking = await bookingService.createVisitBooking(
        userId: auth.id,
        workerId: widget.workerId,
        serviceId: widget.serviceId,
        address: address,
        visitFeeClp: _worker!.visitFee.round(),
        scheduledDate: scheduledDate,
        description: description,
        comunaKey: inferComunaKey(address),
      );

      if (!mounted) return;

      final paid = await EscrowCheckoutSheet.show(
        context,
        jobId: booking.job.id,
        quote: booking.quote,
        workerName: _workerUser?.name,
        serviceName: _serviceName,
      );

      if (paid) {
        await bookingService.confirmEscrowAndAccept(
          jobId: booking.job.id,
          userId: auth.id,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visita agendada y pago en garantía')),
        );
        context.go('${AppConstants.routeJobDetail}/${booking.job.id}');
        return;
      }

      await bookingService.abandonUnpaidCheckout(
        jobId: booking.job.id,
        userId: auth.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pago cancelado. El pedido no se envió al profesional.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorHandler.userMessage(e))),
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
      return const Scaffold(
        appBar: AppGradientAppBar(title: Text('Agendar visita')),
        body: Center(child: Text('Trabajador no encontrado')),
      );
    }

    final dateFmt = DateFormat('EEEE d MMMM', 'es_CL');

    return Scaffold(
      backgroundColor: AppDecorations.canvasOf(context),
      appBar: const AppGradientAppBar(title: Text('Agendar visita')),
      body: SingleChildScrollView(
        padding: LayoutUtils.scrollPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PricingQuoteCard(
              quote: PricingService.instance.calculateVisitBooking(
                visitFeeClp: _worker!.visitFee.round(),
                comunaKey: inferComunaKey(_addressController.text),
              ),
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
            TimeSlotSelector(
              selected: _selectedTime,
              availableLabels: _hoursForSelectedDate,
              emptyHint: _freeSlots.isEmpty
                  ? 'Este profesional aún no publica horarios de atención.'
                  : 'Este profesional no tiene horas libres este día.',
              onChanged: (time) => setState(() => _selectedTime = time),
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
                  : const Text('Continuar al pago'),
            ),
          ],
        ),
      ),
    );
  }
}
