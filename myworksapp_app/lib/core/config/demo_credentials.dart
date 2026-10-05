/// Credenciales de demostración — SOLO desarrollo (`kDebugMode`).
///
/// Nunca autocompletar en release. Son las cuentas del seed
/// `scripts/demo/seed_demo.sql` (ver DEMO.md); producción no debe tenerlas.
///
/// Las cuentas antiguas `@demo.com` / `demo123` quedaron fuera: el administrador
/// legado está suspendido (migración 20261008000012) y la contraseña estaba
/// publicada en el repo.
class DemoCredentials {
  static const demoPassword = 'Demo2026!';

  static const userEmail = 'camila.soto@demo.myworksapp.cl';
  static const userName = 'Camila Soto';

  static const adminEmail = 'admin.ops@demo.myworksapp.cl';
  static const adminName = 'Valentina Riquelme';

  static const workerEmail = 'carmen.lagos@demo.myworksapp.cl';
  static const workerName = 'Carmen Lagos';

  static const extraWorkerEmails = [
    'pedro.rojas@demo.myworksapp.cl',
    'maria.fuentes@demo.myworksapp.cl',
  ];
}
