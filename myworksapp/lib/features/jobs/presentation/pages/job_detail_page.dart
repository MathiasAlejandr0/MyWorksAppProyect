import 'package:flutter/material.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/domain/price_quote.dart';
import '../../../../core/domain/pricing_constants.dart';
import '../../../../core/database/models/change_order_model.dart';
import '../../../../core/database/models/quote_proposal_model.dart';
import '../../../../core/database/repositories/change_order_repository.dart';
import '../../../../core/database/repositories/job_repository.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/database/models/job_model.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/utils/location_utils.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/job_state_machine.dart';
import '../../../../core/services/job_booking_service.dart';
import '../../../../core/services/change_order_service.dart';
import '../../../../core/services/quote_proposal_service.dart';
import '../../../../core/services/pricing_service.dart';
import '../../../../core/database/repositories/worker_repository.dart';
import '../widgets/quote_proposals_section.dart';
import '../widgets/open_quote_status_banner.dart';
import '../widgets/worker_quote_form_dialog.dart';
import '../../../../core/utils/open_quote_utils.dart';
import '../../../../core/widgets/escrow_checkout_sheet.dart';
import '../../../../core/widgets/pricing_quote_card.dart';
import '../../../../core/utils/app_error.dart';
import '../../../../core/database/repositories/job_photo_repository.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class JobDetailPage extends ConsumerStatefulWidget {
  final String jobId;

  const JobDetailPage({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends ConsumerState<JobDetailPage> {
  final JobRepository _jobRepository = JobRepository();
  final UserRepository _userRepository = UserRepository();
  final JobPhotoRepository _jobPhotoRepository = JobPhotoRepository();
  final JobStateMachine _stateMachine = JobStateMachine.instance;
  final ChangeOrderRepository _changeOrderRepository = ChangeOrderRepository();

  JobModel? _job;
  List<ChangeOrderModel> _changeOrders = [];
  List<QuoteProposalModel> _quoteProposals = [];
  final WorkerRepository _workerRepository = WorkerRepository();
  String? _invitedWorkerName;
  bool _isLoading = true;
  String? _error;
  String _displayAddress = '';
  bool _isLoadingAddress = true;
  
  // Estados de transiciones válidas (cache)
  Map<String, bool> _canTransition = {};

  @override
  void initState() {
    super.initState();
    _loadJobDetails();
  }

  Future<void> _loadJobDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final job = await _jobRepository.getJobById(widget.jobId);
      setState(() {
        _job = job;
        _isLoading = false;
      });
      
      if (job != null) {
        _loadAddress(job);
        _loadValidTransitions(job);
        await _loadChangeOrders(job.id);
        if (job.pricingMode == PricingConstants.modeOpenQuote) {
          await _loadQuoteProposals(job.id);
          await _loadInvitedWorkerName(job);
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Carga las transiciones válidas para el estado actual del job
  Future<void> _loadValidTransitions(JobModel job) async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null) return;

    final transitions = <String, bool>{};
    
    // Verificar cada transición posible
    final possibleStatuses = [
      PricingConstants.jobAwaitingPayment,
      AppConstants.jobStatusAccepted,
      AppConstants.jobStatusInProgress,
      AppConstants.jobStatusCompleted,
      AppConstants.jobStatusCancelled,
      PricingConstants.jobPausedChangeOrder,
    ];

    for (final status in possibleStatuses) {
      final canTransition = _stateMachine.isValidTransition(
        job.status,
        status,
        pricingMode: job.pricingMode,
      );
      transitions[status] = canTransition;
    }

    setState(() {
      _canTransition = transitions;
    });
  }

  Future<void> _loadChangeOrders(String jobId) async {
    final orders = await _changeOrderRepository.getByJobId(jobId);
    if (mounted) setState(() => _changeOrders = orders);
  }

  Future<void> _loadQuoteProposals(String jobId) async {
    final list = await QuoteProposalService.instance.listForJob(jobId);
    if (mounted) setState(() => _quoteProposals = list);
  }

  Future<void> _loadInvitedWorkerName(JobModel job) async {
    final invitedId = OpenQuoteUtils.invitedWorkerId(job);
    if (invitedId == null) {
      if (mounted) setState(() => _invitedWorkerName = null);
      return;
    }
    final user = await _userRepository.getUserById(invitedId);
    if (mounted) setState(() => _invitedWorkerName = user?.name);
  }

  Future<void> _submitQuoteProposal() async {
    final job = _job;
    final user = ref.read(authProvider).user;
    if (job == null || user == null) return;

    if (!OpenQuoteUtils.canWorkerSubmitQuote(job, user.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta solicitud fue enviada a otro profesional'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final form = await WorkerQuoteFormDialog.show(context);
    if (form == null || !mounted) return;

    try {
      await QuoteProposalService.instance.submit(
        jobId: job.id,
        workerId: user.id,
        montoTotalClp: form.montoTotalClp,
        descripcion: form.descripcion,
        materialesClp: form.materialesClp,
        manoObraClp: form.manoObraClp,
        horasEstimadas: form.horasEstimadas,
      );
      await _loadQuoteProposals(job.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Propuesta enviada. El cliente fue notificado y podrá aceptar el precio.'),
        ),
      );
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _selectQuoteProposal(QuoteProposalModel proposal) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Aceptas esta cotización?'),
        content: Text(
          'Al aceptar, confirmas el precio total de \$${proposal.montoTotalClp} propuesto por el profesional.\n\n'
          'Después deberás completar el pago en garantía (demo) para reservar el trabajo.\n\n'
          '${proposal.descripcion}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Rechazar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Aceptar precio')),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await QuoteProposalService.instance.selectProposal(
        jobId: widget.jobId,
        proposalId: proposal.id,
        clientUserId: user.id,
      );
      await _loadJobDetails();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cotización aceptada. Usa el botón de pago para confirmar en garantía.'),
        ),
      );
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _requestOvertimeHours() async {
    final job = _job;
    final user = ref.read(authProvider).user;
    if (job == null || user == null || job.workerId != user.id) return;

    final worker = await _workerRepository.getWorkerByUserId(user.id);
    if (worker == null) return;

    final hoursCtrl = TextEditingController(text: '1');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Horas extra'),
        content: TextField(
          controller: hoursCtrl,
          decoration: const InputDecoration(
            labelText: 'Horas adicionales (1-8)',
            helperText: 'Fuera del bloque ya pagado por el cliente',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Solicitar')),
        ],
      ),
    );

    final extra = int.tryParse(hoursCtrl.text.trim());
    hoursCtrl.dispose();
    if (ok != true || !mounted || extra == null) return;

    try {
      final rate =
          PricingService.instance.estimateHourlyRateFromVisitFee(worker.visitFee.round());
      final quote = PricingService.instance.calculateHourlyOvertime(
        hourlyRateClp: rate,
        extraHours: extra,
        comunaKey: job.comunaId,
      );
      await ChangeOrderService.instance.submit(
        jobId: job.id,
        workerId: user.id,
        titulo: 'Horas extra ($extra h)',
        descripcion: quote.message ?? 'Horas adicionales',
        montoClp: quote.subtotalClp,
        tipo: 'overtime',
      );
      await _loadJobDetails();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud de horas extra enviada')),
      );
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }

  PriceQuote? _quoteFromJob(JobModel job) {
    final snap = job.pricingSnapshot;
    if (snap == null || snap.isEmpty) return null;
    return PriceQuote.fromJson(snap);
  }

  Future<void> _payEscrow() async {
    final job = _job;
    final auth = ref.read(authProvider).user;
    if (job == null || auth == null) return;

    final quote = _quoteFromJob(job);
    if (quote == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cotización para este trabajo')),
      );
      return;
    }

    final paid = await EscrowCheckoutSheet.show(
      context,
      jobId: job.id,
      quote: quote,
    );

    if (!paid || !mounted) return;

    try {
      await JobBookingService.instance.confirmEscrowAndAccept(
        jobId: job.id,
        userId: auth.id,
      );
      await _loadJobDetails();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago confirmado y en garantía.')),
      );
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _requestChangeOrder() async {
    final job = _job;
    final user = ref.read(authProvider).user;
    if (job == null || user == null) return;

    final tituloCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final montoCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Solicitar cobro adicional'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloCtrl,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 2,
              ),
              TextField(
                controller: montoCtrl,
                decoration: const InputDecoration(labelText: 'Monto (CLP)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enviar')),
        ],
      ),
    );

    final titulo = tituloCtrl.text.trim();
    final descripcion = descCtrl.text.trim();
    final monto = int.tryParse(montoCtrl.text.trim());
    tituloCtrl.dispose();
    descCtrl.dispose();
    montoCtrl.dispose();

    if (ok != true || !mounted) return;

    if (titulo.isEmpty || monto == null || monto < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa título y monto válido (mín. 1000 CLP)')),
      );
      return;
    }

    try {
      await ChangeOrderService.instance.submit(
        jobId: job.id,
        workerId: user.id,
        titulo: titulo,
        descripcion: descripcion.isEmpty ? titulo : descripcion,
        montoClp: monto,
      );
      await _loadJobDetails();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cobro adicional enviado al cliente')),
      );
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _approveChangeOrder(ChangeOrderModel order) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(order.titulo),
        content: Text(
          '${order.descripcion}\n\nMonto: \$${order.montoClp}\n\nSe autorizará el cobro adicional (demo).',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Rechazar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Aprobar y pagar')),
        ],
      ),
    );

    if (confirm != true) {
      await ChangeOrderService.instance.reject(order: order, clientUserId: user.id);
      await _loadJobDetails();
      return;
    }

    try {
      await ChangeOrderService.instance.approveAndPay(
        order: order,
        clientUserId: user.id,
      );
      await _loadJobDetails();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cobro adicional aprobado')),
      );
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _loadAddress(JobModel job) async {
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      final address = await LocationUtils.getLocationTextForJob(
        address: job.address,
        status: job.status,
        latitude: job.latitude,
        longitude: job.longitude,
      );

      if (mounted) {
        setState(() {
          _displayAddress = address;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _displayAddress = job.status == AppConstants.jobStatusPending
              ? 'Ubicación aproximada'
              : job.address;
          _isLoadingAddress = false;
        });
      }
    }
  }

  Future<void> _updateJobStatus(String newStatus) async {
    try {
      final authState = ref.read(authProvider);
      final user = authState.user;
      if (user == null || _job == null) return;

      // Validar transición usando JobStateMachine
      if (!_stateMachine.isValidTransition(
        _job!.status,
        newStatus,
        pricingMode: _job!.pricingMode,
      )) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se puede cambiar el estado de ${_job!.status} a $newStatus'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Ejecutar transición usando JobStateMachine
      await _stateMachine.transitionTo(
        jobId: widget.jobId,
        newStatus: newStatus,
        userId: user.id,
      );

      await _loadJobDetails();
      
      // Enviar notificación
      if (_job != null) {
        final otherUserId = user.id == _job!.userId ? _job!.workerId : _job!.userId;
        if (otherUserId != null) {
          String title = '';
          String body = '';
          
          switch (newStatus) {
            case AppConstants.jobStatusAccepted:
              title = 'Trabajo Aceptado';
              body = 'Tu solicitud ha sido aceptada por el trabajador';
              break;
            case AppConstants.jobStatusInProgress:
              title = 'Trabajo Iniciado';
              body = 'El trabajador ha iniciado el trabajo';
              break;
            case AppConstants.jobStatusCompleted:
              title = 'Trabajo Completado';
              body = 'El trabajo ha sido finalizado. ¡Califica al trabajador!';
              break;
            case AppConstants.jobStatusCancelled:
              title = 'Trabajo Cancelado';
              body = 'El trabajo ha sido cancelado';
              break;
          }
          
          if (title.isNotEmpty) {
            await NotificationService.instance.showNotification(
              title: title,
              body: body,
              userId: otherUserId,
              type: 'job_${newStatus}',
              relatedId: widget.jobId,
            );
          }
        }
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estado actualizado')),
      );
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _acceptJob() async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null || _job == null) return;

    // Validar transición usando JobStateMachine
    if (!_stateMachine.isValidTransition(
      _job!.status,
      AppConstants.jobStatusAccepted,
      pricingMode: _job!.pricingMode,
    )) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede aceptar un trabajo en estado: ${_job!.status}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verificar si el trabajador ya tiene trabajos activos
    final hasActiveJobs = await _jobRepository.hasActiveJobs(user.id);
    if (hasActiveJobs) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No puedes aceptar más trabajos. Completa o cancela tus trabajos actuales primero.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Usar JobStateMachine para la transición
      await _stateMachine.transitionTo(
        jobId: widget.jobId,
        newStatus: AppConstants.jobStatusAccepted,
        userId: user.id,
      );

      // Asignar trabajador
      await _jobRepository.assignWorker(_job!.id, user.id);
      
      // Actualizar disponibilidad del trabajador a false
      final WorkerRepository _workerRepository = WorkerRepository();
      await _workerRepository.updateAvailability(user.id, false);
      
      await _loadJobDetails();
      
      // Recargar la dirección ahora que el trabajo está aceptado
      if (_job != null) {
        _loadAddress(_job!);
      }

      // Enviar notificación al usuario
      await NotificationService.instance.showNotification(
        title: 'Trabajo Aceptado',
        body: 'Tu solicitud ha sido aceptada por ${user.name}',
        userId: _job!.userId,
        type: 'job_accepted',
        relatedId: widget.jobId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trabajo aceptado. Ahora puedes ver la ubicación exacta. No podrás recibir más trabajos hasta completar este.'),
        ),
      );
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _completeJob() async {
    if (_job == null) return;

    // Validar transición usando JobStateMachine
    if (!_stateMachine.isValidTransition(
      _job!.status,
      AppConstants.jobStatusCompleted,
      pricingMode: _job!.pricingMode,
    )) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede completar un trabajo en estado: ${_job!.status}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verificar que el trabajador haya subido fotos
    final photoCount = await _jobPhotoRepository.getPhotoCountByJobId(widget.jobId);
    
    if (photoCount == 0) {
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Fotos Requeridas'),
          content: const Text(
            'Debes subir al menos una foto del trabajo antes de completarlo. ¿Quieres subir fotos ahora?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
                context.push('${AppConstants.routeJobPhotos}/${widget.jobId}');
              },
              child: const Text('Subir Fotos'),
            ),
          ],
        ),
      );
      
      if (confirm != true) {
        return;
      }
      return; // El usuario irá a subir fotos
    }

    try {
      final authState = ref.read(authProvider);
      final user = authState.user;
      if (user == null) return;

      // Usar JobStateMachine para la transición
      await _stateMachine.transitionTo(
        jobId: widget.jobId,
        newStatus: AppConstants.jobStatusCompleted,
        userId: user.id,
      );

      await _loadJobDetails();
      
      // Restaurar disponibilidad del trabajador
      if (user.role == AppConstants.roleWorker) {
        final WorkerRepository _workerRepository = WorkerRepository();
        await _workerRepository.updateAvailability(user.id, true);
      }
      
      // Si es usuario, mostrar opción de calificar
      if (user.role == AppConstants.roleUser) {
        if (!mounted) return;
        context.push('${AppConstants.routeRating}/${widget.jobId}');
      }
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelJob(BuildContext context) async {
    if (_job == null) return;

    // Validar transición usando JobStateMachine
    if (!_stateMachine.isValidTransition(
      _job!.status,
      AppConstants.jobStatusCancelled,
      pricingMode: _job!.pricingMode,
    )) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede cancelar un trabajo en estado: ${_job!.status}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Solicitud'),
        content: const Text('¿Estás seguro de que quieres cancelar esta solicitud?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final authState = ref.read(authProvider);
        final user = authState.user;
        if (user == null) return;

        // Usar JobStateMachine para la transición
        await _stateMachine.transitionTo(
          jobId: widget.jobId,
          newStatus: AppConstants.jobStatusCancelled,
          userId: user.id,
        );

        await _loadJobDetails();
        if (!mounted) return;
        Navigator.pop(context);
      } on AppError catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectJob(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Trabajo'),
        content: const Text('¿Estás seguro de que quieres rechazar este trabajo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sí, rechazar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _updateJobStatus(AppConstants.jobStatusCancelled);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: null,
        body: LoadingWidget(),
      );
    }

    if (_error != null || _job == null) {
      return Scaffold(
        appBar: AppGradientAppBar(),
        body: ErrorDisplayWidget(
          message: _error ?? 'Trabajo no encontrado',
          onRetry: _loadJobDetails,
        ),
      );
    }

    final authState = ref.watch(authProvider);
    final currentUser = authState.user;
    final isWorker = currentUser?.role == AppConstants.roleWorker;
    final isOwner = currentUser?.id == _job!.userId || currentUser?.id == _job!.workerId;

    return Scaffold(
      appBar: AppGradientAppBar(
        title: const Text('Detalles del Trabajo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(_job!.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(_job!.status),
                    color: _getStatusColor(_job!.status),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getStatusText(_job!.status),
                    style: TextStyle(
                      color: _getStatusColor(_job!.status),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (_job!.pricingMode != PricingConstants.modeLegacy &&
                _job!.paymentStatus != PricingConstants.paymentNone) ...[
              const SizedBox(height: 12),
              Text(
                'Pago: ${_paymentStatusLabel(_job!.paymentStatus)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (_job!.pricingMode == PricingConstants.modeOpenQuote) ...[
              const SizedBox(height: 12),
              OpenQuoteStatusBanner(
                jobStatus: _job!.status,
                isClient: !isWorker && currentUser?.id == _job!.userId,
                workerName: _invitedWorkerName,
                proposalsCount: _quoteProposals
                    .where((p) => p.estado == PricingConstants.quoteSubmitted)
                    .length,
              ),
            ],
            if (_job!.status == PricingConstants.jobAwaitingPayment &&
                !isWorker &&
                currentUser?.id == _job!.userId) ...[
              const SizedBox(height: 16),
              if (_quoteFromJob(_job!) != null)
                PricingQuoteCard(quote: _quoteFromJob(_job!)!),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _payEscrow,
                icon: const Icon(Icons.lock_outline),
                label: const Text('Pagar y confirmar reserva'),
              ),
            ],
            if (_job!.status == PricingConstants.jobAwaitingPayment && isWorker) ...[
              const SizedBox(height: 16),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('El cliente debe completar el pago en garantía para confirmar el trabajo.'),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Descripción
            Text(
              'Descripción',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _job!.description ?? 'Sin descripción',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            // Dirección
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _job!.status == AppConstants.jobStatusPending
                      ? Icons.location_searching
                      : Icons.location_on,
                  color: _job!.status == AppConstants.jobStatusPending
                      ? Colors.orange
                      : Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _isLoadingAddress
                          ? const Text('Obteniendo ubicación...')
                          : Text(
                              _displayAddress,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontStyle: _job!.status == AppConstants.jobStatusPending
                                    ? FontStyle.italic
                                    : null,
                              ),
                            ),
                      if (_job!.status == AppConstants.jobStatusPending) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 14,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Ubicación aproximada. Verás la dirección exacta al aceptar el trabajo',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            // Mapa (solo si el trabajo está aceptado o en progreso)
            if (_job!.status != AppConstants.jobStatusPending &&
                _job!.latitude != null &&
                _job!.longitude != null) ...[
              const SizedBox(height: 24),
              Text(
                'Ubicación',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              // Mapa integrado (requiere Maps SDK)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_job!.latitude!, _job!.longitude!),
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('job_location'),
                        position: LatLng(_job!.latitude!, _job!.longitude!),
                      ),
                    },
                    myLocationButtonEnabled: true,
                    myLocationEnabled: true,
                    mapType: MapType.normal,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Botón para abrir en Google Maps externo (siempre disponible)
              ElevatedButton.icon(
                onPressed: () async {
                  final url = Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=${_job!.latitude},${_job!.longitude}',
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.navigation),
                label: const Text('Abrir en Google Maps'),
              ),
            ],
            if (_job!.pricingMode == PricingConstants.modeHourlyBlock &&
                _job!.hourlyBlockHours != null) ...[
              const SizedBox(height: 8),
              Text(
                'Bloque prepagado: ${_job!.hourlyBlockHours} horas',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (_job!.pricingMode == PricingConstants.modeOpenQuote) ...[
              const SizedBox(height: 24),
              QuoteProposalsSection(
                proposals: _quoteProposals,
                isClient: !isWorker && currentUser?.id == _job!.userId,
                jobStatus: _job!.status,
                onSubmitQuote: isWorker ? _submitQuoteProposal : null,
                onSelect: !isWorker && currentUser?.id == _job!.userId
                    ? _selectQuoteProposal
                    : null,
              ),
            ],
            if (_changeOrders.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Cobros adicionales', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ..._changeOrders.map((o) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(o.titulo),
                      subtitle: Text('${o.descripcion}\n\$${o.montoClp} · ${o.estado}'),
                      isThreeLine: true,
                      trailing: o.isPendingClient && !isWorker
                          ? TextButton(
                              onPressed: () => _approveChangeOrder(o),
                              child: const Text('Revisar'),
                            )
                          : null,
                    ),
                  )),
            ],
            const SizedBox(height: 24),
            // Acciones según el rol y estado (validadas con JobStateMachine)
            if (isOwner) ...[
              // Cancelación para usuario (solo si está pendiente y transición válida)
              if (!isWorker && 
                  _job!.status == AppConstants.jobStatusPending &&
                  _canTransition[AppConstants.jobStatusCancelled] == true) ...[
                OutlinedButton(
                  onPressed: () => _cancelJob(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Cancelar Solicitud'),
                ),
              ],
              // Acciones para trabajador
              if (isWorker && 
                  _job!.status == AppConstants.jobStatusPending &&
                  _canTransition[AppConstants.jobStatusAccepted] == true) ...[
                ElevatedButton(
                  onPressed: _acceptJob,
                  child: const Text('Aceptar Trabajo'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _rejectJob(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Rechazar'),
                ),
              ],
              if (isWorker && 
                  _job!.status == AppConstants.jobStatusAccepted &&
                  _canTransition[AppConstants.jobStatusInProgress] == true) ...[
                ElevatedButton(
                  onPressed: () => _updateJobStatus(AppConstants.jobStatusInProgress),
                  child: const Text('Iniciar Trabajo'),
                ),
              ],
              if (isWorker &&
                  _job!.status == AppConstants.jobStatusInProgress) ...[
                OutlinedButton.icon(
                  onPressed: _requestChangeOrder,
                  icon: const Icon(Icons.add_card_outlined),
                  label: const Text('Solicitar cobro extra'),
                ),
                if (_job!.pricingMode == PricingConstants.modeHourlyBlock) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _requestOvertimeHours,
                    icon: const Icon(Icons.more_time),
                    label: const Text('Solicitar horas extra'),
                  ),
                ],
                const SizedBox(height: 8),
              ],
              if (isWorker && 
                  _job!.status == AppConstants.jobStatusInProgress &&
                  _canTransition[AppConstants.jobStatusCompleted] == true) ...[
                ElevatedButton(
                  onPressed: _completeJob,
                  child: const Text('Finalizar Trabajo'),
                ),
              ],
              if (isWorker &&
                  _job!.status == PricingConstants.jobAwaitingPayment) ...[
                const Text(
                  'El trabajo se confirmará cuando el cliente complete el pago.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
              if (!isWorker && _job!.status == AppConstants.jobStatusCompleted) ...[
                ElevatedButton(
                  onPressed: () {
                    context.push('${AppConstants.routeRating}/${widget.jobId}');
                  },
                  child: const Text('Calificar Trabajo'),
                ),
              ],
              // Botón de chat (si el trabajo está aceptado o en progreso)
              if ((_job!.status == AppConstants.jobStatusAccepted ||
                      _job!.status == AppConstants.jobStatusInProgress) &&
                  isOwner) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    context.push('${AppConstants.routeChat}/${widget.jobId}');
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Abrir Chat'),
                ),
              ],
              // Botón de fotos
              if (isOwner && _job!.status != AppConstants.jobStatusPending) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    context.push('${AppConstants.routeJobPhotos}/${widget.jobId}');
                  },
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Ver Fotos'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.jobStatusPending:
        return Colors.orange;
      case AppConstants.jobStatusAccepted:
        return Colors.blue;
      case AppConstants.jobStatusInProgress:
        return Colors.purple;
      case AppConstants.jobStatusCompleted:
        return Colors.green;
      case AppConstants.jobStatusCancelled:
        return Colors.red;
      case PricingConstants.jobAwaitingPayment:
        return Colors.deepOrange;
      case PricingConstants.jobAwaitingQuotes:
        return Colors.amber;
      case PricingConstants.jobQuoteSelected:
        return Colors.teal;
      case PricingConstants.jobPausedChangeOrder:
        return Colors.amber.shade800;
      default:
        return Colors.grey;
    }
  }

  String _paymentStatusLabel(String status) {
    switch (status) {
      case PricingConstants.paymentPending:
        return 'Pendiente';
      case PricingConstants.paymentAuthorized:
        return 'En garantía';
      case PricingConstants.paymentReleased:
        return 'Liberado al trabajador';
      case PricingConstants.paymentRefunded:
        return 'Reembolsado';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case AppConstants.jobStatusPending:
        return Icons.pending;
      case AppConstants.jobStatusAccepted:
        return Icons.check_circle_outline;
      case AppConstants.jobStatusInProgress:
        return Icons.work;
      case AppConstants.jobStatusCompleted:
        return Icons.check_circle;
      case AppConstants.jobStatusCancelled:
        return Icons.cancel;
      case PricingConstants.jobAwaitingPayment:
        return Icons.payment;
      case PricingConstants.jobAwaitingQuotes:
        return Icons.request_quote;
      case PricingConstants.jobQuoteSelected:
        return Icons.fact_check;
      case PricingConstants.jobPausedChangeOrder:
        return Icons.pause_circle;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case AppConstants.jobStatusPending:
        return 'Pendiente';
      case AppConstants.jobStatusAccepted:
        return 'Aceptado';
      case AppConstants.jobStatusInProgress:
        return 'En Curso';
      case AppConstants.jobStatusCompleted:
        return 'Completado';
      case AppConstants.jobStatusCancelled:
        return 'Cancelado';
      case PricingConstants.jobAwaitingPayment:
        return 'Pago pendiente';
      case PricingConstants.jobAwaitingQuotes:
        return 'Esperando cotizaciones';
      case PricingConstants.jobQuoteSelected:
        return 'Cotización seleccionada';
      case PricingConstants.jobPausedChangeOrder:
        return 'Cobro extra pendiente';
      default:
        return status;
    }
  }
}

