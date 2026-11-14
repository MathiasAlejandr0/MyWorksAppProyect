import '../../../core/utils/constants.dart';

/// Motivo para no guardar la calificación. Null si se puede enviar.
String? ratingBlockReason({
  required String? currentUserId,
  required String? jobClientId,
  required String? jobStatus,
  required bool alreadyRated,
  required bool disputeOpen,
}) {
  if (currentUserId == null || currentUserId.isEmpty) {
    return 'Debes iniciar sesión para calificar';
  }
  if (jobClientId == null || jobClientId.isEmpty) {
    return 'No encontramos el trabajo';
  }
  if (currentUserId != jobClientId) {
    return 'Solo el cliente de este trabajo puede calificar';
  }
  if (jobStatus != AppConstants.jobStatusCompleted) {
    return 'Puedes calificar cuando el trabajo esté terminado';
  }
  if (disputeOpen) {
    return 'Calificación bloqueada por una disputa abierta';
  }
  if (alreadyRated) {
    return 'Este trabajo ya tiene una calificación';
  }
  return null;
}
