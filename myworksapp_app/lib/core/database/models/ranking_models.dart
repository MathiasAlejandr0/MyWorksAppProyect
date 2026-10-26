class RankingConfig {
  const RankingConfig({
    this.pesoCalificacion = 0.32,
    this.pesoCompletados = 0.18,
    this.pesoRechazos = 0.12,
    this.pesoVerificacion = 0.10,
    this.pesoImpulso = 0.08,
    this.pesoRecencia = 0.08,
    this.pesoConfianza = 0.12,
    this.priorBayes = 3.80,
    this.nBayes = 8,
    this.umbralRevision = 0.55,
    this.umbralAutoExcluir = 0.90,
    this.aprendizajeActivo = true,
    this.tasaAprendizaje = 0.15,
    this.pesosSenal = const {},
    this.actualizadoEn,
  });

  final double pesoCalificacion;
  final double pesoCompletados;
  final double pesoRechazos;
  final double pesoVerificacion;
  final double pesoImpulso;
  final double pesoRecencia;
  final double pesoConfianza;
  final double priorBayes;
  final double nBayes;
  final double umbralRevision;
  final double umbralAutoExcluir;
  final bool aprendizajeActivo;
  final double tasaAprendizaje;
  final Map<String, double> pesosSenal;
  final DateTime? actualizadoEn;

  factory RankingConfig.fromMap(Map<String, dynamic> map) {
    return RankingConfig(
      pesoCalificacion: _n(map['peso_calificacion'], 0.32),
      pesoCompletados: _n(map['peso_completados'], 0.18),
      pesoRechazos: _n(map['peso_rechazos'], 0.12),
      pesoVerificacion: _n(map['peso_verificacion'], 0.10),
      pesoImpulso: _n(map['peso_impulso'], 0.08),
      pesoRecencia: _n(map['peso_recencia'], 0.08),
      pesoConfianza: _n(map['peso_confianza'], 0.12),
      priorBayes: _n(map['prior_bayes'], 3.80),
      nBayes: _n(map['n_bayes'], 8),
      umbralRevision: _n(map['umbral_revision'], 0.55),
      umbralAutoExcluir: _n(map['umbral_auto_excluir'], 0.90),
      aprendizajeActivo: map['aprendizaje_activo'] != 0 &&
          map['aprendizaje_activo'] != false &&
          map['aprendizaje_activo'] != '0',
      tasaAprendizaje: _n(map['tasa_aprendizaje'], 0.15),
      pesosSenal: _mapNum(map['pesos_senal']),
      actualizadoEn: _date(map['actualizado_en']),
    );
  }

  Map<String, dynamic> toRpcMap() {
    return {
      'peso_calificacion': pesoCalificacion,
      'peso_completados': pesoCompletados,
      'peso_rechazos': pesoRechazos,
      'peso_verificacion': pesoVerificacion,
      'peso_impulso': pesoImpulso,
      'peso_recencia': pesoRecencia,
      'peso_confianza': pesoConfianza,
      'prior_bayes': priorBayes,
      'n_bayes': nBayes,
      'umbral_revision': umbralRevision,
      'umbral_auto_excluir': umbralAutoExcluir,
      'aprendizaje_activo': aprendizajeActivo ? 1 : 0,
      'tasa_aprendizaje': tasaAprendizaje,
      if (pesosSenal.isNotEmpty) 'pesos_senal': pesosSenal,
    };
  }

  RankingConfig copyWith({
    double? pesoCalificacion,
    double? pesoCompletados,
    double? pesoRechazos,
    double? pesoVerificacion,
    double? pesoImpulso,
    double? pesoRecencia,
    double? pesoConfianza,
    double? priorBayes,
    double? nBayes,
    double? umbralRevision,
    double? umbralAutoExcluir,
    bool? aprendizajeActivo,
    double? tasaAprendizaje,
    Map<String, double>? pesosSenal,
  }) {
    return RankingConfig(
      pesoCalificacion: pesoCalificacion ?? this.pesoCalificacion,
      pesoCompletados: pesoCompletados ?? this.pesoCompletados,
      pesoRechazos: pesoRechazos ?? this.pesoRechazos,
      pesoVerificacion: pesoVerificacion ?? this.pesoVerificacion,
      pesoImpulso: pesoImpulso ?? this.pesoImpulso,
      pesoRecencia: pesoRecencia ?? this.pesoRecencia,
      pesoConfianza: pesoConfianza ?? this.pesoConfianza,
      priorBayes: priorBayes ?? this.priorBayes,
      nBayes: nBayes ?? this.nBayes,
      umbralRevision: umbralRevision ?? this.umbralRevision,
      umbralAutoExcluir: umbralAutoExcluir ?? this.umbralAutoExcluir,
      aprendizajeActivo: aprendizajeActivo ?? this.aprendizajeActivo,
      tasaAprendizaje: tasaAprendizaje ?? this.tasaAprendizaje,
      pesosSenal: pesosSenal ?? this.pesosSenal,
      actualizadoEn: actualizadoEn,
    );
  }

  static double _n(dynamic raw, double fallback) {
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw) ?? fallback;
    return fallback;
  }

  static Map<String, double> _mapNum(dynamic raw) {
    if (raw is! Map) return {};
    return raw.map(
      (key, value) => MapEntry(key.toString(), _n(value, 0)),
    );
  }

  static DateTime? _date(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    return null;
  }
}

class ReviewSignal {
  const ReviewSignal({
    required this.id,
    required this.ratingId,
    required this.signalType,
    required this.score,
    required this.status,
    required this.createdAt,
    this.detail,
    this.reviewScore,
    this.comment,
    this.reviewStatus,
    this.confidence,
    this.jobId,
    this.workerId,
    this.workerName,
    this.clientName,
  });

  final String id;
  final String ratingId;
  final String signalType;
  final double score;
  final String status;
  final DateTime createdAt;
  final String? detail;
  final int? reviewScore;
  final String? comment;
  final String? reviewStatus;
  final double? confidence;
  final String? jobId;
  final String? workerId;
  final String? workerName;
  final String? clientName;

  factory ReviewSignal.fromMap(Map<String, dynamic> map) {
    return ReviewSignal(
      id: map['id'] as String,
      ratingId: map['id_calificacion'] as String,
      signalType: map['tipo_senal'] as String,
      score: (map['puntaje'] as num?)?.toDouble() ?? 0,
      status: map['estado'] as String? ?? 'pendiente',
      createdAt: DateTime.tryParse('${map['creado_en']}') ?? DateTime.now(),
      detail: map['detalle'] as String?,
      reviewScore: (map['puntaje_resena'] as num?)?.toInt(),
      comment: map['comentario'] as String?,
      reviewStatus: map['estado_revision'] as String?,
      confidence: (map['peso_confianza'] as num?)?.toDouble(),
      jobId: map['id_trabajo'] as String?,
      workerId: map['id_trabajador'] as String?,
      workerName: map['nombre_trabajador'] as String?,
      clientName: map['nombre_cliente'] as String?,
    );
  }

  String get signalLabel {
    switch (signalType) {
      case 'auto_resena':
        return 'Auto-reseña';
      case 'sin_trabajo_valido':
        return 'Sin trabajo válido';
      case 'rafaga':
        return 'Ráfaga de reseñas';
      case 'cuenta_nueva':
        return 'Cuenta nueva';
      case 'texto_vacio_extremo':
        return 'Nota extrema sin texto';
      case 'duplicado_texto':
        return 'Texto duplicado';
      case 'outlier':
        return 'Fuera de patrón';
      case 'granja_cinco_estrellas':
        return 'Granja de 5 estrellas';
      default:
        return signalType;
    }
  }
}
