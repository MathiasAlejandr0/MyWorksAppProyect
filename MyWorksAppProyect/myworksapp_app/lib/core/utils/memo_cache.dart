import 'dart:async';

/// Caché en memoria por clave con vencimiento.
///
/// - Si llegan varias pedidas iguales al mismo tiempo, comparten el mismo
///   Future (una sola request a Supabase).
/// - Si la request falla, no queda guardada: la próxima vuelve a intentar.
class MemoCache<T> {
  MemoCache({required this.ttl, DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final Duration ttl;
  final DateTime Function() _now;
  final Map<String, _Entry<T>> _entries = {};

  Future<T> get(String key, Future<T> Function() load) {
    final hit = _entries[key];
    if (hit != null && _now().isBefore(hit.expiresAt)) return hit.value;
    final future = load();
    _entries[key] = _Entry(future, _now().add(ttl));
    unawaited(
      future.then<void>(
        (_) {},
        onError: (Object _, StackTrace __) {
          if (identical(_entries[key]?.value, future)) _entries.remove(key);
        },
      ),
    );
    return future;
  }

  void invalidate(String key) => _entries.remove(key);

  void clear() => _entries.clear();
}

class _Entry<T> {
  _Entry(this.value, this.expiresAt);
  final Future<T> value;
  final DateTime expiresAt;
}
