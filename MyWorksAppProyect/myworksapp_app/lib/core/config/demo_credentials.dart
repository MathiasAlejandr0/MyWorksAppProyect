import '../domain/worker_login_item.dart';

/// Credenciales de demostración — SOLO desarrollo (`kDebugMode`).
///
/// Nunca autocompletar en release. Son las cuentas del seed
/// `scripts/demo/seed_demo.sql` (ver DEMO.md); producción no debe tenerlas.
///
/// Las cuentas antiguas `@demo.com` / `demo123` quedaron fuera: el administrador
/// legado está suspendido (migración 20261008000012) y la contraseña estaba
/// publicada en el repo.
class DemoCredentials {
  /// La contraseña de las cuentas demo NO va en el repo (es público).
  /// Solo para depuración local: `--dart-define=DEMO_PASSWORD=...`.
  /// Sin ese define queda vacía y el login no autocompleta la clave.
  static const demoPassword = String.fromEnvironment('DEMO_PASSWORD');
  static const demoEmailDomain = '@demo.myworksapp.cl';

  static bool isDemoEmail(String email) =>
      email.trim().toLowerCase().endsWith(demoEmailDomain);

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

  /// Selector de login si la RPC vuelve vacía (`demo_modo=0`).
  static const loginWorkers = <WorkerLoginItem>[
    WorkerLoginItem(
      userId: '11111111-1111-4111-8111-000000000101',
      name: 'Pedro Rojas',
      email: 'pedro.rojas@demo.myworksapp.cl',
      profession: 'Gasfíter',
      serviceCategory: 'plomeria',
    ),
    WorkerLoginItem(
      userId: '11111111-1111-4111-8111-000000000102',
      name: 'María Fuentes',
      email: 'maria.fuentes@demo.myworksapp.cl',
      profession: 'Electricista',
      serviceCategory: 'electricidad',
    ),
    WorkerLoginItem(
      userId: '11111111-1111-4111-8111-000000000103',
      name: 'José Muñoz',
      email: 'jose.munoz@demo.myworksapp.cl',
      profession: 'Pintor',
      serviceCategory: 'pintura',
    ),
    WorkerLoginItem(
      userId: '11111111-1111-4111-8111-000000000104',
      name: 'Tomás Herrera',
      email: 'tomas.herrera@demo.myworksapp.cl',
      profession: 'Maestro',
      serviceCategory: 'construccion',
    ),
    WorkerLoginItem(
      userId: '11111111-1111-4111-8111-000000000105',
      name: 'Ana Vidal',
      email: 'ana.vidal@demo.myworksapp.cl',
      profession: 'Aseo hogar',
      serviceCategory: 'limpieza',
    ),
    WorkerLoginItem(
      userId: '11111111-1111-4111-8111-000000000107',
      name: 'Diego Salazar',
      email: 'diego.salazar@demo.myworksapp.cl',
      profession: 'Armador de muebles',
      serviceCategory: 'ensamblaje',
    ),
    WorkerLoginItem(
      userId: '11111111-1111-4111-8111-000000000108',
      name: 'Carmen Lagos',
      email: workerEmail,
      profession: 'Gasfíter',
      serviceCategory: 'gasfiteria',
    ),
    WorkerLoginItem(
      userId: '11111111-1111-4111-8111-000000000109',
      name: 'Felipe Araya',
      email: 'felipe.araya@demo.myworksapp.cl',
      profession: 'Jardinero',
      serviceCategory: 'jardineria',
    ),
    WorkerLoginItem(
      userId: '11111111-1111-4111-8111-000000000110',
      name: 'Rodrigo Peña',
      email: 'rodrigo.pena@demo.myworksapp.cl',
      profession: 'Cerrajero',
      serviceCategory: 'cerrajeria',
    ),
    WorkerLoginItem(
      userId: '11111111-1111-4111-8111-000000000111',
      name: 'Isabel Campos',
      email: 'isabel.campos@demo.myworksapp.cl',
      profession: 'Soporte técnico',
      serviceCategory: 'soporte_tecnico',
    ),
    WorkerLoginItem(
      userId: '11111111-1111-4111-8111-000000000112',
      name: 'Hugo Vargas',
      email: 'hugo.vargas@demo.myworksapp.cl',
      profession: 'Mudanzas',
      serviceCategory: 'mudanza',
    ),
    WorkerLoginItem(
      userId: '11111111-1111-4111-8111-000000000113',
      name: 'Paula Riquelme',
      email: 'paula.riquelme@demo.myworksapp.cl',
      profession: 'Climatización',
      serviceCategory: 'climatizacion',
    ),
    WorkerLoginItem(
      userId: '11111111-1111-4111-8111-000000000206',
      name: 'Patricia Oyarzún',
      email: 'patricia.oyarzun@demo.myworksapp.cl',
      profession: 'Gasfíter',
      serviceCategory: 'gasfiteria',
    ),
    WorkerLoginItem(
      userId: '11111111-1111-4111-8111-000000000209',
      name: 'Ricardo Cheuquepán',
      email: 'ricardo.cheuquepan@demo.myworksapp.cl',
      profession: 'Gasfíter',
      serviceCategory: 'gasfiteria',
    ),
  ];
}
