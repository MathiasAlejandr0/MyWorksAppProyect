import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'worker_service_options_catalog.dart';

/// Servicio adicional creado por el trabajador (fuera del catálogo base).
class WorkerCustomService {
  const WorkerCustomService({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.priceClp,
    this.unit = WorkerPriceUnit.fixed,
  });

  final String id;
  final String title;
  final String subtitle;
  final int priceClp;
  final WorkerPriceUnit unit;

  factory WorkerCustomService.create({
    required String title,
    required String subtitle,
    required int priceClp,
    WorkerPriceUnit unit = WorkerPriceUnit.fixed,
  }) {
    return WorkerCustomService(
      id: 'custom_${const Uuid().v4().substring(0, 8)}',
      title: title,
      subtitle: subtitle,
      priceClp: priceClp,
      unit: unit,
    );
  }

  factory WorkerCustomService.fromMap(Map<String, dynamic> map) {
    final unitRaw = map['unit'] as String? ?? 'fixed';
    return WorkerCustomService(
      id: map['id'] as String,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String? ?? '',
      priceClp: (map['priceClp'] as num).toInt(),
      unit: unitRaw == 'perSqm' ? WorkerPriceUnit.perSqm : WorkerPriceUnit.fixed,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'priceClp': priceClp,
        'unit': unit == WorkerPriceUnit.perSqm ? 'perSqm' : 'fixed',
      };

  WorkerCustomService copyWith({
    String? title,
    String? subtitle,
    int? priceClp,
    WorkerPriceUnit? unit,
  }) {
    return WorkerCustomService(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      priceClp: priceClp ?? this.priceClp,
      unit: unit ?? this.unit,
    );
  }

  WorkerServiceOptionDef toOptionDef() {
    return WorkerServiceOptionDef(
      id: id,
      title: title,
      subtitle: subtitle,
      icon: Icons.layers_outlined,
      defaultPriceClp: priceClp,
      unit: unit,
      isCustom: true,
    );
  }

  static List<WorkerCustomService> listFromJson(dynamic raw) {
    if (raw == null) return [];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((m) => WorkerCustomService.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }
}
