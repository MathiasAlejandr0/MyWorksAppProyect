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
over = {k: uni[k] for k in ('id', 'estado', 'id_usuario', 'rol', 'nombre', 'correo', 'email')}
L.append('')
L.append('/// Fila de ejemplo por tabla: universal + el modelo que la lee.')
L.append('final Map<String, Map<String, dynamic>> tableRows = {')
for tb in sorted(votes):
    best = [c for c, _ in votes[tb].most_common() if c in names]
    parts = ['...universalRow']
    if best:
        parts.append('...sample%s' % best[0])
    parts.append('...' + lit(over)[len('<String, dynamic>'):])
    L.append("  '%s': {%s}," % (tb, ', '.join(parts)))
L.append('};')
open(ROOT + '/test/support/model_samples.dart', 'w').write('\n'.join(L) + '\n')
print('ok', len(t), len(uni))
