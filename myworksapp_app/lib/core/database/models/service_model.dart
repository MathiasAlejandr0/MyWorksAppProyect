/// Modelo para servicios
/// 
/// Extendido para soportar:
/// - Categorías
/// - Modelos de pricing
/// - Validaciones legales
/// - Estado activo/inactivo
class ServiceModel {
  final String id;
  final String name;
  final String? description;
  final String category;
  final bool isActive;
  final bool requiresCertification;
  final String pricingModel; // por_hora | fijo | por_item
  final String? legalDisclaimer;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceModel({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    this.isActive = true,
    this.requiresCertification = false,
    required this.pricingModel,
    this.legalDisclaimer,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': name,
      'descripcion': description,
      'categoria': category,
      'activo': isActive ? 1 : 0,
      'requiere_certificacion': requiresCertification ? 1 : 0,
      'modelo_precio': pricingModel,
      'aviso_legal': legalDisclaimer,
      'creado_en': createdAt.toIso8601String(),
      'actualizado_en': updatedAt.toIso8601String(),
    };
  }

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] as String,
      name: map['nombre'] as String,
      description: map['descripcion'] as String?,
      category: map['categoria'] as String? ?? 'general',
      isActive: (map['activo'] as int? ?? 1) == 1,
      requiresCertification: (map['requiere_certificacion'] as int? ?? 0) == 1,
      pricingModel: map['modelo_precio'] as String? ?? 'por_hora',
      legalDisclaimer: map['aviso_legal'] as String?,
      createdAt: map['creado_en'] != null
          ? DateTime.parse(map['creado_en'] as String)
          : DateTime.now(),
      updatedAt: map['actualizado_en'] != null
          ? DateTime.parse(map['actualizado_en'] as String)
          : DateTime.now(),
    );
  }

  ServiceModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    bool? isActive,
    bool? requiresCertification,
    String? pricingModel,
    String? legalDisclaimer,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      requiresCertification: requiresCertification ?? this.requiresCertification,
      pricingModel: pricingModel ?? this.pricingModel,
      legalDisclaimer: legalDisclaimer ?? this.legalDisclaimer,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Categorías de servicios
class ServiceCategories {
  static const String construction = 'construccion';
  static const String plumbing = 'plomeria';
  static const String electrical = 'electricidad';
  static const String cleaning = 'limpieza';
  static const String assembly = 'ensamblaje';
  static const String techSupport = 'soporte_tecnico';
  static const String gardening = 'jardinera';
  static const String moving = 'mudanza';
}

/// Modelos de pricing
class PricingModels {
  static const String hourly = 'por_hora';
  static const String fixed = 'fijo';
  static const String perItem = 'por_item';
}
