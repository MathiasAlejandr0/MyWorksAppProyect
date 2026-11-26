"""Genera test/support/model_samples.dart a partir de build/models.json."""
import json, pathlib
ROOT = str(pathlib.Path(__file__).resolve().parents[2])
t = json.load(open(ROOT + '/build/models.json'))


def lit(v):
    if isinstance(v, dict):
        return '<String, dynamic>{' + ', '.join(lit(k) + ': ' + lit(w) for k, w in v.items()) + '}'
    if isinstance(v, list):
        return '<dynamic>[' + ', '.join(lit(w) for w in v) + ']'
    if isinstance(v, bool):
        return 'true' if v else 'false'
    if isinstance(v, str):
        return "'" + v.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$') + "'"
    return json.dumps(v)


L = ['// GENERADO por scripts/cobertura/gen_samples.py. No editar a mano.',
     '// Mapas de ejemplo (como vienen de la base) para cada modelo.', '']
# Coordenadas reales (Puerto Montt): un valor genérico como 1000 deja a los
# profesionales fuera de radio y rompe los límites del mapa.
GEO = {'latitud': -41.4693, 'longitud': -72.9424, 'latitude': -41.4693,
       'longitude': -72.9424, 'latitud_base': -41.4693, 'longitud_base': -72.9424,
       'radio_servicio_km': 25.0, 'radio_urbano_km': 10.0}
uni = {}
for x in t:
    for k in GEO:
        if k in x['sample']:
            x['sample'][k] = GEO[k]
    L.append('final sample%s = %s;' % (x['cls'], lit(x['sample'])))
    for k, v in x['sample'].items():
        uni.setdefault(k, v)
uni.update({'id': '00000000-0000-4000-8000-0000000000aa', 'estado': 'pendiente',
            'id_usuario': '00000000-0000-4000-8000-000000000001',
            'rol': 'cliente', 'nombre': 'Ana Pérez', 'correo': 'ana@test.invalid',
            'email': 'ana@test.invalid'})
uni.update({k: v for k, v in GEO.items() if k in uni})
L.append('')
L.append('/// Fila "universal": une las claves de todos los modelos.')
L.append('final universalRow = %s;' % lit(uni))

# tabla -> modelo que la lee (por votos en lib/)
import re, os, collections
votes = collections.defaultdict(collections.Counter)
for dp, _, fs in os.walk(ROOT + '/lib'):
    for f in fs:
        if not f.endswith('.dart'):
            continue
        src = open(os.path.join(dp, f)).read()
        consts = dict(re.findall(r"static const (?:String )?(_\w+)\s*=\s*'(\w+)'", src))
        for m in re.finditer(r"\.from\(\s*(?:'(\w+)'|(_\w+))\s*\)", src):
            tb = m.group(1) or consts.get(m.group(2))
            if not tb:
                continue
            win = src[m.end():m.end() + 900]
            mm = re.search(r"(\w+)\.(fromMap|fromJson|fromRow)\(", win)
            votes[tb][mm.group(1) if mm else None] += 1
names = {x['cls'] for x in t}
# Columnas con contenido realista (JSON) que un valor genérico no ejercita.
_SCHEMA = json.dumps({
    'fields': [
        {'name': 'detalle', 'type': 'text', 'label': 'Detalle', 'required': True},
        {'name': 'tipo', 'type': 'select', 'label': 'Tipo', 'required': True,
         'options': ['Básico', 'Completo']},
        {'name': 'cantidad', 'type': 'number', 'label': 'Cantidad', 'required': True},
        {'name': 'urgente', 'type': 'boolean', 'label': 'Urgente'},
        {'name': 'otro', 'type': 'desconocido'},
    ],
    'variants': [
        {'id': 'basica', 'name': 'Básica', 'price': 15000},
        {'id': 'premium', 'name': 'Premium', 'price': 30000},
    ],
}, ensure_ascii=False).replace("'", "\\'")
TABLE_EXTRA = {
    'configuraciones_servicio': "...{'esquema_config': '%s'}" % _SCHEMA,
}
over = {k: uni[k] for k in ('id', 'estado', 'id_usuario', 'rol', 'nombre', 'correo', 'email')}
over.update({k: v for k, v in GEO.items() if k in uni})
L.append('')
L.append('/// Fila de ejemplo por tabla: universal + el modelo que la lee.')
L.append('final Map<String, Map<String, dynamic>> tableRows = {')
for tb in sorted(votes):
    best = [c for c, _ in votes[tb].most_common() if c in names]
    parts = ['...universalRow']
    if best:
        parts.append('...sample%s' % best[0])
    parts.append('...' + lit(over)[len('<String, dynamic>'):])
    if tb in TABLE_EXTRA:
        parts.append(TABLE_EXTRA[tb])
    L.append("  '%s': {%s}," % (tb, ', '.join(parts)))
L.append('};')
out = '\n'.join(L) + '\n'
out = out.replace("'esquema_config': 'v_esquema_config'", "'esquema_config': '%s'" % _SCHEMA)
# Valor neutro: evita falsos positivos de escáneres de secretos.
out = out.replace("'v_password'", "'valor_de_prueba'")
open(ROOT + '/test/support/model_samples.dart', 'w').write(out)
print('ok', len(t), len(uni))
