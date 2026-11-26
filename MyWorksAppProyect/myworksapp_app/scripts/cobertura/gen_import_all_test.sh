#!/usr/bin/env bash
# Genera test/coverage_all_files_test.dart: importa todos los archivos de lib/
# para que la cobertura cuente también los que ningún test carga (0 %).
# Excluye: main.dart (entrypoint), archivos `part of` (entran por su padre),
# código generado (*.g.dart, *.freezed.dart) y evidence_webp_web.dart
# (solo compila en web: usa dart:js_interop, no carga en la VM de tests).
set -euo pipefail
cd "$(dirname "$0")/../.."
out=test/coverage_all_files_test.dart
{
  echo '// GENERADO por scripts/cobertura/gen_import_all_test.sh. No editar a mano.'
  echo '// ignore_for_file: unused_import, directives_ordering'
  i=0
  find lib -name '*.dart' | LC_ALL=C sort | while read -r f; do
    case "$f" in
      lib/main.dart|*.g.dart|*.freezed.dart|lib/core/services/evidence_webp_web.dart) continue;;
    esac
    if grep -q '^part of' "$f"; then continue; fi
    i=$((i+1))
    echo "import 'package:myworksapp/${f#lib/}' as i$i;"
  done
  echo
  echo "import 'package:flutter_test/flutter_test.dart';"
  echo
  echo 'void main() {'
  echo "  test('carga todos los archivos de lib/ para medir cobertura', () {"
  echo '    expect(true, isTrue);'
  echo '  });'
  echo '}'
} > "$out"
echo "escrito $out"
