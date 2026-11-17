import '../../config/demo_credentials.dart';
import '../../domain/worker_hours.dart';
import '../../domain/worker_public_stats.dart';
import '../../domain/distance_match.dart';
import '../../domain/transport_surcharge.dart';
import '../../domain/user_location_context.dart';
import '../../domain/worker_service_options_catalog.dart';
import '../../domain/worker_login_item.dart';
import '../../services/worker_reputation_service.dart';
import '../../utils/worker_zone_matcher.dart';
import '../models/worker_model.dart';
import '../worker_stats_client.dart';
import '../supabase_db.dart';
import 'job_repository.dart';
import 'rating_repository.dart';

class WorkerRepository {
  static const String _table = 'trabajadores';

  /// Columnas que anon y authenticated pueden leer. La base exacta sale de
  /// `mi_ficha_propia`, solo para el dueño.
  static const String _baseColumns =
      'id_usuario, profesion, descripcion, calificacion, disponible, tarifa_visita, '
      'conteo_rechazos, precios_configurados, zona_trabajo, estado_verificacion, '
      'radio_servicio_km, origen_base, score_listado, radio_urbano_km, '
      'tarifa_fuera_radio_clp, trabajos_completados, es_elite';

  /// Precios, servicios propios y categoría viven en tablas hijas
  /// (`trabajador_precios`, `trabajador_servicios_extra`, `trabajador_servicios`).
  /// Con [byCategory] el embed de categorías pasa a `!inner` para poder filtrar.
  static String _selectColumns({bool byCategory = false}) =>
      '$_baseColumns, '
      'trabajador_precios(codigo, monto_clp), '
      'trabajador_servicios_extra(id, titulo, subtitulo, monto_clp, unidad), '
      'trabajador_servicios${byCategory ? '!inner' : ''}(categoria_servicio)';

  Future<void> createWorker(WorkerModel worker) async {
    await supabase.from(_table).upsert(worker.toMap());
    await _saveOffer(worker, includeCategory: true);
  }

  /// Guarda precios, servicios propios y categoría en sus tablas. Lo que ya
  /// no está en el modelo se borra, para que la base quede igual a la pantalla.
  Future<void> _saveOffer(
    WorkerModel worker, {
    bool includeCategory = false,
  }) async {
    final userId = worker.userId;
    if (worker.pricingTiers.isEmpty) {
      await supabase.from('trabajador_precios').delete().eq('id_usuario', userId);
    } else {
      await supabase.from('trabajador_precios').upsert(
        [
          for (final entry in worker.pricingTiers.entries)
            {
              'id_usuario': userId,
              'codigo': entry.key,
              'monto_clp': entry.value,
            },
        ],
        onConflict: 'id_usuario,codigo',
      );
      await supabase
          .from('trabajador_precios')
          .delete()
          .eq('id_usuario', userId)
          .not('codigo', 'in', '(${worker.pricingTiers.keys.join(',')})');
    }

    if (worker.customServices.isEmpty) {
      await supabase
          .from('trabajador_servicios_extra')
          .delete()
          .eq('id_usuario', userId);
    } else {
      await supabase.from('trabajador_servicios_extra').upsert(
        [
          for (final service in worker.customServices)
            {
              'id': service.id,
              'id_usuario': userId,
              'titulo': service.title,
              'subtitulo': service.subtitle,
              'monto_clp': service.priceClp,
              'unidad': service.unit == WorkerPriceUnit.perSqm ? 'por_m2' : 'fijo',
            },
        ],
        onConflict: 'id_usuario,id',
      );
      await supabase
          .from('trabajador_servicios_extra')
          .delete()
          .eq('id_usuario', userId)
          .not('id', 'in',
              '(${worker.customServices.map((s) => s.id).join(',')})');
    }

    if (includeCategory && worker.serviceCategory != 'general') {
      await supabase.from('trabajador_servicios').upsert(
        {
          'id_trabajador': userId,
          'categoria_servicio': worker.serviceCategory,
        },
        onConflict: 'id_trabajador,categoria_servicio',
      );
    }
  }

  Future<WorkerModel?> getWorkerByUserId(String userId) async {
    final row = await supabase
        .from(_table)
        .select(_selectColumns())
        .eq('id_usuario', userId)
        .maybeSingle();
    if (row == null) return null;
    var worker = WorkerModel.fromMap(row);
    if (supabase.auth.currentUser?.id == userId) {
      Map<String, dynamic>? ficha;
      try {
        ficha = _firstRow(await supabase.rpc('mi_ficha_propia'));
      } catch (_) {
        ficha = null;
      }
      final hours = await supabase.rpc('horarios_disponibles_propios');
      worker = worker.copyWith(
        baseLatitude: (ficha?['latitud_base'] as num?)?.toDouble(),
        baseLongitude: (ficha?['longitud_base'] as num?)?.toDouble(),
        availableHours: parseWorkerHours(hours),
      );
    } else {
      try {
        final base = _firstRow(
          await supabase.rpc(
            'base_publica_profesional',
            params: {'p_id': userId},
          ),
        );
        worker = worker.copyWith(
          baseLatitude: (base?['latitud_base'] as num?)?.toDouble(),
          baseLongitude: (base?['longitud_base'] as num?)?.toDouble(),
        );
      } catch (_) {}
    }
    final overlay = await _overlayStats([worker]);
    return overlay.first;
  }

  Map<String, dynamic>? _firstRow(dynamic raw) {
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      return Map<String, dynamic>.from(raw.first as Map);
    }
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  /// Nota y trabajos reales. Prefiere la RPC canónica; si aún no está
  /// desplegada, calcula lo mismo en el cliente.
  Future<WorkerPublicStats> getPublicStats(String userId) async {
    try {
      final row = _firstRow(
        await supabase.rpc('stats_profesional', params: {'p_id': userId}),
      );
      if (row != null) return WorkerPublicStats.fromMap(row);
    } catch (_) {}

    final ratings = await RatingRepository().getRatingsByWorkerId(userId);
    final counts = await JobRepository().countJobsByWorkerId(userId);
    final average = ratings.isEmpty
        ? null
        : ratings.fold<int>(0, (sum, r) => sum + r.score) / ratings.length;
    return WorkerPublicStats(
      averageRating: average,
      ratingCount: ratings.length,
      completedJobs: counts.completed,
      isElite: (average ?? 0) >= 4.7 && counts.completed >= 5,
    );
  }

  Future<List<WorkerModel>> _overlayStats(List<WorkerModel> workers) {
    return overlayWorkerPublicStats(workers);
  }

  /// Obtiene un trabajador por su ID (alias para getWorkerByUserId)
  Future<WorkerModel?> getWorkerById(String userId) async {
    return getWorkerByUserId(userId);
  }

  Future<List<WorkerModel>> getWorkersByServiceCategory(
    String category, {
    UserLocationContext? near,
  }) async {
    final workers = await _fetchCatalog(category: category);
    return _filterListedWorkers(workers, near: near);
  }

  /// Con GPS se usa la distancia real. Fuera del radio cercano se puede pedir
  /// con extra de traslado; más de 30 km se oculta. Sin GPS se compara la zona.
  static bool _servesLocation(WorkerModel worker, UserLocationContext near) {
    final lat = near.latitude;
    final lng = near.longitude;
    if (lat != null && lng != null) {
      final match = matchByDistance(
        workerLat: worker.baseLatitude,
        workerLng: worker.baseLongitude,
        jobLat: lat,
        jobLng: lng,
        radiusKm: worker.serviceRadiusKm,
      );
      if (match != null) return withinTravelRange(match.distanceKm);
    }
    final zone = worker.workZone;
    if (zone == null || zone.isEmpty) return true;
    return WorkerZoneMatcher.serves(workZone: zone, userLocation: near);
  }

  /// Solo trabajadores disponibles y ordenados por reputación
  Future<List<WorkerModel>> _filterListedWorkers(
    List<WorkerModel> workers, {
    UserLocationContext? near,
  }) async {
    if (workers.isEmpty) return [];

    final jobRepository = JobRepository();
    final busyIds = await jobRepository.getBusyWorkerIds(
      workers.map((w) => w.userId).toList(),
    );
    final listed = <WorkerModel>[];
    for (final worker in workers) {
      if (!worker.isAvailable) continue;
      if (busyIds.contains(worker.userId)) continue;
      if (near != null && !_servesLocation(worker, near)) continue;
      listed.add(worker);
    }

    WorkerReputationService.instance.sortForListing(
      listed,
      clientLatitude: near?.latitude,
      clientLongitude: near?.longitude,
    );
    return listed;
  }

  Future<List<WorkerModel>> getWorkersByProfession(String profession) async {
    final catalog = await _fetchCatalog();
    final needle = profession.trim().toLowerCase();
    final workers = catalog
        .where((worker) => worker.profession.trim().toLowerCase() == needle)
        .toList();
    WorkerReputationService.instance.sortForListing(workers);
    return workers;
  }

  Future<List<WorkerModel>> getAllAvailableWorkers() async {
    final workers = await _fetchCatalog();
    WorkerReputationService.instance.sortForListing(workers);
    return workers;
  }

  /// Lista local de la demo. La RPC ya no es ejecutable por anon.
  Future<List<WorkerLoginItem>> getWorkersForLogin() async {
    return sortWorkerLoginItems(DemoCredentials.loginWorkers);
  }

  Future<void> updateWorker(WorkerModel worker) async {
    await supabase
        .from(_table)
        .update(worker.toMap())
        .eq('id_usuario', worker.userId);
    await _saveOffer(worker);
  }

  Future<void> updateAvailableHours({
    required String userId,
    required List<WorkerHourSlot> hours,
  }) async {
    if (supabase.auth.currentUser?.id != userId) {
      throw StateError('solo puedes editar tu propia agenda');
    }
    final slots = uniqueWorkerHours(hours)
        .map((slot) => slot.toJson())
        .toList();
    // Las horas publicadas viven en `trabajador_horas_publicadas`; la RPC
    // reemplaza las del profesional y deja sus 7 ventanas por día intactas.
    await supabase.rpc('guardar_horarios_propios', params: {'p_horarios': slots});
  }

  Future<List<DateTime>> fetchFreeSlots(String workerId) async {
    final rows = await supabase.rpc(
      'horarios_libres_profesional',
      params: {'p_id_trabajador': workerId, 'p_dias': 14},
    );
    if (rows is! List) return const [];
    final slots = <DateTime>[];
    final seen = <String>{};
    for (final raw in rows) {
      final value = raw is Map ? raw['inicio'] : raw;
      if (value == null) continue;
      final parsed = DateTime.tryParse(value.toString());
      if (parsed == null) continue;
      final utc = parsed.toUtc();
      final key = utc.toIso8601String().substring(0, 16);
      if (!seen.add(key)) continue;
      slots.add(utc);
    }
    slots.sort();
    return slots;
  }

  Future<({String status, String? note})?> fetchVerification(
    String userId,
  ) async {
    try {
      final row = await supabase
          .from(_table)
          .select('estado_verificacion')
          .eq('id_usuario', userId)
          .maybeSingle();
      if (row == null) return null;
      String? rawNote;
      if (supabase.auth.currentUser?.id == userId) {
        rawNote =
            _firstRow(
                  await supabase.rpc('mi_ficha_propia'),
                )?['nota_verificacion']
                as String?;
      }
      final visibleNote = rawNote?.split('\nDocumento:').first.trim();
      return (
        status: row['estado_verificacion'] as String? ?? 'pendiente',
        note: visibleNote,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> submitVerificationReview({
    required String userId,
    required String note,
  }) async {
    await supabase.rpc(
      'enviar_verificacion_profesional',
      params: {'p_nota': note},
    );
  }

  Future<void> updateBaseLocation({
    required String userId,
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    await supabase
        .from(_table)
        .update({
          'latitud_base': latitude,
          'longitud_base': longitude,
          'radio_servicio_km': radiusKm,
          'origen_base': 'mapa',
        })
        .eq('id_usuario', userId);
  }

  Future<void> updateUrbanCoverage({
    required String userId,
    required double urbanRadiusKm,
    required int outsideFeeClp,
  }) async {
    await supabase
        .from(_table)
        .update({
          'radio_urbano_km': urbanRadiusKm,
          'tarifa_fuera_radio_clp': outsideFeeClp,
        })
        .eq('id_usuario', userId);
  }

  Future<void> updateAvailability(String userId, bool isAvailable) async {
    await supabase
        .from(_table)
        .update({'disponible': isAvailable ? 1 : 0})
        .eq('id_usuario', userId);
  }

  /// Disponible para nuevos trabajos: flag activo y sin trabajos en curso.
  Future<bool> isWorkerAcceptingJobs(String userId) async {
    final worker = await getWorkerByUserId(userId);
    if (worker == null || !worker.isAvailable) return false;
    final jobRepository = JobRepository();
    return !await jobRepository.hasActiveJobs(userId);
  }

  /// Mantiene al trabajador como no disponible mientras tenga trabajos activos.
  /// La base marca esa pausa (`pausa_por_trabajo`) y la levanta sola cuando
  /// termina el último trabajo activo (trigger
  /// `trabajos_restablecer_disponibilidad`), también para cuentas reales.
  Future<void> enforceUnavailableWhileBusy(String userId) async {
    final jobRepository = JobRepository();
    if (!await jobRepository.hasActiveJobs(userId)) return;

    final worker = await getWorkerByUserId(userId);
    if (worker != null && worker.isAvailable) {
      await updateAvailability(userId, false);
    }
  }

  /// Si no está en un trabajo en curso, las cuentas demo vuelven al catálogo
  /// aunque las hayan pausado a mano. Las cuentas reales vuelven solas desde
  /// la base al terminar el trabajo; una pausa voluntaria se respeta.
  Future<void> syncAvailabilityWithJobs(String userId, {String? email}) async {
    final jobRepository = JobRepository();
    if (await jobRepository.hasActiveJobs(userId)) {
      await enforceUnavailableWhileBusy(userId);
      return;
    }
    if (email == null || !DemoCredentials.isDemoEmail(email)) {
      return;
    }
    final worker = await getWorkerByUserId(userId);
    if (worker != null && !worker.isAvailable) {
      await updateAvailability(userId, true);
    }
  }

  // Obtener trabajadores disponibles que no tienen trabajos activos
  Future<List<WorkerModel>> getAvailableWorkersWithoutActiveJobs({
    UserLocationContext? near,
  }) async {
    final allWorkers = await _fetchCatalog();
    return _filterListedWorkers(allWorkers, near: near);
  }

  /// Misma fuente que la web: RPC pública, no el REST de `trabajadores`.
  Future<List<WorkerModel>> _fetchCatalog({String? category}) async {
    final categoria = category?.trim();
    try {
      final rows = await supabase.rpc(
        'listar_profesionales_catalogo',
        params: {
          'p_categoria': (categoria == null || categoria.isEmpty)
              ? null
              : categoria,
          'p_limit': 40,
        },
      );
      if (rows is List) {
        return await _overlayStats([
          for (final row in rows.whereType<Map>())
            WorkerModel.fromCatalogMap(Map<String, dynamic>.from(row)),
        ]);
      }
    } catch (_) {
      // Si la RPC no está, un autenticado todavía puede leer el marketplace.
    }
    try {
      final byCategory = categoria != null && categoria.isNotEmpty;
      var query = supabase
          .from(_table)
          .select(_selectColumns(byCategory: byCategory))
          .eq('disponible', 1)
          .eq('precios_configurados', 1)
          .eq('estado_verificacion', 'verificado');
      if (byCategory) {
        query = query.eq('trabajador_servicios.categoria_servicio', categoria);
      }
      final rows = await query
          .order('score_listado', ascending: false)
          .limit(40);
      return await _overlayStats(
        rows.map<WorkerModel>((row) => WorkerModel.fromMap(row)).toList(),
      );
    } catch (_) {
      return const [];
    }
  }

  /// Indica si el trabajador tiene trabajos activos (para badge «ocupado»).
  Future<bool> hasActiveJobs(String userId) async {
    final jobRepository = JobRepository();
    return jobRepository.hasActiveJobs(userId);
  }
}
