import 'package:uuid/uuid.dart';
import '../database/repositories/user_block_repository.dart';
import '../database/models/user_block_model.dart';
import '../utils/app_logger.dart';

/// Servicio para manejar bloqueos entre usuarios
class BlockService {
  final UserBlockRepository _blockRepository = UserBlockRepository();

  /// Bloquea a un usuario
  Future<bool> blockUser({
    required String blockerId,
    required String blockedUserId,
  }) async {
    try {
      // Verificar que no se esté bloqueando a sí mismo
      if (blockerId == blockedUserId) {
        AppLogger.w('No se puede bloquear a uno mismo');
        return false;
      }

      // Verificar si ya está bloqueado
      final isAlreadyBlocked = await _blockRepository.isBlocked(blockerId, blockedUserId);
      if (isAlreadyBlocked) {
        AppLogger.i('Usuario ya está bloqueado');
        return true; // Ya está bloqueado, considerar éxito
      }

      // Crear bloqueo
      final block = UserBlockModel(
        id: const Uuid().v4(),
        blockerId: blockerId,
        blockedUserId: blockedUserId,
        createdAt: DateTime.now(),
      );

      await _blockRepository.createBlock(block);
      AppLogger.i('Usuario bloqueado exitosamente');
      return true;
    } catch (e) {
      AppLogger.e('Error al bloquear usuario', e);
      return false;
    }
  }

  /// Desbloquea a un usuario
  Future<bool> unblockUser({
    required String blockerId,
    required String blockedUserId,
  }) async {
    try {
      await _blockRepository.removeBlock(blockerId, blockedUserId);
      AppLogger.i('Usuario desbloqueado exitosamente');
      return true;
    } catch (e) {
      AppLogger.e('Error al desbloquear usuario', e);
      return false;
    }
  }

  /// Verifica si un usuario está bloqueado
  Future<bool> isUserBlocked(String blockerId, String blockedUserId) async {
    try {
      return await _blockRepository.isBlocked(blockerId, blockedUserId);
    } catch (e) {
      AppLogger.e('Error al verificar bloqueo', e);
      return false;
    }
  }

  /// Obtiene la lista de IDs de usuarios bloqueados
  Future<List<String>> getBlockedUserIds(String blockerId) async {
    try {
      return await _blockRepository.getBlockedUserIds(blockerId);
    } catch (e) {
      AppLogger.e('Error al obtener usuarios bloqueados', e);
      return [];
    }
  }

  /// Filtra trabajos/usuarios bloqueados de una lista
  Future<List<T>> filterBlockedUsers<T>({
    required String currentUserId,
    required List<T> items,
    required String Function(T) getUserId,
  }) async {
    try {
      final blockedIds = await getBlockedUserIds(currentUserId);
      if (blockedIds.isEmpty) return items;

      return items.where((item) {
        final userId = getUserId(item);
        return !blockedIds.contains(userId);
      }).toList();
    } catch (e) {
      AppLogger.e('Error al filtrar usuarios bloqueados', e);
      return items; // En caso de error, retornar lista completa
    }
  }
}

