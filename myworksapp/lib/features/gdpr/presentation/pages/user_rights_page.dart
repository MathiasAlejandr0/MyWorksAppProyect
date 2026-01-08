import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/gdpr_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Página de Derechos del Usuario (GDPR)
/// 
/// Permite ejercer derechos GDPR:
/// - Acceso a datos
/// - Exportación de datos
/// - Eliminación de cuenta
class UserRightsPage extends ConsumerStatefulWidget {
  const UserRightsPage({super.key});

  @override
  ConsumerState<UserRightsPage> createState() => _UserRightsPageState();
}

class _UserRightsPageState extends ConsumerState<UserRightsPage> {
  bool _isExporting = false;
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Derechos'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tus Derechos (GDPR)',
              style: AppTextStyles.displaySmall(),
            ),
            const SizedBox(height: 8),
            Text(
              'Tienes control total sobre tus datos personales',
              style: AppTextStyles.bodyMedium(),
            ),
            const SizedBox(height: 24),
            _buildRightCard(
              icon: Icons.description,
              title: 'Derecho de Acceso',
              description: 'Puedes acceder a todos tus datos personales almacenados en la aplicación.',
            ),
            const SizedBox(height: 16),
            _buildRightCard(
              icon: Icons.download,
              title: 'Derecho de Portabilidad',
              description: 'Exporta todos tus datos en formato JSON para usarlos en otro servicio.',
              action: _buildExportButton(),
            ),
            const SizedBox(height: 16),
            _buildRightCard(
              icon: Icons.edit,
              title: 'Derecho de Rectificación',
              description: 'Puedes actualizar tu información personal desde tu perfil.',
            ),
            const SizedBox(height: 16),
            _buildRightCard(
              icon: Icons.delete_forever,
              title: 'Derecho al Olvido',
              description: 'Solicita la eliminación permanente de tu cuenta y todos tus datos.',
              action: _buildDeleteButton(),
              isDanger: true,
            ),
            const SizedBox(height: 16),
            _buildRightCard(
              icon: Icons.block,
              title: 'Derecho de Oposición',
              description: 'Puedes oponerte al procesamiento de tus datos en cualquier momento.',
            ),
            const SizedBox(height: 16),
            _buildRightCard(
              icon: Icons.cancel,
              title: 'Retirar Consentimiento',
              description: 'Puedes retirar tu consentimiento, aunque esto puede limitar el uso de la app.',
            ),
            const SizedBox(height: 32),
            Text(
              'Información Adicional',
              style: AppTextStyles.titleLarge(),
            ),
            const SizedBox(height: 8),
            Text(
              'Para ejercer cualquiera de estos derechos o hacer preguntas sobre el procesamiento de tus datos, puedes contactarnos desde la sección de Configuración > Privacidad.',
              style: AppTextStyles.bodyMedium(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRightCard({
    required IconData icon,
    required String title,
    required String description,
    Widget? action,
    bool isDanger = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isDanger ? Colors.red : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.titleMedium(
                      color: isDanger ? Colors.red : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: AppTextStyles.bodyMedium(),
            ),
            if (action != null) ...[
              const SizedBox(height: 12),
              action,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isExporting ? null : _exportData,
        icon: _isExporting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.download),
        label: Text(_isExporting ? 'Exportando...' : 'Exportar Mis Datos'),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isDeleting ? null : _requestDeletion,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        icon: _isDeleting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.delete_forever),
        label: Text(_isDeleting ? 'Procesando...' : 'Solicitar Eliminación'),
      ),
    );
  }

  Future<void> _exportData() async {
    // Obtener userId desde el estado de autenticación
    final authState = ref.read(authProvider);
    final userId = authState.user?.id;
    
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes iniciar sesión para exportar tus datos'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    setState(() => _isExporting = true);

    try {
      AppLogger.i('Iniciando exportación de datos para usuario: $userId');

      // Exportar datos
      final jsonData = await GdprService.instance.exportUserDataAsJson(userId);

      // Guardar en archivo temporal
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/myworksapp_data_export_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonData);

      // Compartir archivo
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Exportación de Datos - MyWorksApp',
        text: 'Mis datos personales exportados desde MyWorksApp',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos exportados exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }

      AppLogger.i('Exportación completada exitosamente');
    } catch (e) {
      AppLogger.e('Error al exportar datos', e);
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _requestDeletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar tu cuenta?\n\n'
          'Esta acción es PERMANENTE e IRREVERSIBLE.\n\n'
          'Se eliminarán:\n'
          '• Tu cuenta y perfil\n'
          '• Todos tus trabajos\n'
          '• Todos tus mensajes\n'
          '• Todas tus calificaciones\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar Permanentemente'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Segunda confirmación
    final doubleConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Última Confirmación'),
        content: const Text(
          'Esta es tu última oportunidad.\n\n'
          '¿Realmente deseas eliminar tu cuenta permanentemente?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );

    if (doubleConfirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      final authState = ref.read(authProvider);
      final userId = authState.user?.id;
      
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Debes iniciar sesión para eliminar tu cuenta'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // Solicitar eliminación (esto llamará a AccountDeletionService)
      await GdprService.instance.requestAccountDeletion(userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud de eliminación procesada'),
            backgroundColor: Colors.orange,
          ),
        );
        
        // Redirigir a login después de un momento
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.go('/welcome');
          }
        });
      }
    } catch (e) {
      AppLogger.e('Error al solicitar eliminación', e);
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }
}

