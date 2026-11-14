import '../../../core/utils/constants.dart';

class RatingDirection {
  RatingDirection._();

  static const String clientToWorker = 'cliente_a_trabajador';
  static const String workerToClient = 'trabajador_a_cliente';
}

/// Motivo para no guardar la calificación. Null si se puede enviar.
String? ratingBlockReason({
  required String? currentUserId,
  required String? jobClientId,
  required String? jobWorkerId,
  required String? jobStatus,
  required bool alreadyRated,
  required bool disputeOpen,
  required String direction,
}) {
  if (currentUserId == null || currentUserId.isEmpty) {
    return 'Debes iniciar sesión para calificar';
  }
  if (jobClientId == null || jobClientId.isEmpty) {
    return 'No encontramos el trabajo';
  }
  if (jobStatus != AppConstants.jobStatusCompleted) {
    return 'Puedes calificar cuando el trabajo esté terminado';
  }
  if (disputeOpen) {
    return 'Calificación bloqueada por una disputa abierta';
  }
  if (alreadyRated) {
    return 'Ya calificaste este trabajo';
  }
  if (direction == RatingDirection.clientToWorker) {
    if (currentUserId != jobClientId) {
      return 'Solo el cliente de este trabajo puede calificar al profesional';
    }
    if (jobWorkerId == null || jobWorkerId.isEmpty) {
      return 'Este trabajo no tiene profesional para calificar';
    }
    return null;
  }
  if (direction == RatingDirection.workerToClient) {
    if (jobWorkerId == null || currentUserId != jobWorkerId) {
      return 'Solo el profesional de este trabajo puede calificar al cliente';
    }
    return null;
  }
  return 'Dirección de calificación no válida';
}
