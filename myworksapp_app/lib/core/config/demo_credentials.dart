/// Credenciales de demostración — SOLO desarrollo (`kDebugMode`).
///
/// Nunca autocompletar en release. Seeds de staging documentados en DEMO.md;
/// producción no debe tener estas cuentas.
class DemoCredentials {
  static const demoPassword = 'demo123';

  static const userEmail = 'usuario@demo.com';
  static const userName = 'Carlos Usuario';

  static const adminEmail = 'admin@demo.com';
  static const adminName = 'Admin Demo';

  static const workerEmail = 'trabajador@demo.com';
  static const workerName = 'Juan Electricista';

  static const extraWorkerEmails = [
    'pedro@demo.com',
    'maria@demo.com',
  ];
}
