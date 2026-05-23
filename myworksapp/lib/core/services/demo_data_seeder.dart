import '../config/demo_credentials.dart';
import '../database/models/user_model.dart';
import '../database/models/worker_model.dart';
import '../database/repositories/user_repository.dart';
import '../database/repositories/worker_repository.dart';
import '../utils/app_logger.dart';
import '../utils/constants.dart';
import '../utils/password_utils.dart';

/// Carga datos de demostración para probar la app en un solo dispositivo.
class DemoDataSeeder {
  static final DemoDataSeeder instance = DemoDataSeeder._();
  DemoDataSeeder._();

  static const _demoUserId = 'demo-user-001';
  static const _demoWorkerId = 'demo-worker-001';
  static const _demoWorker2Id = 'demo-worker-002';
  static const _demoWorker3Id = 'demo-worker-003';

  final UserRepository _userRepository = UserRepository();
  final WorkerRepository _workerRepository = WorkerRepository();

  Future<void> seedDemoData() async {
    try {
      final existing = await _userRepository.getUserByEmail(DemoCredentials.userEmail);
      if (existing != null) {
        AppLogger.d('Datos demo ya existen, omitiendo seed');
        return;
      }

      AppLogger.i('Cargando datos de demostración...');
      final passwordHash = PasswordUtils.hashPassword(DemoCredentials.demoPassword);
      final now = DateTime.now();

      await _userRepository.createUser(UserModel(
        id: _demoUserId,
        name: DemoCredentials.userName,
        email: DemoCredentials.userEmail,
        password: passwordHash,
        role: AppConstants.roleUser,
        createdAt: now,
      ));

      await _createWorkerAccount(
        id: _demoWorkerId,
        name: DemoCredentials.workerName,
        email: DemoCredentials.workerEmail,
        profession: 'Electricista',
        description: 'Instalaciones eléctricas, enchufes, luminarias y tableros.',
        rating: 4.8,
        passwordHash: passwordHash,
        createdAt: now,
      );

      await _createWorkerAccount(
        id: _demoWorker2Id,
        name: 'Pedro Gasfiter',
        email: 'pedro@demo.com',
        profession: 'Gasfiter',
        description: 'Reparación de cañerías, grifos y filtraciones.',
        rating: 4.5,
        passwordHash: passwordHash,
        createdAt: now,
      );

      await _createWorkerAccount(
        id: _demoWorker3Id,
        name: 'María Limpieza',
        email: 'maria@demo.com',
        profession: 'Técnico en General',
        description: 'Limpieza general, profunda y post-mudanza.',
        rating: 4.9,
        passwordHash: passwordHash,
        createdAt: now,
      );

      AppLogger.i('Datos de demostración cargados correctamente');
    } catch (e) {
      AppLogger.e('Error cargando datos demo', e);
    }
  }

  Future<void> _createWorkerAccount({
    required String id,
    required String name,
    required String email,
    required String profession,
    required String description,
    required double rating,
    required String passwordHash,
    required DateTime createdAt,
  }) async {
    await _userRepository.createUser(UserModel(
      id: id,
      name: name,
      email: email,
      password: passwordHash,
      role: AppConstants.roleWorker,
      createdAt: createdAt,
    ));

    await _workerRepository.createWorker(WorkerModel(
      userId: id,
      profession: profession,
      description: description,
      rating: rating,
      isAvailable: true,
    ));
  }
}
