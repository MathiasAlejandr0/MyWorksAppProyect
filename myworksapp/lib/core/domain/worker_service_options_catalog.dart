import 'package:flutter/material.dart';

import '../database/models/service_model.dart';
import '../database/models/worker_model.dart';

enum WorkerPriceUnit { fixed, perSqm }

/// Opción de trabajo con tarifa definida por el profesional.
class WorkerServiceOptionDef {
  const WorkerServiceOptionDef({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.defaultPriceClp,
    this.unit = WorkerPriceUnit.fixed,
    this.isCustom = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final int defaultPriceClp;
  final WorkerPriceUnit unit;
  final bool isCustom;

  String priceLabel(int priceClp) {
    final formatted = _formatClp(priceClp);
    if (unit == WorkerPriceUnit.perSqm) return '$formatted/m²';
    return formatted;
  }

  static String _formatClp(int value) {
    final s = value.toString();
    if (s.length <= 3) return '\$$s';
    final buf = StringBuffer('\$');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

/// Catálogo de trabajos posibles según el oficio.
class WorkerServiceOptionsCatalog {
  WorkerServiceOptionsCatalog._();

  static List<WorkerServiceOptionDef> optionsFor(String? category) {
    switch (category) {
      case ServiceCategories.assembly:
        return const [
          WorkerServiceOptionDef(
            id: 'small_furniture',
            title: 'Muebles pequeños',
            subtitle: 'Silla, mesa auxiliar, repisa, buró',
            icon: Icons.chair_outlined,
            defaultPriceClp: 25000,
          ),
          WorkerServiceOptionDef(
            id: 'medium_furniture',
            title: 'Muebles medianos',
            subtitle: 'Escritorio, estantería, cama, cómoda',
            icon: Icons.weekend_outlined,
            defaultPriceClp: 45000,
          ),
          WorkerServiceOptionDef(
            id: 'large_furniture',
            title: 'Muebles grandes',
            subtitle: 'Clóset, rack, cocina modular, walk-in',
            icon: Icons.king_bed_outlined,
            defaultPriceClp: 75000,
          ),
        ];
      case ServiceCategories.gardening:
        return const [
          WorkerServiceOptionDef(
            id: 'garden_small',
            title: 'Jardín pequeño',
            subtitle: 'Hasta 30 m² — poda, césped o limpieza',
            icon: Icons.yard_outlined,
            defaultPriceClp: 35000,
          ),
          WorkerServiceOptionDef(
            id: 'garden_medium',
            title: 'Jardín mediano',
            subtitle: '31 a 80 m² — mantención completa',
            icon: Icons.grass_outlined,
            defaultPriceClp: 65000,
          ),
          WorkerServiceOptionDef(
            id: 'garden_large',
            title: 'Jardín grande',
            subtitle: 'Más de 80 m² — poda, riego y limpieza',
            icon: Icons.park_outlined,
            defaultPriceClp: 95000,
          ),
        ];
      case ServiceCategories.cleaning:
        return const [
          WorkerServiceOptionDef(
            id: 'cleaning_one_room',
            title: 'Un ambiente',
            subtitle: 'Dormitorio, baño u oficina pequeña',
            icon: Icons.cleaning_services_outlined,
            defaultPriceClp: 22000,
          ),
          WorkerServiceOptionDef(
            id: 'cleaning_apartment',
            title: 'Departamento completo',
            subtitle: 'Limpieza estándar del hogar',
            icon: Icons.home_outlined,
            defaultPriceClp: 45000,
          ),
          WorkerServiceOptionDef(
            id: 'cleaning_deep',
            title: 'Limpieza profunda',
            subtitle: 'Post-obra, mudanza o fin de arriendo',
            icon: Icons.auto_awesome_outlined,
            defaultPriceClp: 65000,
          ),
        ];
      case ServiceCategories.plumbing:
        return const [
          WorkerServiceOptionDef(
            id: 'plumbing_minor',
            title: 'Arreglo menor',
            subtitle: 'Grifo, sifón, llave de paso, WC',
            icon: Icons.plumbing_outlined,
            defaultPriceClp: 28000,
          ),
          WorkerServiceOptionDef(
            id: 'plumbing_install',
            title: 'Instalación estándar',
            subtitle: 'Calefón, lavatorio, artefactos nuevos',
            icon: Icons.water_drop_outlined,
            defaultPriceClp: 48000,
          ),
          WorkerServiceOptionDef(
            id: 'plumbing_project',
            title: 'Proyecto o remodelación',
            subtitle: 'Baño completo, red de agua, varias piezas',
            icon: Icons.bathtub_outlined,
            defaultPriceClp: 90000,
          ),
        ];
      case ServiceCategories.electrical:
        return const [
          WorkerServiceOptionDef(
            id: 'electrical_point',
            title: 'Punto eléctrico',
            subtitle: 'Enchufe, interruptor o luminaria',
            icon: Icons.power_outlined,
            defaultPriceClp: 24000,
          ),
          WorkerServiceOptionDef(
            id: 'electrical_multiple',
            title: 'Varios puntos',
            subtitle: 'Tablero pequeño, varias luminarias',
            icon: Icons.electrical_services_outlined,
            defaultPriceClp: 48000,
          ),
          WorkerServiceOptionDef(
            id: 'electrical_major',
            title: 'Instalación mayor',
            subtitle: 'Cableado, tablero nuevo, ampliación',
            icon: Icons.bolt_outlined,
            defaultPriceClp: 85000,
          ),
          WorkerServiceOptionDef(
            id: 'electrical_per_sqm',
            title: 'Cobro por metro cuadrado',
            subtitle: 'Tarifa para proyectos grandes eléctricos',
            icon: Icons.square_foot_outlined,
            defaultPriceClp: 18000,
            unit: WorkerPriceUnit.perSqm,
          ),
        ];
      case ServiceCategories.construction:
        return const [
          WorkerServiceOptionDef(
            id: 'construction_patch',
            title: 'Reparación puntual',
            subtitle: 'Filtración, muro, cerámica suelta',
            icon: Icons.build_outlined,
            defaultPriceClp: 38000,
          ),
          WorkerServiceOptionDef(
            id: 'construction_half_day',
            title: 'Medio día de obra',
            subtitle: 'Aprox. 4 horas de trabajo en terreno',
            icon: Icons.schedule_outlined,
            defaultPriceClp: 62000,
          ),
          WorkerServiceOptionDef(
            id: 'construction_project',
            title: 'Proyecto por etapas',
            subtitle: 'Ampliación, remodelación u obra gruesa',
            icon: Icons.architecture_outlined,
            defaultPriceClp: 120000,
          ),
          WorkerServiceOptionDef(
            id: 'construction_per_sqm',
            title: 'Cobro por metro cuadrado',
            subtitle: 'Tarifa para proyectos grandes de construcción',
            icon: Icons.square_foot_outlined,
            defaultPriceClp: 45000,
            unit: WorkerPriceUnit.perSqm,
          ),
        ];
      case ServiceCategories.techSupport:
        return const [
          WorkerServiceOptionDef(
            id: 'tech_single',
            title: 'Un equipo',
            subtitle: 'PC, notebook, impresora o router',
            icon: Icons.computer_outlined,
            defaultPriceClp: 25000,
          ),
          WorkerServiceOptionDef(
            id: 'tech_multi',
            title: 'Varios equipos',
            subtitle: 'Formateo, respaldo u optimización',
            icon: Icons.devices_outlined,
            defaultPriceClp: 45000,
          ),
          WorkerServiceOptionDef(
            id: 'tech_network',
            title: 'Red u oficina pequeña',
            subtitle: 'Wi-Fi, cableado, varios puestos',
            icon: Icons.lan_outlined,
            defaultPriceClp: 70000,
          ),
        ];
      case ServiceCategories.moving:
        return const [
          WorkerServiceOptionDef(
            id: 'moving_few',
            title: 'Muebles o pocos bultos',
            subtitle: 'Traslado puntual dentro de la ciudad',
            icon: Icons.local_shipping_outlined,
            defaultPriceClp: 35000,
          ),
          WorkerServiceOptionDef(
            id: 'moving_apartment',
            title: 'Departamento',
            subtitle: 'Mudanza estándar con carga y descarga',
            icon: Icons.apartment_outlined,
            defaultPriceClp: 85000,
          ),
          WorkerServiceOptionDef(
            id: 'moving_house',
            title: 'Casa completa',
            subtitle: 'Mudanza grande con embalaje básico',
            icon: Icons.house_outlined,
            defaultPriceClp: 150000,
          ),
        ];
      default:
        return const [
          WorkerServiceOptionDef(
            id: 'service_basic',
            title: 'Trabajo básico',
            subtitle: 'Tarea acotada o de poca duración',
            icon: Icons.handyman_outlined,
            defaultPriceClp: 30000,
          ),
          WorkerServiceOptionDef(
            id: 'service_standard',
            title: 'Trabajo estándar',
            subtitle: 'Servicio de complejidad media',
            icon: Icons.construction_outlined,
            defaultPriceClp: 50000,
          ),
          WorkerServiceOptionDef(
            id: 'service_premium',
            title: 'Trabajo complejo',
            subtitle: 'Proyecto extenso o especializado',
            icon: Icons.star_outline,
            defaultPriceClp: 80000,
          ),
        ];
    }
  }

  static Map<String, int> defaultTiersFor(String? category) {
    return {
      for (final o in optionsFor(category)) o.id: o.defaultPriceClp,
    };
  }

  static int priceFor({
    required Map<String, int> workerTiers,
    required WorkerServiceOptionDef option,
  }) =>
      workerTiers[option.id] ?? option.defaultPriceClp;

  /// Opciones visibles al cliente (sin la tarifa interna por m²).
  static List<WorkerServiceOptionDef> catalogOptionsFor(String? category) {
    return optionsFor(category)
        .where((o) => !_workerOnlyPerSqmTierIds.contains(o.id))
        .toList();
  }

  /// Tarifas que edita el trabajador (incluye cobro por m²).
  static List<WorkerServiceOptionDef> pricingOptionsFor(String? category) =>
      optionsFor(category);

  static const _workerOnlyPerSqmTierIds = {
    'construction_per_sqm',
    'electrical_per_sqm',
  };

  static const _largeProjectClientOptionIds = {
    'construction_large_project',
    'electrical_large_project',
  };

  /// Opción «Proyecto grande» que ve el cliente (usa tarifa per_sqm del trabajador).
  static WorkerServiceOptionDef? largeProjectClientOption(String? category) {
    switch (category) {
      case ServiceCategories.construction:
        return const WorkerServiceOptionDef(
          id: 'construction_large_project',
          title: 'Proyecto grande',
          subtitle: 'Indica los m² a construir; se calcula según la tarifa del maestro',
          icon: Icons.domain_outlined,
          defaultPriceClp: 45000,
          unit: WorkerPriceUnit.perSqm,
        );
      case ServiceCategories.electrical:
        return const WorkerServiceOptionDef(
          id: 'electrical_large_project',
          title: 'Proyecto grande',
          subtitle: 'Indica los m² del proyecto; se calcula según la tarifa del electricista',
          icon: Icons.domain_outlined,
          defaultPriceClp: 18000,
          unit: WorkerPriceUnit.perSqm,
        );
      default:
        return null;
    }
  }

  static String? perSqmTierIdForCategory(String? category) {
    switch (category) {
      case ServiceCategories.construction:
        return 'construction_per_sqm';
      case ServiceCategories.electrical:
        return 'electrical_per_sqm';
      default:
        return null;
    }
  }

  static List<WorkerServiceOptionDef> clientOptionsFor(WorkerModel worker) {
    final items = <WorkerServiceOptionDef>[
      ...catalogOptionsFor(worker.serviceCategory),
    ];
    final large = largeProjectClientOption(worker.serviceCategory);
    if (large != null) items.add(large);
    return items;
  }

  static List<WorkerServiceOptionDef> customOptionsFor(WorkerModel worker) =>
      worker.customServices.map((s) => s.toOptionDef()).toList();

  static int priceForWorker({
    required WorkerModel worker,
    required WorkerServiceOptionDef option,
  }) {
    if (option.isCustom) {
      for (final custom in worker.customServices) {
        if (custom.id == option.id) return custom.priceClp;
      }
      return option.defaultPriceClp;
    }
    if (_largeProjectClientOptionIds.contains(option.id)) {
      final tierId = perSqmTierIdForCategory(worker.serviceCategory);
      final tierDef = tierId != null
          ? findOption(worker.serviceCategory, tierId)
          : null;
      if (tierId != null && tierDef != null) {
        return worker.pricingTiers[tierId] ?? tierDef.defaultPriceClp;
      }
    }
    return priceFor(workerTiers: worker.pricingTiers, option: option);
  }

  /// Tarifa unitaria (fija o CLP/m²).
  static int unitPriceForWorker({
    required WorkerModel worker,
    required WorkerServiceOptionDef option,
  }) =>
      priceForWorker(worker: worker, option: option);

  /// Total a cobrar; para opciones por m² multiplica por [squareMeters].
  static int totalPriceForWorker({
    required WorkerModel worker,
    required WorkerServiceOptionDef option,
    int? squareMeters,
  }) {
    final unitPrice = unitPriceForWorker(worker: worker, option: option);
    if (requiresSquareMeters(option)) {
      final m2 = squareMeters ?? 0;
      if (m2 <= 0) return unitPrice;
      return unitPrice * m2;
    }
    return unitPrice;
  }

  static bool requiresSquareMeters(WorkerServiceOptionDef option) =>
      _largeProjectClientOptionIds.contains(option.id);

  static bool categorySupportsLargeProjects(String? category) =>
      category == ServiceCategories.construction ||
      category == ServiceCategories.electrical;

  static WorkerServiceOptionDef? findOption(String? category, String optionId) {
    for (final o in optionsFor(category)) {
      if (o.id == optionId) return o;
    }
    if (_largeProjectClientOptionIds.contains(optionId)) {
      return largeProjectClientOption(category);
    }
    return null;
  }

  static WorkerServiceOptionDef? findOptionForWorker(
    WorkerModel worker,
    String optionId,
  ) {
    if (_largeProjectClientOptionIds.contains(optionId)) {
      return largeProjectClientOption(worker.serviceCategory);
    }
    final catalog = findOption(worker.serviceCategory, optionId);
    if (catalog != null) return catalog;
    for (final custom in worker.customServices) {
      if (custom.id == optionId) return custom.toOptionDef();
    }
    return null;
  }
}
