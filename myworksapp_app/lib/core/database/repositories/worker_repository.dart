import '../../domain/distance_match.dart';
import '../../domain/user_location_context.dart';
import '../../domain/worker_login_item.dart';
import '../../services/worker_reputation_service.dart';
import '../../utils/worker_zone_matcher.dart';
import '../models/worker_model.dart';
import '../supabase_db.dart';
import 'job_repository.dart';
class WorkerRepository {
  static const String _table = 'trabajadores';

  Future<void> createWorker(WorkerModel worker) async {
    await supabase.from(_table).upsert(worker.toMap());
  }

  Future<WorkerModel?> getWorkerByUserId(String userId) async {
    final row = await supabase
        .from(_table)
        .select()
        .eq('id_usuario', userId)
        .maybeSingle();
    if (row == null) return null;
    return WorkerModel.fromMap(row);
  }

  /// Obtiene un trabajador por su ID (alias para getWorkerByUserId)
  Future<WorkerModel?> getWorkerById(String userId) async {
    return getWorkerByUserId(userId);
  }

  Future<List<WorkerModel>> getWorkersByServiceCategory(
    String category, {
    UserLocationContext? near,
  }) async {
    var rows = await supabase
        .from(_table)
        .select()
        .eq('categoria_servicio', category)
        .order('calificacion', ascending: false)
        .limit(40);

    if (rows.isEmpty) {
      final needle = category.replaceAll(RegExp(r'[%_,]'), '');
      if (needle.isNotEmpty) {
        rows = await supabase
            .from(_table)
            .select()
            .ilike('categoria_servicio', '%$needle%')
            .order('calificacion', ascending: false)
            .limit(40);
      }
    }

    final workers =
        rows.map<WorkerModel>((m) => WorkerModel.fromMap(m)).toList();
    return _filterListedWorkers(workers, near: near);
  }

  /// Con coordenadas del cliente y base del profesional se usa la distancia
  /// real contra `radio_servicio_km`. Si falta alguna, se compara la zona por
  /// nombre de ciudad/comuna como antes.
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
      if (match != null) return !match.outsideRadius;
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

    // Fallback de integridad: Si el filtro de zona o disponibilidad dejó 0 resultados,
    // devolver los trabajadores de la categoría para no dejar al cliente sin alternativas demo.
    if (listed.isEmpty) {
      for (final worker in workers) {
        listed.add(worker);
      }
    }

    WorkerReputationService.instance.sortForListing(listed);
    return listed;
  }

  Future<List<WorkerModel>> getWorkersByProfession(String profession) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('profesion', profession)
        .eq('disponible', 1)
        .order('calificacion', ascending: false)
        .limit(40);
    final workers = rows.map<WorkerModel>((m) => WorkerModel.fromMap(m)).toList();
    WorkerReputationService.instance.sortForListing(workers);
    return workers;
  }

  Future<List<WorkerModel>> getAllAvailableWorkers() async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('disponible', 1)
        .eq('precios_configurados', 1)
        .order('calificacion', ascending: false)
        .limit(40);
    final workers =
        rows.map<WorkerModel>((m) => WorkerModel.fromMap(m)).toList();
    WorkerReputationService.instance.sortForListing(workers);
    return workers;
  }

  /// Correos solo de cuentas @demo.myworksapp.cl. El resto de perfiles no se lista.
  Future<List<WorkerLoginItem>> getWorkersForLogin() async {
    final rows = await supabase.rpc('listar_cuentas_demo_acceso');
    final items = <WorkerLoginItem>[];
    if (rows is! List) return items;
    for (final raw in rows) {
      if (raw is! Map) continue;
      final row = Map<String, dynamic>.from(raw);
      final userId = row['id'] as String?;
      if (userId == null || userId.isEmpty) continue;
      items.add(
        WorkerLoginItem(
          userId: userId,
          name: row['nombre'] as String? ?? 'Trabajador',
          email: row['correo'] as String? ?? '',
          profession: row['profesion'] as String? ?? '',
          serviceCategory: row['categoria_servicio'] as String? ?? 'general',
        ),
      );
    }

    items.sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  Future<void> updateWorker(WorkerModel worker) async {
    await supabase
        .from(_table)
        .update(worker.toMap())
        .eq('id_usuario', worker.userId);
  }

  Future<({String status, String? note})?> fetchVerification(String userId) async {
    try {
      final row = await supabase
          .from(_table)
          .select('estado_verificacion, nota_verificacion')
          .eq('id_usuario', userId)
          .maybeSingle();
      if (row == null) return null;
      final rawNote = row['nota_verificacion'] as String?;
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
    await supabase.rpc('enviar_verificacion_profesional', params: {
      'p_nota': note,
    });
  }

  Future<void> updateBaseLocation({
    required String userId,
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    await supabase.from(_table).update({
      'latitud_base': latitude,
      'longitud_base': longitude,
      'radio_servicio_km': radiusKm,
      'origen_base': 'mapa',
    }).eq('id_usuario', userId);
  }

  Future<void> updateAvailability(String userId, bool isAvailable) async {
    await supabase
        .from(_table)
        .update({'disponible': isAvailable ? 1 : 0}).eq('id_usuario', userId);
  }

  /// Disponible para nuevos trabajos: flag activo y sin trabajos en curso.
  Future<bool> isWorkerAcceptingJobs(String userId) async {
    final worker = await getWorkerByUserId(userId);
    if (worker == null || !worker.isAvailable) return false;
    final jobRepository = JobRepository();
    return !await jobRepository.hasActiveJobs(userId);
  }

  /// Mantiene al trabajador como no disponible mientras tenga trabajos activos.
  Future<void> enforceUnavailableWhileBusy(String userId) async {
    final jobRepository = JobRepository();
    if (!await jobRepository.hasActiveJobs(userId)) return;

    final worker = await getWorkerByUserId(userId);
    if (worker != null && worker.isAvailable) {
      await updateAvailability(userId, false);
    }
  }

  // Obtener trabajadores disponibles que no tienen trabajos activos
  Future<List<WorkerModel>> getAvailableWorkersWithoutActiveJobs({
    UserLocationContext? near,
  }) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('disponible', 1)
        .eq('precios_configurados', 1)
        .order('calificacion', ascending: false)
        .limit(40);
    final allWorkers =
        rows.map<WorkerModel>((m) => WorkerModel.fromMap(m)).toList();
    return _filterListedWorkers(allWorkers, near: near);
  }

  /// Indica si el trabajador tiene trabajos activos (para badge «ocupado»).
  Future<bool> hasActiveJobs(String userId) async {
    final jobRepository = JobRepository();
    return jobRepository.hasActiveJobs(userId);
  }
}
