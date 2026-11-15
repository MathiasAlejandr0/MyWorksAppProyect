import 'dart:async';

/// Utilidad para debounce de funciones
/// 
/// Útil para búsquedas, validaciones y otras operaciones
/// que no deben ejecutarse en cada cambio de input.
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  /// Ejecuta la función después del delay
  /// 
  /// Si se llama nuevamente antes de que expire el delay,
  /// cancela la ejecución anterior y reinicia el timer.
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancela la ejecución pendiente
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Verifica si hay una ejecución pendiente
  bool get isPending => _timer?.isActive ?? false;

  /// Libera recursos
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

