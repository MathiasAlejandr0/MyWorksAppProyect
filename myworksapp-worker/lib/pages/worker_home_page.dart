import 'package:flutter/material.dart';
import '../models/worker.dart';
import '../database/worker_database_helper.dart';
import '../utils/app_colors.dart';
import '../services/worker_communication_service.dart';

class WorkerHomePage extends StatefulWidget {
  final int workerId;
  const WorkerHomePage({super.key, required this.workerId});

  @override
  State<WorkerHomePage> createState() => _WorkerHomePageState();
}

class _WorkerHomePageState extends State<WorkerHomePage> {
  final WorkerDatabaseHelper _dbHelper = WorkerDatabaseHelper();
  final WorkerCommunicationService _communicationService =
      WorkerCommunicationService();
  Worker? _currentWorker;
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _notifications = [];
  int _unreadNotificationsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkerData();
  }

  Future<void> _loadWorkerData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Cargar datos del trabajador
      final workerId = await _getCurrentWorkerId();
      if (workerId != null) {
        final worker = await _dbHelper.getWorkerById(workerId);
        if (worker != null) {
          _currentWorker = worker;

          // Guardar disponibilidad para que la app de usuario lo vea
          await _communicationService.saveWorkerAvailability(worker);

          // Cargar solicitudes
          final requests =
              await _communicationService.getWorkerRequests(workerId);

          // Cargar notificaciones
          final notifications =
              await _communicationService.getWorkerNotifications(workerId);
          final unreadCount =
              await _communicationService.getUnreadNotificationsCount(workerId);

          setState(() {
            _requests = requests;
            _notifications = notifications;
            _unreadNotificationsCount = unreadCount;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading worker data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<int?> _getCurrentWorkerId() async {
    // Simular obtener ID del trabajador actual
    // En una implementación real, esto vendría del sistema de autenticación
    return 1; // ID simulado
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${_currentWorker?.name ?? 'Trabajador'}'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textOnPrimaryColor,
        actions: [
          // Badge de notificaciones
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  _showNotificationsDialog();
                },
              ),
              if (_unreadNotificationsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_unreadNotificationsCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWorkerData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: 24),
                    _buildRequestsSection(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final isAvailable = _currentWorker?.isAvailable ?? false;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAvailable ? Icons.check_circle : Icons.cancel,
                  color: isAvailable ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  isAvailable ? 'Disponible' : 'No disponible',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _toggleAvailability(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAvailable ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isAvailable
                        ? 'Marcar como ocupado'
                        : 'Marcar como disponible'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Solicitudes recientes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/requests');
              },
              child: const Text('Ver todas'),
            ),
          ],
        ),
        if (_requests.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No hay solicitudes pendientes',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ..._requests.take(3).map((request) => _buildRequestCard(request)),
      ],
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.primaryColor,
          child: Icon(Icons.work, color: Colors.white),
        ),
        title: Text(request['serviceName'] ?? 'Servicio'),
        subtitle: Text(request['description'] ?? 'Sin descripción'),
        trailing: Chip(
          label: Text(request['status'] ?? 'Pendiente'),
          backgroundColor: _getStatusColor(request['status']),
        ),
        onTap: () {
          // Navegar a detalles de la solicitud
        },
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones rápidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.work,
                title: 'Ver solicitudes',
                onTap: () {
                  Navigator.pushNamed(context, '/requests');
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                icon: Icons.person,
                title: 'Mi perfil',
                onTap: () {
                  Navigator.pushNamed(context, '/profile');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: AppColors.primaryColor),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleAvailability() async {
    if (_currentWorker != null) {
      final newAvailability = !_currentWorker!.isAvailable;
      _currentWorker = _currentWorker!.copyWith(isAvailable: newAvailability);

      // Actualizar en base de datos local
      await _dbHelper.updateWorker(_currentWorker!);

      // Actualizar en el sistema de comunicación
      await _communicationService.saveWorkerAvailability(_currentWorker!);

      setState(() {});
    }
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notificaciones'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: _notifications.isEmpty
              ? const Center(
                  child: Text('No hay notificaciones'),
                )
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return ListTile(
                      title: Text(notification['title'] ?? ''),
                      subtitle: Text(notification['message'] ?? ''),
                      trailing: notification['isRead'] == false
                          ? const Icon(Icons.circle,
                              color: Colors.blue, size: 12)
                          : null,
                      onTap: () {
                        _communicationService.markNotificationAsRead(
                          _currentWorker?.id ?? 1,
                          notification['id'],
                        );
                        Navigator.pop(context);
                        _loadWorkerData();
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
