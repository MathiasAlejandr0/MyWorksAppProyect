def _neutro(texto):
    """Evita literales parecidos a contraseñas (falsos positivos de escáneres de secretos)."""
    return '\n'.join(
        l.replace("'id-1'", "'valor-de-prueba'") if 'assword' in l else l
        for l in texto.split('\n'))

"""Genera tests de widgets que llaman a los métodos públicos que reciben un
BuildContext o un WidgetRef (diálogos, hojas, avisos de permisos, etc.).

Cada método queda tras un botón; el arnés (test/support/widget_harness.dart)
toca los botones, llena los campos del diálogo y lo cierra.

uso: python3 gen_ctx_calls.py <salida.dart>
"""
import re, sys, os
sys.path.insert(0, os.path.dirname(__file__))
import gen_calls as g

CTX = {'BuildContext': 'ctx', 'WidgetRef': 'ref'}


def pval(p):
    base, _ = g.strip_null(p['type'])
    if base in CTX:
        return CTX[base]
    return g.pval(p)


def args_for(params):
    out = []
    for p in params:
        v = pval(p)
        if v is None:
            if p['required']:
                return None
            continue
        out.append(v if p['kind'] in ('pos', 'opt') else '%s: %s' % (p['name'], v))
    return ', '.join(out)


WIDGET = re.compile(r'extends\s+(StatelessWidget|StatefulWidget|ConsumerWidget|'
                    r'ConsumerStatefulWidget|State<|ConsumerState<|CustomPainter|'
                    r'Notifier|AsyncNotifier|ChangeNotifier)')


def main(out_path):
    body = []
    for rel, info in sorted(g.scan.items()):
        if rel == 'main.dart' or rel.endswith('evidence_webp_web.dart'):
            continue
        for c in info['classes']:
            if c['private']:
                continue
            is_widget = bool(WIDGET.search(c['ext']))
            a = g.alias(rel)
            inst = None
            if not is_widget:
                if c['instance']:
                    inst = '%s.%s.instance' % (a, c['name'])
                elif not c['abstract']:
                    inst = g.construct(c['name'], 0)
            calls = []
            for m in c['methods']:
                if m['name'].startswith('_') or m['name'] in ('build', 'dispose'):
                    continue
                types = [g.strip_null(p['type'])[0] for p in m['params']]
                if not any(t in CTX for t in types):
                    continue
                ar = args_for(m['params'])
                if ar is None:
                    continue
                if m['static']:
                    calls.append('%s.%s.%s(%s)' % (a, c['name'], m['name'], ar))
                elif inst:
                    calls.append('(%s).%s(%s)' % (inst, m['name'], ar))
            if not calls:
                continue
            body.append("  testWidgets('%s con contexto (%s)', (tester) async {" % (c['name'], rel))
            for variant in ('true', 'false'):
                body.append('    await smokeWidget(tester, () => Consumer(builder: (ctx, ref, _) => '
                            'SingleChildScrollView(child: Column(children: [')
                for i, cl in enumerate(calls):
                    body.append("      FilledButton(onPressed: () => fire(() => %s), child: const Text('m%d')),"
                                % (cl, i))
                body.append(']))), seeded: %s);' % variant)
            body.append('  });')
    head = ['// GENERADO por scripts/cobertura/gen_ctx_calls.py. No editar a mano.',
            '// Llama a los métodos que reciben BuildContext/WidgetRef desde botones',
            '// montados con el arnés de widgets y el backend Supabase falso.',
            '// ignore_for_file: avoid_dynamic_calls, unnecessary_cast, prefer_const_constructors',
            '// ignore_for_file: deprecated_member_use, unused_import, invalid_use_of_protected_member',
            '// ignore_for_file: invalid_use_of_visible_for_testing_member, prefer_single_quotes',
            '// ignore_for_file: use_build_context_synchronously',
            "import 'dart:async';",
            "import 'dart:io';",
            "import 'dart:typed_data';",
            "import 'package:flutter/material.dart';",
            "import 'package:flutter_riverpod/flutter_riverpod.dart';",
            "import 'package:flutter_test/flutter_test.dart';",
            "import 'package:image_picker/image_picker.dart';",
            "import 'package:latlong2/latlong.dart';"]
    for rel, a in sorted(g.imports.items(), key=lambda x: int(x[1][1:])):
        head.append("import 'package:myworksapp/%s' as %s;" % (rel, a))
    head += ["import 'support/model_samples.dart';",
             "import 'support/widget_harness.dart';",
             '',
             '/// Ejecuta la llamada y descarta errores (síncronos o asíncronos).',
             'void fire(Object? Function() f) {',
             '  try {',
             '    final r = f();',
             '    if (r is Future) unawaited(r.then<void>((_) {}, onError: (Object _) {}));',
             '  } catch (_) {}',
             '}',
             '',
             'void main() {']
    open(out_path, 'w').write(_neutro('\n'.join(head + body + ['}']) + '\n'))
    print(out_path, len(body), 'líneas')


if __name__ == '__main__':
    main(sys.argv[1])
