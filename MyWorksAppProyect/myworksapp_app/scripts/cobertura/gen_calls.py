"""Genera tests de humo que llaman a cada método público de las clases de
las carpetas indicadas, contra el backend Supabase falso y en varios
escenarios (vacío, con filas, RPC con datos, todo fallando, sin sesión).

uso: python3 gen_calls.py <salida.dart> <carpeta_lib> [<carpeta_lib> ...]
"""
import json, re, sys, os, pathlib
sys.path.insert(0, os.path.dirname(__file__))
import dart_scan

ROOT = dart_scan.ROOT
scan = dart_scan.scan_all()
models = {m['cls']: m for m in json.load(open(ROOT + '/build/models.json'))}

# índice nombre -> (archivo, info)
CLASSES, ENUMS, TYPEDEFS = {}, {}, {}
for rel, info in sorted(scan.items()):
    for c in info['classes']:
        CLASSES.setdefault(c['name'], (rel, c))
    for e in info['enums']:
        ENUMS.setdefault(e, rel)
    for t, rhs in info['typedefs']:
        TYPEDEFS.setdefault(t, rhs)

imports = {}


def alias(rel):
    if rel not in imports:
        imports[rel] = 'f%d' % len(imports)
    return imports[rel]


EXT = {
    'VoidCallback': 'void Function()',
    'AsyncCallback': 'Future<void> Function()',
    'ValueChanged': 'void Function(T)',
    'ValueSetter': 'void Function(T)',
    'ValueGetter': 'T Function()',
}

SKIP_TYPES = {'BuildContext', 'WidgetRef', 'Ref', 'Widget', 'State', 'TickerProvider',
              'Animation', 'AnimationController', 'GlobalKey', 'StackTrace', 'Notifier',
              'ProviderContainer', 'GoRouter', 'GoRouterState', 'NavigatorState',
              'SupabaseClient', 'RealtimeChannel', 'Stream', 'StreamController',
              'StreamSubscription', 'Completer', 'TextEditingController', 'ScrollController',
              'FocusNode', 'CameraController', 'Position'}


def strip_null(t):
    t = t.strip()
    return (t[:-1], True) if t.endswith('?') else (t, False)


def generic_args(t):
    m = re.match(r'^[\w.]+<(.*)>$', t)
    return dart_scan.split_top(m.group(1)) if m else []


def closure(fn_type, depth):
    m = re.match(r'^(.*?)\s*Function\s*\((.*)\)$', fn_type.strip(), re.S)
    if not m:
        return None
    ret, args = m.group(1).strip() or 'dynamic', m.group(2)
    params = dart_scan.parse_params(args) if args.strip() else []
    # parámetros sin nombre: "String, int"
    n_pos = len([x for x in dart_scan.split_top(args)]) if args.strip() and not args.strip().startswith('{') else 0
    names = ', '.join('_' * (i + 1) for i in range(n_pos))
    named = [p for p in params if p['kind'] == 'named']
    if named:
        names = (names + ', ' if names else '') + '{' + ', '.join(
            ('required ' if p['required'] else '') + 'dynamic ' + p['name'] if False else
            ('required ' + p['type'] + ' ' + p['name'] if p['required'] else p['type'] + ' ' + p['name'] + ('' if p['type'].endswith('?') else ''))
            for p in named) + '}'
        if any(not p['required'] and not p['type'].endswith('?') for p in named):
            return None
    base, _ = strip_null(ret)
    if ret == 'void' or ret == 'dynamic':
        return '(%s) {}' % names
    if base.startswith('Future') or base.startswith('FutureOr'):
        inner = generic_args(base)
        inner = inner[0] if inner else 'void'
        if inner in ('void', 'dynamic') or inner.endswith('?'):
            return '(%s) async {}' % names if inner == 'void' else '(%s) async => null' % names
        v = val(inner, depth + 1)
        return None if v is None else '(%s) async => %s' % (names, v)
    v = val(ret, depth + 1)
    return None if v is None else '(%s) => %s' % (names, v)


def construct(name, depth):
    rel, c = CLASSES[name]
    if c['abstract'] or c['private'] or depth > 3:
        return None
    a = alias(rel)
    if name in models:
        mm = models[name]
        return '%s.%s.%s(sample%s)' % (a, name, mm['ctor'], name)
    ctors = sorted(c['ctors'], key=lambda x: (x['named'] != '', len(x['params'])))
    for ct in ctors:
        if ct['named'].startswith('_'):
            continue
        args = []
        ok = True
        for p in ct['params']:
            if not p['required'] and (p['has_default'] or p['type'].endswith('?')):
                continue
            v = val(p['type'], depth + 1)
            if v is None:
                ok = False
                break
            args.append(v if p['kind'] in ('pos', 'opt') else '%s: %s' % (p['name'], v))
        if ok:
            return '%s.%s%s(%s)' % (a, name, ('.' + ct['named']) if ct['named'] else '', ', '.join(args))
    if not c['ctors']:
        return '%s.%s()' % (a, name)
    return None


def val(t, depth=0):
    if depth > 4:
        return None
    t = t.strip()
    base, nullable = strip_null(t)
    if 'Function' in base and base.endswith(')'):
        return closure(base, depth) or ('null' if nullable else None)
    head = re.match(r'^([\w.]+)', base)
    head = head.group(1) if head else base
    ga = generic_args(base)
    simple = {
        'String': "'id-1'", 'int': '1', 'num': '1', 'double': '1.0', 'bool': 'true',
        'DateTime': 'DateTime.utc(2026, 1, 2, 15)', 'Duration': 'const Duration(milliseconds: 1)',
        'Object': "'x'", 'dynamic': 'null', 'Uint8List': 'Uint8List.fromList([1, 2, 3, 4])',
        'File': "File('/tmp/no-existe.jpg')", 'XFile': "XFile('/tmp/no-existe.jpg')",
        'LatLng': 'const LatLng(-41.4693, -72.9424)', 'Color': 'const Color(0xFF000000)',
        'Uri': "Uri.parse('https://example.invalid/x')", 'TimeOfDay': 'const TimeOfDay(hour: 10, minute: 0)',
        'DateTimeRange': 'DateTimeRange(start: DateTime.utc(2026, 1, 2), end: DateTime.utc(2026, 1, 3))',
        'Exception': "Exception('x')", 'Error': 'StateError(\'x\')', 'Locale': "const Locale('es', 'CL')",
    }
    if head in simple:
        return simple[head]
    if head in ('List', 'Iterable'):
        if ga:
            v = val(ga[0], depth + 1)
            if v is not None and v != 'null':
                return '[%s]' % v
        return 'const []'
    if head == 'Set':
        return 'const {}'
    if head == 'Map':
        return 'const {}'
    if head in ('Future', 'FutureOr'):
        inner = ga[0] if ga else 'void'
        if inner == 'void':
            return 'Future<void>.value()'
        v = val(inner, depth + 1)
        return None if v is None else 'Future.value(%s)' % v
    if head in EXT:
        ft = EXT[head]
        if ga:
            ft = ft.replace('T', ga[0])
        elif 'T' in ft:
            ft = ft.replace('(T)', '(dynamic)').replace('T Function', 'dynamic Function')
        return closure(ft, depth)
    if head in TYPEDEFS:
        rhs = TYPEDEFS[head]
        if 'Function' in rhs:
            return closure(rhs, depth) or ('null' if nullable else None)
        return val(rhs, depth + 1)
    if head in SKIP_TYPES:
        return 'null' if nullable else None
    if head in ENUMS:
        return '%s.%s.values.first' % (alias(ENUMS[head]), head)
    if head in CLASSES:
        v = construct(head, depth)
        if v is not None:
            return v
    if t.startswith('(') and t.endswith(')'):
        return None
    return 'null' if nullable else None


def args_for(params):
    out = []
    for p in params:
        v = val(p['type'])
        if v is None:
            if p['required']:
                return None
            continue
        out.append(v if p['kind'] in ('pos', 'opt') else '%s: %s' % (p['name'], v))
    return ', '.join(out)


def emit(out_path, folders, exclude=()):
    body = []
    used_models = set()
    for rel, info in sorted(scan.items()):
        if not any(rel.startswith(f) for f in folders) or any(x in rel for x in exclude):
            continue
        for c in info['classes']:
            if c['private']:
                continue
            ext = c['ext']
            if re.search(r'extends\s+(StatelessWidget|StatefulWidget|ConsumerWidget|ConsumerStatefulWidget|State<|ConsumerState<|CustomPainter|Notifier|AsyncNotifier|ChangeNotifier)', ext):
                continue
            a = alias(rel)
            calls = []
            inst = None
            if c['instance']:
                inst = '%s.%s.instance' % (a, c['name'])
            elif not c['abstract']:
                inst = construct(c['name'], 0)
                if inst and inst.startswith(a + '.' + c['name'] + '.from'):
                    used_models.add(c['name'])
            for g in c['getters']:
                if g['name'].startswith('_'):
                    continue
                if g['static']:
                    calls.append('%s.%s.%s' % (a, c['name'], g['name']))
                elif inst:
                    calls.append('o.%s' % g['name'])
            for m in c['methods']:
                if m['name'].startswith('_') or m['name'] in ('dispose', 'build', 'toString', 'noSuchMethod', 'hashCode'):
                    continue
                ar = args_for(m['params'])
                if ar is None:
                    continue
                if m['static']:
                    calls.append('%s.%s.%s(%s)' % (a, c['name'], m['name'], ar))
                elif inst:
                    calls.append('o.%s(%s)' % (m['name'], ar))
            if not calls:
                continue
            body.append("  test('%s (%s)', () async {" % (c['name'], rel))
            body.append('    await forEachScenario(() async {')
            if inst and not any(cl.startswith('o.') for cl in calls):
                body.append('      probe(() => %s);' % inst)
            elif inst:
                body.append('      final dynamic o = probe(() => %s);' % inst)
            for cl in calls:
                if not cl.startswith('o.'):
                    body.append('      await call(() => %s);' % cl)
            inst_calls = [cl for cl in calls if cl.startswith('o.')]
            if inst_calls:
                body.append('      if (o != null) {')
                for cl in inst_calls:
                    body.append('        await call(() => %s);' % cl)
                body.append('      }')
            body.append('    });')
            body.append('  });')
    for name in list(models):
        pass
    head = ['// GENERADO por scripts/cobertura/gen_calls.py. No editar a mano.',
            '// Tests de humo: cada método público se llama contra el backend Supabase',
            '// falso (test/support/fake_supabase.dart) en varios escenarios. Nada sale a',
            '// la red: no toca producción ni Transbank.',
            '// ignore_for_file: avoid_dynamic_calls, unnecessary_cast, prefer_const_constructors',
            '// ignore_for_file: deprecated_member_use, unused_import, invalid_use_of_protected_member',
            '// ignore_for_file: invalid_use_of_visible_for_testing_member, prefer_single_quotes',
            "import 'dart:io';",
            "import 'dart:typed_data';",
            "import 'package:flutter/material.dart';",
            "import 'package:flutter_test/flutter_test.dart';",
            "import 'package:image_picker/image_picker.dart';",
            "import 'package:latlong2/latlong.dart';"]
    for rel, a in sorted(imports.items(), key=lambda x: int(x[1][1:])):
        head.append("import 'package:myworksapp/%s' as %s;" % (rel, a))
    head.append("import 'support/model_samples.dart';")
    head.append("import 'support/scenarios.dart';")
    head.append('')
    head.append('void main() {')
    head.append('  setUpAll(setUpScenarios);')
    src = '\n'.join(head + body + ['}']) + '\n'
    open(out_path, 'w').write(src)
    print(out_path, len(body), 'líneas')


if __name__ == '__main__':
    out = sys.argv[1]
    folders = [f for f in sys.argv[2:] if not f.startswith('-')]
    excl = [f[1:] for f in sys.argv[2:] if f.startswith('-')]
    emit(out, folders, excl)
