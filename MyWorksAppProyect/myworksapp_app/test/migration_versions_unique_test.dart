import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('cada archivo SQL de migraciones tiene un prefijo de versión único', () {
    final dir = Directory('supabase/migrations');
    expect(dir.existsSync(), isTrue);

    final sqlFiles = dir
        .listSync()
        .whereType<File>()
        .where((file) => p.extension(file.path) == '.sql')
        .toList();

    final prefixes = <String, String>{};
    for (final file in sqlFiles) {
      final name = p.basename(file.path);
      final underscore = name.indexOf('_');
      expect(
        underscore > 0,
        isTrue,
        reason: 'el nombre debe empezar con dígitos y un _: $name',
      );
      final prefix = name.substring(0, underscore);
      expect(
        prefixes.containsKey(prefix),
        isFalse,
        reason:
            'versión duplicada $prefix: ${prefixes[prefix]} y $name. '
            'Supabase registra una sola fila por versión en '
            'schema_migrations, así que la segunda nunca se aplica.',
      );
      prefixes[prefix] = name;
    }

    expect(
      File(
        'supabase/migrations/20261122230000_cancelar_solicitud_con_disputa.sql',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        'supabase/migrations/20261120193000_cancelar_solicitud_con_disputa.sql',
      ).existsSync(),
      isFalse,
    );
  });
}
