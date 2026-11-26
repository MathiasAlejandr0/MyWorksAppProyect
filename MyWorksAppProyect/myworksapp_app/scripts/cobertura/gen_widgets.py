"""Genera tests de humo de widgets (testWidgets) para cada widget público de
las carpetas indicadas, usando test/support/widget_harness.dart.

uso: python3 gen_widgets.py <salida.dart> <carpeta_lib> [...]
"""
import re, sys, os
sys.path.insert(0, os.path.dirname(__file__))
import gen_calls as g

WIDGET_EXT = re.compile(r'extends\s+(StatelessWidget|StatefulWidget|ConsumerWidget|'
                        r'ConsumerStatefulWidget|HookWidget|HookConsumerWidget)\b')
g.SKIP_TYPES.discard('Widget')
EXTRA = {
    'Widget': 'const SizedBox()', 'IconData': 'Icons.star', 'TextStyle': 'const TextStyle()',
    'EdgeInsets': 'EdgeInsets.zero', 'EdgeInsetsGeometry': 'EdgeInsets.zero',
    'BorderRadius': 'BorderRadius.zero', 'Alignment': 'Alignment.center',
    'TextEditingController': 'TextEditingController()', 'ScrollController': 'ScrollController()',
    'FocusNode': 'FocusNode()', 'Key': None,
}
_orig_val = g.val
# Widgets que abren el selector de mapa, cuyo FilledButton recibe ancho infinito
# con el tema de la app (bug B1 del informe): se recorren con botones acotados.
NO_INTERACT = {'ServiceRequestPage'}
STATUSES = ['pendiente', 'aceptado', 'en_camino', 'en_curso', 'completado', 'cancelado',
            'expirado', 'no_asistio', 'esperando_pago', 'esperando_cotizaciones',
            'cotizacion_seleccionada', 'pausado_orden_cambio', 'esperando_aprobacion_cliente']


def val(t, depth=0):
    base, nullable = g.strip_null(t)
    head = re.match(r'^([\w.]+)', base)
    head = head.group(1) if head else base
    if 'Function' in base and base.endswith(')'):
        return _orig_val(t, depth)
    if head in EXTRA:
        v = EXTRA[head]
        return v if v is not None else ('null' if nullable else None)
    return _orig_val(t, depth)


g.val = val


def main(out, folders, excl):
    body = []
    for rel, info in sorted(g.scan.items()):
        if not any(rel.startswith(f) for f in folders) or any(x in rel for x in excl):
            continue
        for c in info['classes']:
            if c['private'] or c['abstract'] or not WIDGET_EXT.search(c['ext']):
                continue
            a = g.alias(rel)
            ctors = sorted([x for x in c['ctors'] if not x['named'].startswith('_')],
                           key=lambda x: (x['named'] != '', len(x['params'])))
            if not c['ctors']:
                ctors = [dict(named='', params=[])]
            emitted = 0
            for ct in ctors:
                full, minimal, ok = [], [], True
                for p in ct['params']:
                    if p['name'] == 'key':
                        continue
                    v = g.pval(p) if not g.strip_null(p['type'])[0].startswith(('List', 'Map')) else val(p['type'])
                    optional = not p['required'] or p['has_default']
                    if v is None:
                        if not optional:
                            ok = False
                            break
                        continue
                    arg = v if p['kind'] in ('pos', 'opt') else '%s: %s' % (p['name'], v)
                    full.append(arg)
                    if not optional:
                        minimal.append(arg)
                if not ok:
                    continue
                name = c['name'] + (('.' + ct['named']) if ct['named'] else '')
                variants = [('completo', full, True)]
                if minimal != full:
                    variants.append(('mínimo', minimal, False))
                role = 'trabajador' if '/worker/' in rel else ('administrador' if '/admin/' in rel else 'usuario')
                joined = ', '.join(full)
                status_target = ('features/jobs/presentation/pages' in rel or 'admin_job_detail' in rel
                                 or 'sampleJobModel' in joined)
                if status_target and emitted == 0:
                    roles = ['usuario', 'trabajador'] if '/pages/' in rel else [role]
                    for st in STATUSES:
                        for rl in roles:
                            args = [x.replace('sampleJobModel', "{...sampleJobModel, 'estado': '%s'}" % st) for x in full]
                            body.append("  testWidgets('%s estado %s rol %s (%s)', (tester) async {" % (name, st, rl, rel))
                            extra = ", 'id_trabajador': '00000000-0000-4000-8000-000000000001'" if rl == 'trabajador' else ''
                            body.append("    await smokeWidget(tester, () => %s.%s(%s), role: '%s', overrides: const {'estado': '%s'%s});"
                                        % (a, name, ', '.join(args), rl, st, extra))
                            body.append('  });')
                for label, args, seeded in variants:
                    body.append("  testWidgets('%s %s (%s)', (tester) async {" % (name, label, rel))
                    body.append("    await smokeWidget(tester, () => %s.%s(%s), seeded: %s, role: '%s'%s);"
                                % (a, name, ', '.join(args), 'true' if seeded else 'false', role,
                                   ', boundedButtons: true' if c['name'] in NO_INTERACT else ''))
                    body.append('  });')
                emitted += 1
                if emitted >= 2:
                    break
            if not emitted:
                print('  sin constructor generable:', rel, c['name'], file=sys.stderr)
    head = ['// GENERADO por scripts/cobertura/gen_widgets.py. No editar a mano.',
            '// Tests de humo de widgets: montan cada widget contra el backend falso,',
            '// tocan sus botones y escriben en sus campos (test/support/widget_harness.dart).',
            '// ignore_for_file: prefer_const_constructors, deprecated_member_use, unused_import',
            '// ignore_for_file: prefer_single_quotes, avoid_dynamic_calls',
            "import 'dart:io';",
            "import 'dart:typed_data';",
            "import 'package:flutter/material.dart';",
            "import 'package:flutter_test/flutter_test.dart';",
            "import 'package:image_picker/image_picker.dart';",
            "import 'package:latlong2/latlong.dart';"]
    for rel, a in sorted(g.imports.items(), key=lambda x: int(x[1][1:])):
        head.append("import 'package:myworksapp/%s' as %s;" % (rel, a))
    head += ["import 'support/model_samples.dart';", "import 'support/widget_harness.dart';", '',
             'void main() {']
    open(out, 'w').write('\n'.join(head + body + ['}']) + '\n')
    print(out, len(body) // 3, 'tests')


if __name__ == '__main__':
    out = sys.argv[1]
    main(out, [f for f in sys.argv[2:] if not f.startswith('-')],
         [f[1:] for f in sys.argv[2:] if f.startswith('-')])
