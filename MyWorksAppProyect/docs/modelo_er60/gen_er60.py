# Figuras ER (60 tablas) legibles a >= 9 pt impresos: una figura por página apaisada.
import importlib.util, re, subprocess, sys, json
from pathlib import Path
from collections import defaultdict
GEN = Path(__file__).resolve().parents[3] / 'Fase 2' / 'modelo_entidad_relacion' / '_gen_modelo_er.py'
spec = importlib.util.spec_from_file_location('g', GEN); g = importlib.util.module_from_spec(spec); spec.loader.exec_module(g)
OUT = Path(__file__).resolve().parent / 'figuras'; OUT.mkdir(exist_ok=True)
g.SCHEMA = Path(__file__).resolve().parent / '_schema_public_60.json'
DOM = [list(x) for x in g.DOMINIOS]
DOM[0][4] = DOM[0][4] + ['direcciones_cliente']
DOM[6][4] = DOM[6][4] + ['auditoria_consola', 'rate_limit_ventana']
DOM_OF = {t: (k, n, c, bg) for k, n, c, bg, ts in DOM for t in ts}
d, cols, pk, fks, uq = g.cargar()
assert sorted(cols) == sorted(DOM_OF), set(cols) ^ set(DOM_OF)
FONT = g.FONT
W, H = 678, 414   # pt disponibles en la página apaisada (22,9 cm x 13,9 cm)
esc = g.esc

def tipo(c):
    ty = c['ty']
    if ty == 'USER-DEFINED':
        return 'enum'
    return g.tshort(ty)

def nodo(t, color, bg, fkcols, extfk=None):
    extfk = extfk or {}
    todas = cols[t]
    cs = [c for c in todas if c['c'] in pk.get(t, []) or c['c'] in fkcols.get(t, set())]
    resto = len(todas) - len(cs)
    def celdas(c):
        tags = []
        if c['c'] in pk.get(t, []): tags.append('PK')
        if c['c'] in fkcols.get(t, set()): tags.append('FK')
        name = esc(c['c'])
        if 'PK' in tags: name = f'<b><u>{name}</u></b>'
        elif 'FK' in tags: name = f'<i>{name}</i>'
        nn = '' if c['nn'] or 'PK' in tags else '?'
        cbg = bg if tags else 'white'
        tag = ','.join(tags) or ' '
        return (f'<td align="left" bgcolor="{cbg}"><font point-size="9" color="#555555">{tag}</font></td>'
                f'<td align="left" bgcolor="{cbg}"><font point-size="10">{name}</font></td>'
                f'<td align="left" bgcolor="{cbg}"><font point-size="9" color="#444444">{esc(tipo(c))}{nn}</font>'
                + (f'<font point-size="9" color="#7A1F1F"> → {esc(extfk[c["c"]])}</font>' if c['c'] in extfk else '') + '</td>')
    ng = 1
    per = -(-len(cs) // ng)
    grupos = [cs[i*per:(i+1)*per] for i in range(ng)]
    rows = []
    for i in range(per):
        parts = []
        for j, gr in enumerate(grupos):
            if j: parts.append('<td width="6"></td>')
            parts.append(celdas(gr[i]) if i < len(gr) else '<td></td><td></td><td></td>')
        rows.append('<tr>' + ''.join(parts) + '</tr>')
    span = 3 * ng + (ng - 1)
    if resto:
        rows.append(f'<tr><td colspan="{span}" align="left"><font point-size="9" color="#555555">+ {resto} atributo{"s" if resto > 1 else ""} más (diccionario)</font></td></tr>')
    head = (f'<tr><td colspan="{span}" bgcolor="{color}" align="left">'
            f'<font color="white" point-size="11"><b>{esc(t)}</b></font></td></tr>')
    return (f'"{t}" [label=<<table border="1" cellborder="0" cellspacing="0" cellpadding="1" color="{color}">'
            + head + ''.join(rows) + '</table>>];')

def externo(t):
    lab = 'auth.users' if t == 'users' else t
    sub = 'esquema auth' if t == 'users' else 'en otra figura'
    return (f'"{t}" [label=<<table border="1" cellborder="0" cellspacing="0" cellpadding="2" color="#7F7F7F" style="dashed">'
            f'<tr><td bgcolor="#EFEFEF"><font point-size="10" color="#333333"><b>{esc(lab)}</b></font></td></tr>'
            f'<tr><td><font point-size="9" color="#555555">{sub}</font></td></tr></table>>];')

def dot_chunk(title, color, bg, tablas, rankdir, wrap=1):
    fkcols = defaultdict(set)
    for f in fks: fkcols[f['t']].update(f['cols'])
    out = [f'digraph x {{', f'graph [fontname="{FONT}", bgcolor="white", pad="0.05", nodesep="0.25", ranksep="0.4", splines="spline", rankdir="{rankdir}", labelloc="t", labeljust="l"];',
           f'node [shape=plaintext, fontname="{FONT}"]; edge [fontname="{FONT}", color="{color}", penwidth="1.3", arrowsize="0.8", dir="both"];']
    pares = defaultdict(list); extfk = defaultdict(dict)
    for f in fks:
        if f['t'] in tablas:
            rt = f['rt']
            if rt in tablas and rt != f['t']:
                pares[(f['t'], rt)].append(f)
            else:
                nombre = 'auth.users' if rt == 'users' else rt
                for c in f['cols']: extfk[f['t']][c] = nombre
    for t in tablas: out.append(nodo(t, color, bg, fkcols, extfk[t]))
    for (a, b), fs in pares.items():
        porcard = defaultdict(list)
        for f in fs:
            porcard[g.cardinalidad(f, cols, pk, uq)].append(f)
        for ((hl, ha), (pl, pa)), grupo in porcard.items():
            lab = ', '.join(c for f in grupo for c in f['cols'])
            out.append(f'"{a}" -> "{b}" [arrowtail="{ha}", arrowhead="{pa}", label=<<font point-size="9" color="#555555">{esc(lab)}</font>>];')
    if wrap > 1:
        conect = {x for ab in pares for x in ab}
        sueltas = [t for t in tablas if t not in conect]
        for i in range(0, len(sueltas), wrap):
            col_ = sueltas[i:i+wrap]
            for a, b in zip(col_, col_[1:]):
                out.append(f'"{a}" -> "{b}" [style="invis", dir="none"];')
    out.append('}')
    return '\n'.join(out)

def size(dot):
    svg = subprocess.run(['dot', '-Tsvg'], input=dot, capture_output=True, text=True, check=True).stdout
    w = float(re.search(r'width="([\d.]+)pt"', svg).group(1)); h = float(re.search(r'height="([\d.]+)pt"', svg).group(1))
    return w, h

def fits(tablas, color, bg):
    best = None
    for rd, wr in (('LR', 1), ('TB', 1), ('LR', 2), ('TB', 2), ('LR', 3), ('TB', 3), ('LR', 4), ('TB', 4), ('LR', 5), ('TB', 5), ('LR', 6), ('TB', 6)):
        dt = dot_chunk('', color, bg, tablas, rd, wr); w, h = size(dt)
        if w <= W and h <= H and (best is None or w * h < best[1] * best[2]):
            best = (rd + str(wr), w, h, dt)
    return best

def chunks(ts, color, bg):
    # agrupa en orden; el centro del dominio (más referenciado) va en cada grupo cuando cabe
    res, cur = [], []
    for t in ts:
        trial = cur + [t]
        if fits(trial, color, bg): cur = trial
        else:
            if not cur: sys.exit(f'{t} no cabe sola')
            res.append(cur); cur = [t]
    if cur: res.append(cur)
    return res

GRUPOS = {
 '01_usuarios_territorio': [['perfiles','codigos_restablecimiento','consentimientos_usuario','dispositivos_push','suscripciones','bloqueos_usuario'],['direcciones_cliente','verificacion_eventos','paises','regiones','comunas']],
 '02_profesionales_catalogo': [['trabajadores','trabajador_precios','trabajador_horarios','trabajador_horas_publicadas','trabajador_servicios_extra','trabajador_servicios'],['categorias_servicio','servicios','configuraciones_servicio','portafolio_trabajador','impulsos']],
 '03_trabajos_reservas': [['trabajos','propuestas_cotizacion','propuesta_cotizacion_items','acuerdos_trabajo','cancelaciones_trabajo','reprogramaciones_trabajo'],['pines_inicio_trabajo','bloqueos_pin_inicio','intentos_pin_inicio','fotos_trabajo','ubicacion_en_vivo']],
 '04_pagos_escrow': [['pagos','ordenes_cambio','liquidaciones','metodos_pago_oneclick','cuentas_bancarias']],
 '05_comunicacion_disputas': [['disputas','disputa_mensajes','mensajes','notificaciones','tickets_soporte']],
 '06_calificaciones_ranking': [['calificaciones','senales_resena','calificaciones_cliente','eventos_ranking','ranking_aprendizaje','ranking_config']],
 '07_admin_auditoria': [['auditoria_consola','rate_limit_ventana','app_config','banderas_funcionalidad','acciones_pendientes','reportes'],['eventos_abuso','registros_error_app','eventos_analitica','encuestas_testing','encuesta_testing_respuestas']],
}
ORDEN = {
 '01_usuarios_territorio': ['perfiles','codigos_restablecimiento','consentimientos_usuario','dispositivos_push','suscripciones','bloqueos_usuario','direcciones_cliente','verificacion_eventos','paises','regiones','comunas'],
 '02_profesionales_catalogo': ['trabajadores','trabajador_precios','trabajador_horarios','trabajador_horas_publicadas','trabajador_servicios_extra','trabajador_servicios','categorias_servicio','servicios','configuraciones_servicio','portafolio_trabajador','impulsos'],
 '03_trabajos_reservas': ['trabajos','propuestas_cotizacion','propuesta_cotizacion_items','acuerdos_trabajo','cancelaciones_trabajo','reprogramaciones_trabajo','pines_inicio_trabajo','bloqueos_pin_inicio','intentos_pin_inicio','fotos_trabajo','ubicacion_en_vivo'],
 '04_pagos_escrow': ['pagos','ordenes_cambio','liquidaciones','metodos_pago_oneclick','cuentas_bancarias'],
 '05_comunicacion_disputas': ['disputas','disputa_mensajes','mensajes','notificaciones','tickets_soporte'],
 '06_calificaciones_ranking': ['calificaciones','senales_resena','calificaciones_cliente','eventos_ranking','ranking_aprendizaje','ranking_config'],
 '07_admin_auditoria': ['auditoria_consola','rate_limit_ventana','app_config','banderas_funcionalidad','acciones_pendientes','reportes','eventos_abuso','registros_error_app','eventos_analitica','encuestas_testing','encuesta_testing_respuestas'],
}
manifest = []
for k, n, color, bg, ts in DOM:
    orden = ORDEN[k]; assert sorted(orden) == sorted(ts), (k, set(orden) ^ set(ts))
    parts = []
    for gr in ([ORDEN[k]] if fits(ORDEN[k], color, bg) else GRUPOS[k]):
        if fits(gr, color, bg): parts.append(gr)
        else:
            for rd in ('LR','TB'):
                print('  NO CABE', k, rd, [round(x) for x in size(dot_chunk('', color, bg, gr, rd))], gr)
            parts += chunks(gr, color, bg)
    assert sorted(sum(parts, [])) == sorted(ts)
    for i, p in enumerate(parts, 1):
        rd, w, h, dt = fits(p, color, bg)
        name = f'er60_{k}_{i}'
        (OUT / f'{name}.dot').write_text(dt)
        subprocess.run(['dot', '-Tsvg', '-o', str(OUT / f'{name}.svg')], input=dt, text=True, check=True)
        subprocess.run(['dot', '-Tpng', '-Gdpi=300', '-o', str(OUT / f'{name}.png')], input=dt, text=True, check=True)
        manifest.append({'file': f'{name}.png', 'dominio': n, 'parte': i, 'partes': len(parts), 'tablas': p, 'w_pt': w, 'h_pt': h, 'rankdir': rd})
        print(name, rd, round(w), round(h), p)
json.dump(manifest, open(OUT / 'manifest.json', 'w'), ensure_ascii=False, indent=1)
