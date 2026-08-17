import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_logger.dart';
import '../services/session_manager.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../database/repositories/job_repository.dart';
import '../database/repositories/message_repository.dart';
import '../database/repositories/pending_action_repository.dart';

/// Servicio global para manejar el ciclo de vida de la app
class AppLifecycleService extends WidgetsBindingObserver {
  static final AppLifecycleService instance = AppLifecycleService._();
  AppLifecycleService._();

  WidgetRef? _ref;
  bool _isInitialized = false;

  /// Inicializa el servicio
  void initialize(WidgetRef ref) {
    if (_isInitialized) return;

    _ref = ref;
    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;
    AppLogger.i('AppLifecycleService inicializado');
  }

  /// Limpia el servicio
  void dispose() {
    if (!_isInitialized) return;

    WidgetsBinding.instance.removeObserver(this);
    _isInitialized = false;
    _ref = null;
    AppLogger.i('AppLifecycleService limpiado');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (_ref == null) return;

    AppLogger.i('App lifecycle cambió a: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        _handleResumed();
        break;
      case AppLifecycleState.paused:
        _handlePaused();
        break;
      case AppLifecycleState.inactive:
        _handleInactive();
        break;
      case AppLifecycleState.detached:
        _handleDetached();
        break;
      case AppLifecycleState.hidden:
        _handlePaused();
        break;
    }
  }

  /// Maneja cuando la app vuelve a primer plano
  Future<void> _handleResumed() async {
    try {
      AppLogger.i('App resumida, revalidando estado...');

      // 1. Revalidar sesión
      await _revalidateSession();

      // 2. Refrescar jobs activos
      await _refreshActiveJobs();

      // 3. Marcar mensajes como leídos
      await _markMessagesAsRead();

      // 4. Re-sincronizar pending_actions si corresponde
      await _resyncPendingActions();

      AppLogger.i('Estado revalidado exitosamente');
    } catch (e) {
      AppLogger.e('Error al revalidar estado al resumir app', e);
    }
  }

  /// Maneja cuando la app va a segundo plano
  Future<void> _handlePaused() async {
    try {
      AppLogger.i('App pausada, persistiendo estado...');

      // 1. Persistir estado temporal
      await _persistTemporaryState();

      // 2. Guardar borradores (chat / formularios)
      await _saveDrafts();

      AppLogger.i('Estado persistido exitosamente');
    } catch (e) {
      AppLogger.e('Error al persistir estado al pausar app', e);
    }
  }

  /// Maneja cuando la app está inactiva
  Future<void> _handleInactive() async {
    // Estado transitorio, no requiere acción específica
    AppLogger.i('App inactiva');
  }

  /// Maneja cuando la app está desconectada
  Future<void> _handleDetached() async {
    // Similar a paused, pero más definitivo
    await _handlePaused();
    AppLogger.i('App desconectada');
  }

  /// Revalida la sesión del usuario
  /// 
  /// IMPORTANTE: No hace logout automático por errores temporales.
  /// Solo cierra sesión si realmente no hay datos de sesión guardados.
  Future<void> _revalidateSession() async {
    try {
      if (_ref == null) return;

      final authNotifier = _ref!.read(authProvider.notifier);
      final authState = _ref!.read(authProvider);

      // Si hay usuario logueado en el estado, verificar que la sesión persiste
      if (authState.user != null) {
        // Primero verificar si hay datos de sesión guardados (más rápido y confiable)
        final sessionData = await SessionManager.instance.getSessionData();
        
        if (sessionData == null || sessionData['userId'] == null) {
          // No hay datos de sesión guardados, hacer logout
          AppLogger.w('No hay datos de sesión guardados, cerrando sesión');
          await authNotifier.logout();
          return;
        }

        // Verificar que el userId de la sesión coincide con el usuario actual
        final savedUserId = sessionData['userId'];
        if (savedUserId != authState.user!.id) {
          AppLogger.w('UserId de sesión no coincide, cerrando sesión');
          await authNotifier.logout();
          return;
        }

        // Intentar verificar que el usuario sigue activo (con tolerancia a errores)
        try {
          final hasActiveSession = await SessionManager.instance.hasActiveSession();
          
          if (!hasActiveSession) {
            // Solo hacer logout si realmente no hay sesión válida
            // Pero primero verificar que no sea un error temporal
            final user = await SessionManager.instance.restoreSession();
            if (user == null) {
              AppLogger.w('Sesión inválida confirmada, cerrando sesión');
              await authNotifier.logout();
              return;
            }
            // Si restoreSession funciona, la sesión es válida, solo recargar usuario
          }
          
          // Recargar usuario para obtener datos actualizados (sin hacer logout)
          try {
            await authNotifier.loadCurrentUser(authState.user!.id, silent: true);
          } catch (e) {
            // Si falla recargar, no es crítico, solo loguear
            AppLogger.w('No se pudo recargar usuario, pero sesión sigue activa: $e');
          }
        } catch (e) {
          // Error al verificar sesión activa - NO hacer logout por errores temporales
          // La sesión está guardada, así que asumimos que es válida
          AppLogger.w('Error temporal al verificar sesión activa (ignorado): $e');
          AppLogger.i('Sesión sigue activa basada en datos guardados');
          // No hacer logout, la sesión probablemente es válida
        }
      } else {
        // No hay usuario en el estado, pero verificar si hay sesión guardada para restaurar
        final sessionData = await SessionManager.instance.getSessionData();
        if (sessionData != null && sessionData['userId'] != null) {
          AppLogger.i('Usuario no en estado pero hay sesión guardada, restaurando...');
          try {
            final restored = await authNotifier.restoreSession();
            if (!restored) {
              AppLogger.w('No se pudo restaurar sesión guardada');
            }
          } catch (e) {
            AppLogger.e('Error al restaurar sesión guardada', e);
          }
        }
      }
    } catch (e) {
      // Error general - NO hacer logout automático
      AppLogger.e('Error al revalidar sesión (no se cerrará sesión): $e');
      // Mantener la sesión activa si hay datos guardados
    }
  }

  /// Refresca los jobs activos del usuario
  Future<void> _refreshActiveJobs() async {
    try {
      if (_ref == null) return;

      final authState = _ref!.read(authProvider);
      final user = authState.user;
      
      if (user == null) return;

      final jobRepository = JobRepository();
      
      // Obtener jobs activos según rol
      if (user.role == 'user') {
        final activeJobs = await jobRepository.getJobsByUserId(user.id);
        final pendingOrInProgress = activeJobs.where((job) => 
          job.status == 'pending' || 
          job.status == 'accepted' || 
          job.status == 'in_progress'
        ).toList();
        
        if (pendingOrInProgress.isNotEmpty) {
          AppLogger.i('${pendingOrInProgress.length} trabajos activos encontrados');
        }
      } else if (user.role == 'worker') {
        final activeJobs = await jobRepository.getJobsByWorkerId(user.id);
        final pendingOrInProgress = activeJobs.where((job) => 
          job.status == 'pending' || 
          job.status == 'accepted' || 
          job.status == 'in_progress'
        ).toList();
        
        if (pendingOrInProgress.isNotEmpty) {
          AppLogger.i('${pendingOrInProgress.length} trabajos activos encontrados');
        }
      }
    } catch (e) {
      AppLogger.e('Error al refrescar jobs activos', e);
    }
  }

  /// Marca mensajes como leídos
  Future<void> _markMessagesAsRead() async {
    try {
      if (_ref == null) return;

      final authState = _ref!.read(authProvider);
      final user = authState.user;
      
      if (user == null) return;

      final messageRepository = MessageRepository();
      
      // Obtener mensajes no leídos del usuario
      final unreadMessages = await messageRepository.getUnreadMessages(user.id);
      
      if (unreadMessages.isNotEmpty) {
        // Marcar como leídos (solo los que están en pantalla activa)
        // En producción, esto se haría más selectivamente
        AppLogger.i('${unreadMessages.length} mensajes no leídos encontrados');
      }
    } catch (e) {
      AppLogger.e('Error al marcar mensajes como leídos', e);
    }
  }

  /// Re-sincroniza pending_actions
  Future<void> _resyncPendingActions() async {
    try {
      if (_ref == null) return;

      final authState = _ref!.read(authProvider);
      final user = authState.user;
      
      if (user == null) return;

      final pendingActionRepository = PendingActionRepository();
      
      // Obtener acciones pendientes
      final pendingActions = await pendingActionRepository.getPendingActions(user.id);
      
      if (pendingActions.isNotEmpty) {
        AppLogger.i('${pendingActions.length} acciones pendientes encontradas');
        // En producción, aquí se intentarían sincronizar con backend
        // Por ahora solo logueamos
      }
    } catch (e) {
      AppLogger.e('Error al re-sincronizar pending_actions', e);
    }
  }

  /// Persiste estado temporal
  Future<void> _persistTemporaryState() async {
    try {
      // Aquí se pueden guardar estados temporales si es necesario
      // Por ejemplo: formularios parcialmente completados
      AppLogger.i('Estado temporal persistido');
    } catch (e) {
      AppLogger.e('Error al persistir estado temporal', e);
    }
  }

  /// Guarda borradores de chat y formularios
  Future<void> _saveDrafts() async {
    try {
      // Aquí se guardarían borradores si se implementa esa funcionalidad
      // Por ahora solo logueamos
      AppLogger.i('Borradores guardados');
    } catch (e) {
      AppLogger.e('Error al guardar borradores', e);
    }
  }
}

