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
uni = {}
for x in t:
    L.append('final sample%s = %s;' % (x['cls'], lit(x['sample'])))
    for k, v in x['sample'].items():
        uni.setdefault(k, v)
uni.update({'id': '00000000-0000-4000-8000-0000000000aa', 'estado': 'pendiente',
            'id_usuario': '00000000-0000-4000-8000-000000000001',
            'rol': 'cliente', 'nombre': 'Ana Pérez', 'correo': 'ana@test.invalid',
            'email': 'ana@test.invalid'})
L.append('')
L.append('/// Fila "universal": une las claves de todos los modelos.')
L.append('final universalRow = %s;' % lit(uni))
open(ROOT + '/test/support/model_samples.dart', 'w').write('\n'.join(L) + '\n')
print('ok', len(t), len(uni))
