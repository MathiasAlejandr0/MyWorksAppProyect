import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/models.dart';
import '../database/database_helper.dart';
import '../services/security_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  User? _user;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Obtener ID del usuario autenticado
      final userId = await SecurityService.getUserId();
      if (userId == null) {
        setState(() {
          _error = 'Usuario no autenticado';
          _isLoading = false;
        });
        return;
      }

      // Cargar datos del usuario desde la base de datos
      final user = await _dbHelper.getUser(userId);
      if (user == null) {
        setState(() {
          _error = 'Usuario no encontrado';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar perfil: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Limpiar datos de sesión
      await SecurityService.clearSession();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserProfile,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Implementar edición de perfil
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función de edición próximamente'),
                ),
              );
            },
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
                      const Icon(Icons.error_outline,
                          size: 80, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadUserProfile,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _user == null
                  ? const Center(
                      child: Text('No se encontraron datos del usuario'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sección de información personal
                          Center(
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: AppColors.primaryColor
                                      .withValues(alpha: 0.2),
                                  child: _user!.profileImage != null &&
                                          _user!.profileImage!.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          child: Image.asset(
                                            _user!.profileImage!,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.person,
                                                size: 50,
                                                color: AppColors.primaryColor,
                                              );
                                            },
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: AppColors.primaryColor,
                                        ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _user!.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _user!.email,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondaryColor,
                                  ),
                                ),
                                if (_user!.isVerified)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.verified,
                                          color: Colors.blue,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Verificado',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Sección de información de contacto
                          _buildSectionTitle(
                              context, 'Información de contacto'),
                          _buildInfoItem(Icons.phone, 'Teléfono', _user!.phone),
                          _buildInfoItem(Icons.email, 'Email', _user!.email),

                          const SizedBox(height: 24),

                          // Sección de direcciones
                          if (_user!.addresses.isNotEmpty) ...[
                            _buildSectionTitle(context, 'Direcciones'),
                            ..._user!.addresses.map(
                              (address) => _buildInfoItem(
                                Icons.location_on,
                                'Dirección',
                                address,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Información adicional
                          _buildSectionTitle(context, 'Información adicional'),
                          _buildInfoItem(
                            Icons.calendar_today,
                            'Miembro desde',
                            '${_user!.createdAt.day}/${_user!.createdAt.month}/${_user!.createdAt.year}',
                          ),
                          if (_user!.lastLogin != null)
                            _buildInfoItem(
                              Icons.access_time,
                              'Último acceso',
                              '${_user!.lastLogin!.day}/${_user!.lastLogin!.month}/${_user!.lastLogin!.year}',
                            ),

                          const SizedBox(height: 32),

                          // Botón de cerrar sesión
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _logout,
                              icon: const Icon(Icons.logout),
                              label: const Text('Cerrar sesión'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryColor,
                  ),
                ),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
