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
  final String category; // 'construction', 'plumbing', 'cleaning', 'assembly', 'tech_support', 'gardening', 'moving'
  final bool isActive;
  final bool requiresCertification; // false para servicios no regulados
  final String pricingModel; // 'hourly', 'fixed', 'per_item'
  final String? legalDisclaimer; // Descargo de responsabilidad específico
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
      'name': name,
      'description': description,
      'category': category,
      'isActive': isActive ? 1 : 0,
      'requiresCertification': requiresCertification ? 1 : 0,
      'pricingModel': pricingModel,
      'legalDisclaimer': legalDisclaimer,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      category: map['category'] as String? ?? 'general',
      isActive: (map['isActive'] as int? ?? 1) == 1,
      requiresCertification: (map['requiresCertification'] as int? ?? 0) == 1,
      pricingModel: map['pricingModel'] as String? ?? 'hourly',
      legalDisclaimer: map['legalDisclaimer'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
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
  static const String construction = 'construction';
  static const String plumbing = 'plumbing';
  static const String electrical = 'electrical';
  static const String cleaning = 'cleaning';
  static const String assembly = 'assembly';
  static const String techSupport = 'tech_support';
  static const String gardening = 'gardening';
  static const String moving = 'moving';
}

/// Modelos de pricing
class PricingModels {
  static const String hourly = 'hourly';
  static const String fixed = 'fixed';
  static const String perItem = 'per_item';
}
