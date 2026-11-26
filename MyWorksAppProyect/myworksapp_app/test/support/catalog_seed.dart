// Catálogo de profesionales cerca de Puerto Montt para pantallas de búsqueda.
import 'fake_supabase.dart';
import 'model_samples.dart';

const catalogServiceId = '00000000-0000-4000-8000-0000000005e1';
const catalogJobId = '00000000-0000-4000-8000-0000000006b1';

String catalogProId(int i) => '00000000-0000-4000-8000-00000000e00$i';

Map<String, dynamic> catalogPro(int i, {double nota = 4.5}) => {
      ...sampleWorkerModel,
      'id': '00000000-0000-4000-8000-00000000d00$i',
      'id_usuario': catalogProId(i),
      'profesion': i.isEven ? 'Electricista' : 'Gasfíter',
      'descripcion': 'Profesional $i con experiencia',
      'calificacion': nota,
      'rating': nota,
      'tarifa_visita': 10000 + i * 2500,
      'disponible': 1,
      'precios_configurados': 1,
      'categoria_servicio': 'plomeria',
      'zona_trabajo': 'Puerto Montt',
      'latitud_base': -41.4693 + i * 0.004,
      'longitud_base': -72.9424 + i * 0.003,
      'radio_servicio_km': 15,
      'ultima_actividad': DateTime.now().toUtc().toIso8601String(),
    };

/// Siembra el catálogo; [ocupados] marca profesionales con trabajo activo.
void seedCatalog(FakeBackend b, {int n = 3, Set<String> ocupados = const {}}) {
  final pros = [
    for (var i = 1; i <= n; i++) catalogPro(i, nota: 3.5 + i * 0.4)
  ];
  b.rpc('listar_profesionales_catalogo', pros);
  b.seed('trabajadores', pros);
  b.rpc('profesionales_ocupados', [
    for (final id in ocupados) {'id': id}
  ]);
  b.rpc('perfiles_publicos_por_ids', [
    for (var i = 1; i <= n; i++)
      {
        ...sampleUserModel,
        'id': catalogProId(i),
        'nombre': 'Pro Número $i',
        'ultimo_acceso': DateTime.now().toUtc().toIso8601String(),
      },
  ]);
  b.rpc('stats_profesionales', <Object>[]);
  b.seed('servicios', [
    {
      ...sampleServiceModel,
      'id': catalogServiceId,
      'nombre': 'Gasfitería',
      'categoria': 'plomeria',
      'activo': 1,
    },
  ]);
  b.seed('trabajos', [
    {
      ...universalRow,
      'id': catalogJobId,
      'id_servicio': catalogServiceId,
      'id_usuario': fakeUserId,
      'estado': 'pendiente',
      'latitud': -41.4693,
      'longitud': -72.9424,
    },
  ]);
}
