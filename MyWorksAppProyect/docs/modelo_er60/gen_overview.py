import importlib.util, subprocess, re
from pathlib import Path
spec = importlib.util.spec_from_file_location('e', Path(__file__).with_name('gen_er60.py'))
src = Path(__file__).with_name('gen_er60.py').read_text()
# reutiliza DOM sin regenerar figuras
ns = {"__file__": str(Path(__file__).with_name("gen_er60.py"))}
exec(src.split("manifest = []")[0], ns)
DOM, esc, fks = ns["DOM"], ns["esc"], ns["fks"]; FONT = "Roboto Condensed"
out = ['digraph g {', f'graph [fontname="{FONT}", bgcolor="white", pad="0.05", nodesep="0.18", ranksep="0.25", rankdir="TB"];',
       f'node [shape=plaintext, fontname="{FONT}"]; edge [style="invis"];']
for k, n, color, bg, ts in DOM:
    nint = sum(1 for f in fks if f['t'] in ts and f['rt'] in ts and f['t'] != f['rt'])
    filas = ''.join(f'<tr><td align="left" bgcolor="white"><font point-size="9">{esc(t)}</font></td></tr>' for t in ts)
    out.append(f'"{k}" [label=<<table border="2" cellborder="0" cellspacing="0" cellpadding="1" color="{color}">'
               f'<tr><td bgcolor="{color}" align="left"><font color="white" point-size="11"><b>{esc(ns["g"].CORTO[k])}</b></font></td></tr>'
               f'<tr><td bgcolor="{bg}" align="left"><font point-size="9">{len(ts)} tablas</font></td></tr>{filas}</table>>];')
nota = ('<table border="1" cellborder="0" cellspacing="0" cellpadding="3" color="#7F7F7F" style="dashed">'
        '<tr><td align="left"><font point-size="10"><b>Cómo leer este mapa</b></font></td></tr>'
        '<tr><td align="left"><font point-size="9">60 tablas del esquema public en 7 dominios.</font></td></tr>'
        '<tr><td align="left"><font point-size="9">perfiles es el centro: la referencian</font></td></tr>'
        '<tr><td align="left"><font point-size="9">tablas de todos los dominios.</font></td></tr>'
        '<tr><td align="left"><font point-size="9">perfiles.id = auth.users.id (Supabase Auth).</font></td></tr>'
        '<tr><td align="left"><font point-size="9">Las relaciones y claves de cada dominio</font></td></tr>'
        '<tr><td align="left"><font point-size="9">están en las figuras A-1 a A-11 (Anexo A).</font></td></tr></table>')
out.append(f'nota [label=<{nota}>];')
keys = [d[0] for d in DOM]
out.append('{rank="same"; ' + '; '.join(f'"{k}"' for k in keys[:4]) + ';}')
out.append('{rank="same"; ' + '; '.join(f'"{k}"' for k in keys[4:]) + '; nota;}')
for a, b in zip(keys[:4], keys[4:] + ['nota']):
    out.append(f'"{a}" -> "{b}";')
out.append('}')
dot = '\n'.join(out)
OUT = Path(__file__).with_name('figuras')
(OUT / 'er60_00_mapa_dominios.dot').write_text(dot)
svg = subprocess.run(['dot', '-Tsvg'], input=dot, capture_output=True, text=True, check=True).stdout
(OUT / 'er60_00_mapa_dominios.svg').write_text(svg)
print(re.search(r'width="([\d.]+)pt" height="([\d.]+)pt"', svg).groups())
subprocess.run(['dot', '-Tpng', '-Gdpi=300', '-o', str(OUT / 'er60_00_mapa_dominios.png')], input=dot, text=True, check=True)
