import '../utils/constants.dart';

/// Propuesta para cambiar la hora de un trabajo (tabla
/// `reprogramaciones_trabajo`). La base valida todo; esto solo decide qué
/// mostrar.
class RescheduleProposal {
  const RescheduleProposal({
    required this.id,
    required this.jobId,
    required this.proposedBy,
    required this.proposerRole,
    required this.previousAt,
    required this.proposedAt,
    required this.status,
    required this.createdAt,
    this.reason,
    this.respondedBy,
    this.respondedAt,
  });

  final String id;
  final String jobId;
  final String proposedBy;
  final String proposerRole;
  final DateTime previousAt;
  final DateTime proposedAt;
  final String status;
  final String? reason;
  final String? respondedBy;
  final DateTime? respondedAt;
  final DateTime createdAt;

  bool get isPending => status == RescheduleRules.statusPending;

  factory RescheduleProposal.fromMap(Map<String, dynamic> map) {
    DateTime parse(Object? value) =>
        DateTime.parse(value.toString().replaceFirst(' ', 'T')).toUtc();
    return RescheduleProposal(
      id: map['id'].toString(),
      jobId: map['id_trabajo'].toString(),
      proposedBy: map['propuesta_por'].toString(),
      proposerRole: (map['rol_proponente'] as String?) ?? 'cliente',
      previousAt: parse(map['fecha_anterior']),
      proposedAt: parse(map['fecha_propuesta']),
      status: (map['estado'] as String?) ?? RescheduleRules.statusPending,
      reason: map['motivo'] as String?,
      respondedBy: map['respondida_por'] as String?,
      respondedAt:
          map['respondida_en'] == null ? null : parse(map['respondida_en']),
      createdAt: parse(map['creado_en']),
    );
  }
}

class RescheduleRules {
  RescheduleRules._();

  static const String statusPending = 'pendiente';

  /// Estados en que se puede reagendar: antes de que el profesional salga.
  static const List<String> reschedulableStatuses = [
    AppConstants.jobStatusPending,
    AppConstants.jobStatusAccepted,
  ];

  /// Antelación mínima que exige la base para la nueva hora.
  static const Duration minimumLead = Duration(hours: 1);

  static bool canPropose({
    required String status,
    required DateTime? scheduledAt,
    required String? workerId,
    DateTime? now,
  }) {
    if (workerId == null || workerId.isEmpty || scheduledAt == null) {
      return false;
    }
    if (!reschedulableStatuses.contains(status)) return false;
    return scheduledAt.toUtc().isAfter((now ?? DateTime.now()).toUtc());
  }

  /// Horas libres que se pueden ofrecer: distintas a la actual y con margen.
  static List<DateTime> slotOptions(
    List<DateTime> freeSlots,
    DateTime? currentAt, {
    DateTime? now,
  }) {
    final minimum = (now ?? DateTime.now()).toUtc().add(minimumLead);
    final current = currentAt?.toUtc();
    return freeSlots
        .map((slot) => slot.toUtc())
        .where((slot) => slot.isAfter(minimum) && slot != current)
        .toList()
      ..sort();
  }

  static bool canRespond(RescheduleProposal? proposal, String? userId) =>
      proposal != null &&
      proposal.isPending &&
      userId != null &&
      proposal.proposedBy != userId;

  static String statusLabel(String status) {
    switch (status) {
      case 'pendiente':
        return 'Esperando respuesta';
      case 'aceptada':
        return 'Aceptada';
      case 'rechazada':
        return 'Rechazada';
      case 'retirada':
        return 'Retirada';
      case 'vencida':
        return 'Venció';
      default:
        return 'Sin estado';
    }
  }
}
