part of 'job_detail_page.dart';

// El estado es privado de la página; la extensión se invoca por nombre.
// ignore: library_private_types_in_public_api
extension JobDetailWorkflows on _JobDetailPageState {
  Future<void> _submitQuoteProposal() async {
    final job = _job;
    final user = ref.read(authProvider).user;
    if (job == null || user == null) return;

    if (!OpenQuoteUtils.canWorkerSubmitQuote(job, user.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta solicitud fue enviada a otro profesional'),
          backgroundColor: AppColors.error,
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
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
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
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _requestOvertimeHours() async {
    final job = _job;
    final user = ref.read(authProvider).user;
    if (job == null || user == null || job.workerId != user.id) return;

    final worker = await _workerRepository.getWorkerByUserId(user.id);
    if (worker == null) return;
    if (!mounted) return;

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
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  void _goToDashboard() {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    if (user.role == AppConstants.roleWorker) {
      requestWorkerHomeRefresh(ref);
      context.go(AppConstants.routeWorkerHome);
      return;
    }
    context.go(AppConstants.routeUserHome);
  }

  Future<void> _payEscrow() async {
    final job = _job;
    final auth = ref.read(authProvider).user;
    if (job == null || auth == null) return;

    final quote = JobDetailHelpers.quoteFromJob(job);
    if (quote == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cotización para este trabajo')),
      );
      return;
    }

    final paid = await PaymentScreen.open(
      context,
      jobId: job.id,
      amount: quote.totalClp.toDouble(),
      serviceName: job.description,
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
        const SnackBar(
          content: Text(
            'Pedido confirmado. Se descontará el monto de tu tarjeta. El profesional ya puede aceptar el pedido.',
          ),
        ),
      );
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _approveCompletion() async {
    final job = _job;
    final auth = ref.read(authProvider).user;
    if (job == null || auth == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recibo conforme'),
        content: const Text(
          'Confirmas que el trabajo quedó bien. Los fondos retenidos se liberan al profesional.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Liberar fondos'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await JobBookingService.instance.confirmCompletionAndPay(
        jobId: job.id,
        userId: auth.id,
      );

      if (job.workerId != null) {
        requestWorkerHomeRefresh(ref);
        await NotificationService.instance.showNotification(
          title: 'Pago confirmado',
          body:
              'El cliente aprobó tu trabajo. Activa tu disponibilidad cuando quieras recibir nuevos trabajos.',
          userId: job.workerId!,
          type: 'job_completion_approved',
          relatedId: job.id,
        );
      }

      await _loadJobDetails();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trabajo recibido conforme. Los fondos quedaron liberados.')),
      );
      context.push('${AppConstants.routeRating}/${widget.jobId}');
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _rejectCompletion() async {
    final job = _job;
    final auth = ref.read(authProvider).user;
    if (job == null || auth == null) return;

    final descriptionCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No estoy conforme'),
        content: TextField(
          controller: descriptionCtrl,
          decoration: const InputDecoration(
            labelText: 'Qué no quedó bien',
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Abrir ticket'),
          ),
        ],
      ),
    );
    final description = descriptionCtrl.text.trim();
    descriptionCtrl.dispose();
    if (confirm != true || !mounted) return;

    await _openDispute(
      AppConstants.disputeReasonQuality,
      description.isEmpty ? 'El cliente no recibió conforme el trabajo.' : description,
    );
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
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
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
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _loadAddress(JobModel job) async {
    refreshView(() {
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
        refreshView(() {
          _displayAddress = address;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      final fallback = job.status == AppConstants.jobStatusPending
          ? 'Ubicación aproximada'
          : await LocationUtils.resolveExactAddress(
              address: job.address,
              latitude: job.latitude,
              longitude: job.longitude,
            );
      if (mounted) {
        refreshView(() {
          _displayAddress = fallback;
          _isLoadingAddress = false;
        });
      }
    }
  }

  Widget buildJobDetail(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: null,
        body: LoadingWidget(),
      );
    }

    if (_error != null || _job == null) {
      return Scaffold(
        appBar: const AppGradientAppBar(),
        body: ErrorStateWidget(
          title: 'Trabajo no disponible',
          message: _error ?? 'Trabajo no encontrado',
          actionLabel: 'Reintentar',
          onRetry: _loadJobDetails,
        ),
      );
    }

    final authState = ref.watch(authProvider);
    final currentUser = authState.user;
    final isWorker = currentUser?.role == AppConstants.roleWorker;
    final isOwner = currentUser?.id == _job!.userId || currentUser?.id == _job!.workerId;
    final hasCoordinates =
        _job!.latitude != null && _job!.longitude != null;
    final workerShowsLocationCard = isWorker &&
        currentUser?.id == _job!.workerId &&
        _job!.status != AppConstants.jobStatusPending &&
        hasCoordinates;
    final clientShowsLocationPreview = !isWorker &&
        _job!.status != AppConstants.jobStatusPending &&
        hasCoordinates;

    return Scaffold(
      appBar: AppGradientAppBar(
        title: const Text('Detalles del Trabajo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: isWorker ? 'Volver al panel' : 'Volver al inicio',
            onPressed: _goToDashboard,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: LayoutUtils.scrollPadding(context, top: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            JobDetailStatusHeader(job: _job!),
            const SizedBox(height: 12),
            JobStatusTimeline(status: _job!.status),
            if (_job!.scheduledDate != null && !workerShowsLocationCard) ...[
              const SizedBox(height: 12),
              JobDetailScheduledDateRow(scheduledDate: _job!.scheduledDate!),
            ],
            if (workerShowsLocationCard) ...[
              const SizedBox(height: 12),
              JobAcceptedLocationCard(
                address: _isLoadingAddress ? 'Obteniendo dirección...' : _displayAddress,
                latitude: _job!.latitude!,
                longitude: _job!.longitude!,
                scheduledDate: _job!.scheduledDate,
                isLoadingAddress: _isLoadingAddress,
              ),
            ],
            JobDetailPaymentEscrowSection(
              job: _job!,
              jobId: widget.jobId,
              isWorker: isWorker,
              isClientOwner: currentUser?.id == _job!.userId,
              isAssignedWorker: currentUser?.id == _job!.workerId,
              invitedWorkerName: _invitedWorkerName,
              quoteProposals: _quoteProposals,
              onPayEscrow: _payEscrow,
              onApproveCompletion: _approveCompletion,
              onRejectCompletion: _rejectCompletion,
            ),
            const SizedBox(height: 16),
            JobDetailDescriptionSection(job: _job!),
            const SizedBox(height: 16),
            if (!isWorker && currentUser?.id == _job!.userId) ...[
              const SizedBox(height: 12),
              ClientLiveTracking(
                jobId: _job!.id,
                jobStatus: _job!.status,
                destinationLat: _job!.latitude,
                destinationLng: _job!.longitude,
              ),
            ],
            if (isWorker && currentUser?.id == _job!.workerId)
              WorkerGpsPublisher(
                jobId: _job!.id,
                active: publishesLiveGps(_job!.status),
              ),
            if (clientShowsLocationPreview) ...[
              JobLocationPreviewSection(
                address: _isLoadingAddress
                    ? 'Obteniendo ubicación...'
                    : _displayAddress,
                latitude: _job!.latitude!,
                longitude: _job!.longitude!,
                isLoadingAddress: _isLoadingAddress,
              ),
            ] else if (!workerShowsLocationCard) ...[
              JobLocationPreviewSection(
                address: _isLoadingAddress
                    ? 'Obteniendo ubicación...'
                    : _displayAddress,
                latitude: _job!.latitude ?? 0,
                longitude: _job!.longitude ?? 0,
                isLoadingAddress: _isLoadingAddress,
                showApproximateHint:
                    _job!.status == AppConstants.jobStatusPending,
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
              const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            ChangeOrdersSection(
              orders: _changeOrders,
              isWorker: isWorker,
              canRequest: isWorker &&
                  _job!.status == AppConstants.jobStatusInProgress,
              onRequest: _requestChangeOrder,
              onReview: !isWorker ? _approveChangeOrder : null,
            ),
            const SizedBox(height: 16),
            DisputeSection(
              dispute: _dispute,
              isParticipant: isOwner,
              canOpenDispute: _canOpenDispute(_job!),
              onOpenDispute: _openDispute,
              onAddComment: _addDisputeComment,
            ),
            JobDetailActionsSection(
              jobId: widget.jobId,
              job: _job!,
              isWorker: isWorker,
              isOwner: isOwner,
              canTransition: _canTransition,
              onGoToDashboard: _goToDashboard,
              onCancelJob: () => JobDetailStatusActions(this)._cancelJob(),
              onAcceptJob: () => JobDetailStatusActions(this)._acceptJob(),
              onRejectJob: () => JobDetailStatusActions(this)._rejectJob(),
              onMarkEnRoute: () =>
                  JobDetailStatusActions(this)._updateJobStatus(
                    AppConstants.jobStatusEnRoute,
                  ),
              onStartJob: () =>
                  JobDetailStatusActions(this)._updateJobStatus(
                    AppConstants.jobStatusInProgress,
                  ),
              onRequestOvertimeHours: _requestOvertimeHours,
              onCompleteJob: () => JobDetailStatusActions(this)._completeJob(),
            ),
          ],
        ),
      ),
    );
  }
}
