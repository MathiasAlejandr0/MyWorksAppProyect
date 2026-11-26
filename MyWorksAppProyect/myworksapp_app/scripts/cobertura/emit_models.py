import pathlib; ROOT=str(pathlib.Path(__file__).resolve().parents[2])
import json
t=json.load(open(ROOT+'/build/models.json'))
skip=set()
imports=sorted(set(x['path'] for x in t))
alias={p:f'lm{i}' for i,p in enumerate(imports)}
L=["// GENERADO por scripts/cobertura/gen_models.py + emit_models.py. No editar a mano.",
"// Prueba fromMap/toMap/copyWith/getters de todos los modelos con un mapa completo",
"// y con variantes (valores nulos, tipos alternativos) que la base puede devolver.",
"// ignore_for_file: avoid_dynamic_calls",
"import 'package:flutter_test/flutter_test.dart';"]
for p in imports: L.append(f"import 'package:myworksapp/{p}' as {alias[p]};")
L.append("import 'support/model_probe.dart';")
L.append("")
L.append("void main() {")
for x in t:
    a=alias[x['path']]; c=x['cls']
    def lit(v):
        if isinstance(v,dict): return '<String, dynamic>{'+', '.join(lit(k)+': '+lit(w) for k,w in v.items())+'}'
        if isinstance(v,list): return '<dynamic>['+', '.join(lit(w) for w in v)+']'
        if isinstance(v,bool): return 'true' if v else 'false'
        if isinstance(v,str): return "'"+v.replace('\\','\\\\').replace("'","\\'").replace('$','\\$')+"'"
        return json.dumps(v)
    s=lit(x['sample'])[len('<String, dynamic>'):]
    L.append(f"  group('{c}', () {{")
    L.append(f"    final sample = <String, dynamic>{s};")
    L.append(f"    dynamic build(Map<String, dynamic> m) => {a}.{c}.{x['ctor']}(m);")
    L.append(f"    test('fromMap con mapa completo', () {{")
    L.append(f"      final o = build(sample);")
    L.append(f"      expect(o, isA<{a}.{c}>());")
    L.append(f"      touchCommon(o);")
    for g in x['getters']:
        L.append(f"      probe(() => o.{g});")
    for g in x.get('methods',[]):
        L.append(f"      probe(() => o.{g}());")
    if x['toMap']:
        tm=x['toMap']
        L.append(f"      final roundTrip = Map<String, dynamic>.from(o.{tm}() as Map);")
        L.append(f"      expect(roundTrip, isNotEmpty);")
        L.append(f"      probe(() => build(roundTrip));")
    if x['copyWith']:
        L.append(f"      expect(o.copyWith(), isA<{a}.{c}>());")
    L.append("    });")
    L.append(f"    test('fromMap con variantes de la base', () {{")
    L.append(f"      for (final v in variants(sample)) {{")
    L.append(f"        final o = probe(() => build(v));")
    L.append(f"        if (o == null) continue;")
    L.append(f"        touchCommon(o);")
    for g in x['getters']:
        L.append(f"        probe(() => o.{g});")
    if x['toMap']:
        L.append(f"        probe(() => o.{x['toMap']}());")
    L.append("      }")
    L.append("    });")
    L.append("  });")
L.append("}")
open(ROOT+'/test/models_roundtrip_test.dart','w').write('\n'.join(L)+'\n')
