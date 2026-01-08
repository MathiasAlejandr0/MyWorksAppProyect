import 'package:flutter/material.dart';
import '../../services/app_health_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_logger.dart';

/// Página de mantenimiento (Modo Seguro)
/// 
/// Se muestra cuando se detectan fallos críticos en la aplicación.
/// Ofrece opciones de recuperación sin crashear la app.
class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  final AppHealthService _healthService = AppHealthService.instance;
  bool _isRecovering = false;
  String? _recoveryMessage;

  @override
  Widget build(BuildContext context) {
    final diagnostics = _healthService.getDiagnostics();
    final failureType = _healthService.lastFailureType;
    final failureMessage = _healthService.lastFailureMessage;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono de mantenimiento
              Icon(
                Icons.build_circle_outlined,
                size: 80,
                color: AppColors.warning,
              ),
              const SizedBox(height: 24),
              
              // Título
              Text(
                'Modo Mantenimiento',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.grayDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Mensaje principal
              Text(
                'Estamos reparando el sistema local.\nTus datos están seguros.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.grayMedium,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Información del error (si está disponible)
              if (failureType != null || failureMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (failureType != null)
                        Text(
                          'Tipo: ${_formatFailureType(failureType)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                      if (failureMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          failureMessage!,
                          style: TextStyle(
                            color: AppColors.grayDark,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              
              const SizedBox(height: 32),
              
              // Mensaje de recuperación (si está en proceso)
              if (_isRecovering)
                Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    if (_recoveryMessage != null)
                      Text(
                        _recoveryMessage!,
                        style: TextStyle(color: AppColors.info),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              
              if (!_isRecovering) ...[
                // Botón: Reintentar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Botón: Restaurar Backup
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _handleRestoreBackup,
                    icon: const Icon(Icons.restore),
                    label: const Text('Restaurar Último Backup'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryLight,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Botón: Contactar Soporte
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _handleContactSupport,
                    icon: const Icon(Icons.support_agent),
                    label: const Text('Contactar Soporte'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.grayDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Información de diagnóstico (colapsable)
              ExpansionTile(
                title: const Text(
                  'Información Técnica',
                  style: TextStyle(fontSize: 12),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      diagnostics.entries
                          .map((e) => '${e.key}: ${e.value}')
                          .join('\n'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFailureType(CriticalFailureType type) {
    switch (type) {
      case CriticalFailureType.databaseNotInitialized:
        return 'Base de datos no inicializada';
      case CriticalFailureType.migrationInterrupted:
        return 'Migración interrumpida';
      case CriticalFailureType.partialCorruption:
        return 'Corrupción parcial detectada';
      case CriticalFailureType.databaseClosed:
        return 'Base de datos cerrada';
      case CriticalFailureType.unknown:
        return 'Error desconocido';
    }
  }

  Future<void> _handleRetry() async {
    setState(() {
      _isRecovering = true;
      _recoveryMessage = 'Reintentando conexión...';
    });

    try {
      final success = await _healthService.attemptRecovery(restoreBackup: false);
      
      if (success) {
        setState(() {
          _recoveryMessage = '¡Recuperación exitosa!';
        });
        
        // Esperar un momento y luego intentar navegar
        await Future.delayed(const Duration(seconds: 1));
        
        // La app debería redirigir automáticamente cuando el health check pase
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        setState(() {
          _recoveryMessage = 'No se pudo recuperar. Intenta restaurar un backup.';
          _isRecovering = false;
        });
      }
    } catch (e) {
      AppLogger.e('Error durante recuperación', e);
      setState(() {
        _recoveryMessage = 'Error: $e';
        _isRecovering = false;
      });
    }
  }

  Future<void> _handleRestoreBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar Backup'),
        content: const Text(
          'Esto restaurará el último backup disponible. '
          '¿Estás seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isRecovering = true;
      _recoveryMessage = 'Restaurando backup...';
    });

    try {
      final success = await _healthService.attemptRecovery(restoreBackup: true);
      
      if (success) {
        setState(() {
          _recoveryMessage = '¡Backup restaurado exitosamente!';
        });
        
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        setState(() {
          _recoveryMessage = 'No se pudo restaurar el backup.';
          _isRecovering = false;
        });
      }
    } catch (e) {
      AppLogger.e('Error al restaurar backup', e);
      setState(() {
        _recoveryMessage = 'Error: $e';
        _isRecovering = false;
      });
    }
  }

  void _handleContactSupport() {
    // TODO: Implementar contacto con soporte
    // Por ahora, mostrar información de diagnóstico
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contactar Soporte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Por favor, proporciona esta información al soporte:'),
            const SizedBox(height: 16),
            SelectableText(
              _healthService.getDiagnostics().entries
                  .map((e) => '${e.key}: ${e.value}')
                  .join('\n'),
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
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

