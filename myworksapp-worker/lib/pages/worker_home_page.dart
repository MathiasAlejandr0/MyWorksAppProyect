import 'package:flutter/material.dart';
import '../database/worker_database_helper.dart';
import '../models/worker.dart';
import '../utils/app_colors.dart';
import 'worker_profile_page.dart';
import 'worker_portfolio_page.dart';
import 'worker_requests_page.dart';

class WorkerHomePage extends StatefulWidget {
  final int workerId;
  const WorkerHomePage({super.key, required this.workerId});

  @override
  State<WorkerHomePage> createState() => _WorkerHomePageState();
}

class _WorkerHomePageState extends State<WorkerHomePage> {
  final _dbHelper = WorkerDatabaseHelper();
  Worker? _worker;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWorkerData();
  }

  Future<void> _loadWorkerData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Usar el método público para obtener el trabajador por ID
      final worker = await _dbHelper.getWorkerById(widget.workerId);
      if (worker != null) {
        _worker = worker;
      } else {
        // Si no encontramos el trabajador, crear uno por defecto para demo
        _worker = Worker(
          id: widget.workerId,
          name: 'Juan Pérez',
          email: 'juan@test.com',
          phone: '123456789',
          password: '123456',
          profession: 'Plomero',
          description: 'Plomero profesional con 5 años de experiencia.',
          address: 'Calle Principal 123, Ciudad',
          hourlyRate: 25.0,
          createdAt: DateTime.now(),
          isAvailable: true,
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Error al cargar datos: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAvailability() async {
    if (_worker == null) return;
    setState(() {
      _isLoading = true;
    });
    try {
      await _dbHelper.updateWorkerAvailability(
          widget.workerId, !_worker!.isAvailable);
      _worker = _worker!.copyWith(isAvailable: !_worker!.isAvailable);
    } catch (e) {
      setState(() {
        _error = 'Error al actualizar disponibilidad: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyWorks - Trabajador'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textOnPrimaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWorkerData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadWorkerData,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _worker == null
                  ? const Center(child: Text('No se pudo cargar el perfil.'))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header con información del trabajador
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '¡Hola, ${_worker!.name}!',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _worker!.profession,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Icon(
                                        _worker!.isAvailable
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: _worker!.isAvailable
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _worker!.isAvailable
                                            ? 'Disponible'
                                            : 'No disponible',
                                        style: TextStyle(
                                          color: _worker!.isAvailable
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Toggle de disponibilidad
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Estado de Disponibilidad',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SwitchListTile(
                                    title: Text(
                                      _worker!.isAvailable
                                          ? 'Disponible para trabajos'
                                          : 'No disponible',
                                    ),
                                    subtitle: Text(
                                      _worker!.isAvailable
                                          ? 'Los clientes pueden contactarte'
                                          : 'No recibirás nuevas solicitudes',
                                    ),
                                    value: _worker!.isAvailable,
                                    onChanged: (value) => _toggleAvailability(),
                                    activeColor: AppColors.primaryColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Menú de opciones
                          const Text(
                            'Gestionar',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Botones de navegación
                          _buildMenuButton(
                            icon: Icons.person,
                            title: 'Mi Perfil',
                            subtitle: 'Editar información personal',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WorkerProfilePage(
                                  workerId: widget.workerId,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          _buildMenuButton(
                            icon: Icons.photo_library,
                            title: 'Mi Portafolio',
                            subtitle: 'Gestionar fotos de trabajos',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WorkerPortfolioPage(
                                  workerId: widget.workerId,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          _buildMenuButton(
                            icon: Icons.assignment,
                            title: 'Solicitudes',
                            subtitle: 'Ver y gestionar solicitudes',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WorkerRequestsPage(
                                  workerId: widget.workerId,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryColor, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
