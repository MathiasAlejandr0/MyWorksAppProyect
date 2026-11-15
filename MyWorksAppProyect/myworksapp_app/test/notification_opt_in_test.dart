import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/services/notification_opt_in.dart';

class _ScriptedPermission implements NotificationPermissionClient {
  _ScriptedPermission(this.outcome);
  final NotificationPermissionOutcome outcome;

  @override
  Future<NotificationPermissionOutcome> request() async => outcome;
}

void main() {
  test('al activar notificaciones devuelve el resultado del sistema', () async {
    final granted = await NotificationOptIn(
      _ScriptedPermission(NotificationPermissionOutcome.granted),
    ).enable();
    final blocked = await NotificationOptIn(
      _ScriptedPermission(NotificationPermissionOutcome.permanentlyDenied),
    ).enable();
    expect(granted, NotificationPermissionOutcome.granted);
    expect(blocked, NotificationPermissionOutcome.permanentlyDenied);
  });
}
