part of 'job_detail_page.dart';

extension JobDetailStatusActions on _JobDetailPageState {
  Future<void> _updateJobStatus(String newStatus) async {
    try {
      final authState = ref.read(authProvider);
      final user = authState.user;
      if (user == null || _job == null) return;

      // Validar transición usando JobStateMachine
      if (!await _stateMachine.isValidTransition(
        _job!.status,
        newStatus,
        pricingMode: _job!.pricingMode,
      )) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se puede cambiar el estado de ${_job!.status} a $newStatus'),
            backgroundColor: AppColors.error,
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
              type: 'job_$newStatus',
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
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _acceptJob() async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null || _job == null) return;

    // Validar transición usando JobStateMachine
    if (!await _stateMachine.isValidTransition(
      _job!.status,
      AppConstants.jobStatusAccepted,
      pricingMode: _job!.pricingMode,
    )) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede aceptar un trabajo en estado: ${_job!.status}'),
          backgroundColor: AppColors.error,
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
          backgroundColor: AppColors.warning,
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
      
      final WorkerRepository workerRepository = WorkerRepository();
      await workerRepository.updateAvailability(user.id, false);
      await workerRepository.enforceUnavailableWhileBusy(user.id);
      
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

      requestWorkerHomeRefresh(ref, openTabIndex: 1);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trabajo aceptado. Revisa los detalles en la pestaña En curso.'),
        ),
      );
      context.go(AppConstants.routeWorkerHome);
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _completeJob() async {
    if (_job == null) return;

    final targetStatus = JobDetailHelpers.completionTargetStatus(_job!);

    if (!await _stateMachine.isValidTransition(
      _job!.status,
      targetStatus,
      pricingMode: _job!.pricingMode,
    )) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede finalizar un trabajo en estado: ${_job!.status}'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final evidenceCount =
        await _jobPhotoRepository.getEvidenceCountByJobId(widget.jobId);

    if (evidenceCount == 0) {
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Evidencia requerida'),
          content: const Text(
            'Debes subir al menos una foto o un video del trabajo antes de finalizarlo. ¿Quieres subir evidencia ahora?',
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
              child: const Text('Subir evidencia'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
      return;
    }

    try {
      final authState = ref.read(authProvider);
      final user = authState.user;
      if (user == null) return;

      await _stateMachine.transitionTo(
        jobId: widget.jobId,
        newStatus: targetStatus,
        userId: user.id,
      );

      if (targetStatus == PricingConstants.jobAwaitingClientApproval) {
        await NotificationService.instance.showNotification(
          title: 'Trabajo finalizado',
          body: 'El profesional terminó. Si recibes conforme, se liberan los fondos retenidos.',
          userId: _job!.userId,
          type: 'job_completion_review',
          relatedId: widget.jobId,
        );
      }

      await _loadJobDetails();

      if (targetStatus == AppConstants.jobStatusCompleted) {
        if (user.role == AppConstants.roleWorker) {
          requestWorkerHomeRefresh(ref);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Trabajo finalizado. Activa tu disponibilidad cuando quieras recibir nuevos trabajos.',
              ),
            ),
          );
        }
        if (user.role == AppConstants.roleUser) {
          if (!mounted) return;
          context.push('${AppConstants.routeRating}/${widget.jobId}');
        }
      } else if (!mounted) {
        return;
      } else {
        requestWorkerHomeRefresh(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Evidencia enviada. Cuando el cliente apruebe podrás activar tu disponibilidad.',
            ),
          ),
        );
      }
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _cancelJob() async {
    if (_job == null) return;

    if (!await _stateMachine.isValidTransition(
      _job!.status,
      AppConstants.jobStatusCancelled,
      pricingMode: _job!.pricingMode,
    )) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede cancelar un trabajo en estado: ${_job!.status}'),
          backgroundColor: AppColors.error,
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
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
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
            backgroundColor: AppColors.error,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _rejectJob() async {
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
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sí, rechazar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authState = ref.read(authProvider);
      final user = authState.user;
      if (user == null || _job == null) return;

      final isTierInvitation =
          _job!.serviceMetadata?['request_type'] == 'worker_tier_invitation';

      if (isTierInvitation) {
        try {
          await WorkerJobRejectionService.instance.rejectAndSuggestAlternatives(
            jobId: widget.jobId,
            workerId: user.id,
          );
          requestWorkerHomeRefresh(ref);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Solicitud rechazada correctamente')),
          );
          context.go(AppConstants.routeWorkerHome);
        } on AppError catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
          );
        }
        return;
      }

      await _updateJobStatus(AppConstants.jobStatusCancelled);
      requestWorkerHomeRefresh(ref);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }
}
