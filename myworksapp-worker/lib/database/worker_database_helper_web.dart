import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/worker.dart';
import '../models/portfolio_item.dart';
import '../models/request.dart';

class WorkerDatabaseHelper {
  static final WorkerDatabaseHelper _instance =
      WorkerDatabaseHelper._internal();
  factory WorkerDatabaseHelper() => _instance;
  WorkerDatabaseHelper._internal();

  static const String _storageKey = 'worker_app_data';
  List<Worker> _workers = [];
  List<PortfolioItem> _portfolioItems = [];
  List<Request> _requests = [];
  int _nextWorkerId = 1;
  int _nextPortfolioId = 1;
  int _nextRequestId = 1;

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      if (data != null) {
        final map = json.decode(data);
        _workers =
            (map['workers'] as List).map((w) => Worker.fromMap(w)).toList();
        _portfolioItems = (map['portfolio'] as List)
            .map((p) => PortfolioItem.fromMap(p))
            .toList();
        _requests =
            (map['requests'] as List).map((r) => Request.fromMap(r)).toList();
        _nextWorkerId = map['nextWorkerId'] ?? 1;
        _nextPortfolioId = map['nextPortfolioId'] ?? 1;
        _nextRequestId = map['nextRequestId'] ?? 1;
      }
    } catch (e) {
      // Ignorar errores de almacenamiento en web
      // Los errores de SharedPreferences en web son comunes y no críticos
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'workers': _workers.map((w) => w.toMap()).toList(),
        'portfolio': _portfolioItems.map((p) => p.toMap()).toList(),
        'requests': _requests.map((r) => r.toMap()).toList(),
        'nextWorkerId': _nextWorkerId,
        'nextPortfolioId': _nextPortfolioId,
        'nextRequestId': _nextRequestId,
      };
      await prefs.setString(_storageKey, json.encode(data));
    } catch (e) {
      // Ignorar errores de almacenamiento en web
      // Los errores de SharedPreferences en web son comunes y no críticos
    }
  }

  void _insertDefaultData() {
    if (_workers.isNotEmpty) return;
    final testWorker = Worker(
      id: _nextWorkerId++,
      name: 'Juan Pérez',
      email: 'juan@test.com',
      phone: '123456789',
      password: '123456',
      profession: 'Plomero',
      description:
          'Plomero profesional con 5 años de experiencia en instalaciones y reparaciones.',
      address: 'Calle Principal 123, Ciudad',
      hourlyRate: 25.0,
      createdAt: DateTime.now(),
      isAvailable: true,
    );
    _workers.add(testWorker);
    _portfolioItems.addAll([
      PortfolioItem(
        id: _nextPortfolioId++,
        workerId: testWorker.id!,
        imagePath: 'assets/images/placeholder.txt',
        description: 'Instalación de tuberías en cocina',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      PortfolioItem(
        id: _nextPortfolioId++,
        workerId: testWorker.id!,
        imagePath: 'assets/images/placeholder.txt',
        description: 'Reparación de fuga en baño',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ]);
    _requests.addAll([
      Request(
        id: _nextRequestId++,
        workerId: testWorker.id!,
        userName: 'María García',
        userContact: 'maria@email.com',
        service: 'Reparación de fuga',
        description:
            'Tengo una fuga en la tubería del baño que necesita reparación urgente.',
        requestedAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'pendiente',
      ),
      Request(
        id: _nextRequestId++,
        workerId: testWorker.id!,
        userName: 'Carlos López',
        userContact: 'carlos@email.com',
        service: 'Instalación de grifo',
        description: 'Necesito instalar un nuevo grifo en la cocina.',
        requestedAt: DateTime.now().subtract(const Duration(days: 1)),
        status: 'aceptada',
      ),
    ]);
  }

  // Métodos públicos (idénticos a la versión nativa, pero usando almacenamiento local)
  // ... (insertWorker, getWorkerByEmail, updateWorker, updateWorkerAvailability, insertPortfolioItem, getPortfolioByWorker, deletePortfolioItem, insertRequest, getRequestsByWorker, updateRequestStatus, insertTestData)

  // Trabajadores
  Future<int> insertWorker(Worker worker) async {
    await _loadFromStorage();
    worker = worker.copyWith(id: _nextWorkerId++);
    _workers.add(worker);
    await _saveToStorage();
    return worker.id!;
  }

  Future<Worker?> getWorkerByEmail(String email) async {
    await _loadFromStorage();
    try {
      return _workers.firstWhere((w) => w.email == email);
    } catch (e) {
      return null;
    }
  }

  Future<Worker?> getWorkerById(int id) async {
    await _loadFromStorage();
    try {
      return _workers.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<int> updateWorker(Worker worker) async {
    await _loadFromStorage();
    final index = _workers.indexWhere((w) => w.id == worker.id);
    if (index != -1) {
      _workers[index] = worker;
      await _saveToStorage();
      return 1;
    }
    return 0;
  }

  Future<int> updateWorkerAvailability(int workerId, bool isAvailable) async {
    await _loadFromStorage();
    final index = _workers.indexWhere((w) => w.id == workerId);
    if (index != -1) {
      _workers[index] = _workers[index].copyWith(isAvailable: isAvailable);
      await _saveToStorage();
      return 1;
    }
    return 0;
  }

  // Portafolio
  Future<int> insertPortfolioItem(PortfolioItem item) async {
    await _loadFromStorage();
    item = PortfolioItem(
      id: _nextPortfolioId++,
      workerId: item.workerId,
      imagePath: item.imagePath,
      description: item.description,
      createdAt: item.createdAt,
    );
    _portfolioItems.add(item);
    await _saveToStorage();
    return item.id!;
  }

  Future<List<PortfolioItem>> getPortfolioByWorker(int workerId) async {
    await _loadFromStorage();
    return _portfolioItems.where((item) => item.workerId == workerId).toList();
  }

  Future<int> deletePortfolioItem(int id) async {
    await _loadFromStorage();
    _portfolioItems.removeWhere((item) => item.id == id);
    await _saveToStorage();
    return 1;
  }

  // Solicitudes
  Future<int> insertRequest(Request request) async {
    await _loadFromStorage();
    request = Request(
      id: _nextRequestId++,
      workerId: request.workerId,
      userName: request.userName,
      userContact: request.userContact,
      service: request.service,
      description: request.description,
      requestedAt: request.requestedAt,
      status: request.status,
    );
    _requests.add(request);
    await _saveToStorage();
    return request.id!;
  }

  Future<List<Request>> getRequestsByWorker(int workerId) async {
    await _loadFromStorage();
    return _requests.where((request) => request.workerId == workerId).toList();
  }

  Future<int> updateRequestStatus(int requestId, String status) async {
    await _loadFromStorage();
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _requests[index] = _requests[index].copyWith(status: status);
      await _saveToStorage();
      return 1;
    }
    return 0;
  }

  // Método para insertar datos de prueba
  Future<void> insertTestData() async {
    await _loadFromStorage();
    _insertDefaultData();
    await _saveToStorage();
  }
}
