import 'package:flutter/material.dart';
import '../models/worker.dart';
import '../services/worker_security_service.dart';
import '../database/worker_database_helper.dart';
import '../utils/app_colors.dart';

class WorkerHomePage extends StatefulWidget {
  const WorkerHomePage({super.key});

  @override
  State<WorkerHomePage> createState() => _WorkerHomePageState();
}

class _WorkerHomePageState extends State<WorkerHomePage> {
  final _securityService = WorkerSecurityService();
  final _databaseHelper = WorkerDatabaseHelper();

  Worker? _currentWorker;
  bool _isLoading = true;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadWorkerData();
  }

  Future<void> _loadWorkerData() async {
    try {
      final worker = await _securityService.getWorkerSession();
      if (worker != null) {
        setState(() {
          _currentWorker = worker;
        });

        // Cargar notificaciones no leídas
        final unreadCount =
            await _databaseHelper.getUnreadNotificationsCount(worker.id!);
        setState(() {
          _unreadNotifications = unreadCount;
        });
      }
    } catch (e) {
      print('Error loading worker data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAvailability() async {
    if (_currentWorker == null) return;

    try {
      final newAvailability = !_currentWorker!.isAvailable;
      await _databaseHelper.updateWorkerAvailability(
          _currentWorker!.id!, newAvailability);

      setState(() {
        _currentWorker = _currentWorker!.copyWith(isAvailable: newAvailability);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newAvailability
                ? 'Ahora estás disponible para recibir solicitudes'
                : 'Ya no estás disponible para recibir solicitudes',
          ),
          backgroundColor:
              newAvailability ? AppColors.successColor : AppColors.warningColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar disponibilidad: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await _securityService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/worker_login');
      }
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentWorker == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No se pudo cargar la información del trabajador'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/worker_login');
                },
                child: const Text('Volver al login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('My Worker App'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textOnPrimaryColor,
        elevation: 0,
        actions: [
          // Notificaciones
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.of(context).pushNamed('/worker_notifications');
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.errorColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_unreadNotifications',
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
          // Menú
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.of(context).pushNamed('/worker_profile');
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Mi Perfil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Cerrar Sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarjeta de bienvenida
            _buildWelcomeCard(),
            const SizedBox(height: 24),

            // Estado de disponibilidad
            _buildAvailabilityCard(),
            const SizedBox(height: 24),

            // Estadísticas
            _buildStatsSection(),
            const SizedBox(height: 24),

            // Acciones rápidas
            _buildQuickActions(),
            const SizedBox(height: 24),

            // Información del perfil
            _buildProfileInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [AppColors.primaryColor, AppColors.primaryDarkColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.textOnPrimaryColor,
                    child: _currentWorker!.profileImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.asset(
                              _currentWorker!.profileImage!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person,
                                  size: 30,
                                  color: AppColors.primaryColor,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 30,
                            color: AppColors.primaryColor,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¡Hola, ${_currentWorker!.name}!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textOnPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentWorker!.profession,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textOnPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.getAvailabilityColor(
                      _currentWorker!.isAvailable),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _currentWorker!.isAvailable ? 'Disponible' : 'No Disponible',
                  style: const TextStyle(
                    color: AppColors.textOnPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _currentWorker!.isAvailable
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: AppColors.getAvailabilityColor(
                      _currentWorker!.isAvailable),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Estado de Disponibilidad',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _currentWorker!.isAvailable
                  ? 'Estás disponible para recibir solicitudes de trabajo. Los clientes podrán contactarte.'
                  : 'No estás disponible para recibir solicitudes. Los clientes no podrán contactarte.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _toggleAvailability,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentWorker!.isAvailable
                      ? AppColors.warningColor
                      : AppColors.successColor,
                  foregroundColor: AppColors.textOnPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _currentWorker!.isAvailable
                      ? 'Marcar como No Disponible'
                      : 'Marcar como Disponible',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.star,
            title: 'Calificación',
            value: _currentWorker!.rating?.toStringAsFixed(1) ?? 'N/A',
            color: AppColors.ratingColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.rate_review,
            title: 'Reseñas',
            value: '${_currentWorker!.totalReviews ?? 0}',
            color: AppColors.infoColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.attach_money,
            title: 'Tarifa/Hora',
            value: _currentWorker!.hourlyRate != null
                ? '\$${_currentWorker!.hourlyRate!.toStringAsFixed(0)}'
                : 'N/A',
            color: AppColors.successColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acciones Rápidas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.person,
                    label: 'Mi Perfil',
                    onTap: () {
                      Navigator.of(context).pushNamed('/worker_profile');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.photo_library,
                    label: 'Mi Portafolio',
                    onTap: () {
                      Navigator.of(context).pushNamed('/worker_portfolio');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.rate_review,
                    label: 'Mis Reseñas',
                    onTap: () {
                      Navigator.of(context).pushNamed('/worker_reviews');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.settings,
                    label: 'Configuración',
                    onTap: () {
                      Navigator.of(context).pushNamed('/worker_settings');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.primaryColor,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textPrimaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información del Perfil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Email', _currentWorker!.email),
            _buildInfoRow('Teléfono', _currentWorker!.phone),
            if (_currentWorker!.address != null &&
                _currentWorker!.address!.isNotEmpty)
              _buildInfoRow('Dirección', _currentWorker!.address!),
            if (_currentWorker!.title != null)
              _buildInfoRow('Título',
                  '${_currentWorker!.title} (${_currentWorker!.titleInstitution}, ${_currentWorker!.titleYear})'),
            if (_currentWorker!.description != null &&
                _currentWorker!.description!.isNotEmpty)
              _buildInfoRow('Descripción', _currentWorker!.description!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
