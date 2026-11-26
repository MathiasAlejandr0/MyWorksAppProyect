"""Escaneo liviano (regex) de clases Dart de lib/ para generar tests de humo.

No es un parser completo: reconoce clases, constructores, métodos y getters
públicos y sus parámetros con la indentación estándar de `dart format`.
"""
import os, re, json, pathlib

ROOT = str(pathlib.Path(__file__).resolve().parents[2])
LIB = ROOT + '/lib'


def block(src, i):
    """Devuelve (inicio, fin) del bloque {...} que empieza en o después de i."""
    i = src.index('{', i)
    d = 0
    j = i
    in_s = None
    while j < len(src):
        c = src[j]
        if in_s:
            if c == '\\':
                j += 2
                continue
            if src.startswith(in_s, j):
                j += len(in_s)
                in_s = None
                continue
        else:
            if src.startswith("'''", j) or src.startswith('"""', j):
                in_s = src[j:j + 3]
                j += 3
                continue
            if c in '\'"':
                in_s = c
            elif c == '/' and src.startswith('//', j):
                j = src.find('\n', j)
                if j < 0:
                    break
                continue
            elif c == '{':
                d += 1
            elif c == '}':
                d -= 1
                if d == 0:
                    return i, j + 1
        j += 1
    return i, len(src)


def parens(src, i):
    """src[i] == '(' -> índice del ')' que cierra."""
    d = 0
    for j in range(i, len(src)):
        if src[j] in '([{<' and not (src[j] == '<' and src[j - 1] == ' '):
            if src[j] in '([{':
                d += 1
        elif src[j] in ')]}':
            d -= 1
            if d == 0:
                return j
    return len(src)


def split_top(s):
    out, d, cur = [], 0, ''
    for c in s:
        if c in '(<[{':
            d += 1
        elif c in ')>]}':
            d -= 1
        if c == ',' and d == 0:
            out.append(cur)
            cur = ''
        else:
            cur += c
    if cur.strip():
        out.append(cur)
    return [x.strip() for x in out if x.strip()]


def parse_params(s):
    """Lista de dicts: name, type, kind(pos|opt|named), required, has_default."""
    res = []
    s = s.strip()
    kind = 'pos'
    parts = []
    # separa posicionales de {named} o [opt]
    d = 0
    cur = ''
    for c in s:
        if c in '{[' and d == 0:
            if cur.strip():
                parts.append(('pos', cur))
            cur = ''
            kind = 'named' if c == '{' else 'opt'
            d += 1
            continue
        if c in '([{<':
            d += 1
        if c in ')]}>':
            d -= 1
            if d == 0 and c in '}]':
                parts.append((kind, cur))
                cur = ''
                continue
        cur += c
    if cur.strip():
        parts.append((kind if d else 'pos', cur))
    for k, chunk in parts:
        for p in split_top(chunk):
            p = re.sub(r'@\w+(\([^)]*\))?\s*', '', p).strip()
            req = p.startswith('required ')
            if req:
                p = p[len('required '):].strip()
            default = None
            if '=' in p:
                p, default = p.split('=', 1)
                p = p.strip()
            p = p.replace('final ', '').replace('covariant ', '').strip()
            m = re.match(r'^(.*?)\s*\b(\w+)$', p, re.S)
            if not m:
                continue
            typ, name = m.group(1).strip(), m.group(2)
            if typ.startswith('this.') or name and typ == '' and p.startswith('this.'):
                typ = 'this'
            if p.startswith('this.') or p.startswith('super.'):
                typ = 'this'
                name = p.split('.', 1)[1]
            res.append(dict(name=name, type=typ or 'dynamic', kind=k,
                            required=req or k == 'pos',
                            has_default=default is not None))
    return res


DECL = re.compile(
    r'^  (static\s+)?(?:(?:external|abstract|override)\s+)?'
    r'((?:Future|FutureOr|Stream|List|Map|Set|Iterable)<.*?>\??|[\w.]+(?:<[^()]*?>)?\??|void)\s+'
    r'(\w+)\s*(<[^()]*>)?\s*\(', re.M)
GETTER = re.compile(r'^  (static\s+)?(?:[\w.<>?, ]+)\s+get\s+(\w+)\s*(=>|\{)', re.M)


def scan_class(src, name, body_start, body_end, abstract):
    body = src[body_start:body_end]
    # solo profundidad 1: blanquea bloques internos
    flat = list(body)
    d = 0
    for idx, c in enumerate(body):
        if c == '{':
            d += 1
        elif c == '}':
            d -= 1
    methods, getters, ctors = [], [], []
    for m in DECL.finditer(body):
        static, ret, mname = bool(m.group(1)), m.group(2), m.group(3)
        if mname in ('if', 'for', 'while', 'switch', 'return', 'catch', 'Function'):
            continue
        open_i = m.end() - 1
        close_i = parens(body, open_i)
        params = parse_params(body[open_i + 1:close_i])
        methods.append(dict(name=mname, static=static, ret=ret,
                            params=params))
    for m in re.finditer(r'^  (const\s+)?(factory\s+)?' + name + r'(\.\w+)?\s*\(', body, re.M):
        open_i = m.end() - 1
        close_i = parens(body, open_i)
        ctors.append(dict(named=(m.group(3) or '')[1:], factory=bool(m.group(2)),
                          const=bool(m.group(1)),
                          params=parse_params(body[open_i + 1:close_i])))
    for m in GETTER.finditer(body):
        getters.append(dict(name=m.group(2), static=bool(m.group(1))))
    fields = {}
    for fm in re.finditer(r'^  (?:late\s+)?final\s+(.+?)\s+(\w+)\s*[;=]', body, re.M):
        fields[fm.group(2)] = fm.group(1).strip()
    for c in ctors:
        for prm in c['params']:
            if prm['type'] == 'this':
                prm['type'] = fields.get(prm['name'], 'dynamic')
    methods = [x for x in methods if x['name'] != name]
    inst = None
    if re.search(r'static\s+(final\s+)?' + name + r'\??\s+(get\s+)?instance\b', body) or \
       re.search(r'static\s+' + name + r'\s+get\s+instance', body):
        inst = 'instance'
    return dict(methods=methods, getters=getters, ctors=ctors, instance=inst)


def scan_file(path):
    src = open(path, encoding='utf-8').read()
    out = []
    for m in re.finditer(r'^(abstract\s+|sealed\s+|final\s+|base\s+|interface\s+|mixin\s+)*class\s+(\w+)([^{]*)\{', src, re.M):
        mods, name, ext = m.group(1) or '', m.group(2), m.group(3)
        s, e = block(src, m.end() - 1)
        info = scan_class(src, name, s + 1, e - 1, 'abstract' in mods)
        info.update(name=name, ext=ext.strip(), abstract=bool(re.search(r'abstract|sealed|interface', mods)),
                    private=name.startswith('_'))
        out.append(info)
    enums = re.findall(r'^enum\s+(\w+)', src, re.M)
    typedefs = re.findall(r'^typedef\s+(\w+)(?:<[^=]*>)?\s*=\s*(.*?);', src, re.M)
    return dict(classes=out, enums=enums, typedefs=typedefs)


def scan_all():
    res = {}
    for dp, _, fs in os.walk(LIB):
        for f in fs:
            if f.endswith('.dart') and not f.endswith('.g.dart'):
                p = os.path.join(dp, f)
                rel = p[len(LIB) + 1:]
                src = open(p, encoding='utf-8').read()
                if re.search(r'^part of', src, re.M):
                    continue
                res[rel] = scan_file(p)
    return res


if __name__ == '__main__':
    r = scan_all()
    os.makedirs(ROOT + '/build', exist_ok=True)
    json.dump(r, open(ROOT + '/build/scan.json', 'w'), indent=1)
    print(sum(len(v['classes']) for v in r.values()), 'clases')
