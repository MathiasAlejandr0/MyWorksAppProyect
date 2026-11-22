import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/services/error_report_filter.dart';
import 'package:myworksapp/core/utils/app_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('isExpectedUserError: no se reporta', () {
    test('mensajes de negocio de Postgres (P0001)', () {
      for (final msg in [
        'ya hay un acuerdo pendiente',
        'la otra parte debe responder',
        'esa hora ya no esta disponible',
        'elige un horario publicado por el profesional',
        'el acuerdo ya fue respondido',
        'el trabajo ya esta cerrado',
      ]) {
        expect(
          isExpectedUserError(
            PostgrestException(
              message: msg,
              code: 'P0001',
              details: 'Bad Request',
            ),
          ),
          isTrue,
          reason: msg,
        );
      }
    });

    test('sin conexión (web y móvil)', () {
      expect(
        isExpectedUserError(
          'FunctionsFetchException(status: 0, details: ClientException: Failed to fetch, uri=https://x.supabase.co/functions/v1/webpay-create)',
        ),
        isTrue,
      );
      expect(isExpectedUserError(Exception('Failed host lookup: x')), isTrue);
      expect(isExpectedUserError(Exception('SocketException: reset')), isTrue);
    });

    test('AppError de validación, red, sesión y permisos', () {
      expect(isExpectedUserError(AppError.validation('x')), isTrue);
      expect(isExpectedUserError(AppError.network('x')), isTrue);
      expect(isExpectedUserError(AppError.authentication('x')), isTrue);
      expect(isExpectedUserError(AppError.permission('x')), isTrue);
    });
  });

  group('isExpectedUserError: sí se reporta', () {
    test('función de Postgres inexistente (42883) y RPC fuera de caché', () {
      expect(
        isExpectedUserError(
          const PostgrestException(
            message:
                'function public.transicion_trabajo_permitida(text, text, text) does not exist',
            code: '42883',
          ),
        ),
        isFalse,
      );
      expect(
        isExpectedUserError(
          const PostgrestException(
            message: 'Could not find the function',
            code: 'PGRST202',
          ),
        ),
        isFalse,
      );
    });

    test('monto que no coincide entre la app y el servidor', () {
      expect(
        isExpectedUserError(
          'FunctionsException(status: 400, details: {error: Monto 40220 no coincide con tarifa/cotización 39830})',
        ),
        isFalse,
      );
    });

    test('nulos, plataforma y AppError crítico o de base de datos', () {
      expect(
        isExpectedUserError(
          StateError('Null check operator used on a null value'),
        ),
        isFalse,
      );
      expect(
        isExpectedUserError(UnsupportedError('Platform._version')),
        isFalse,
      );
      expect(isExpectedUserError(AppError.critical('x')), isFalse);
      expect(isExpectedUserError(AppError.database('x')), isFalse);
      expect(isExpectedUserError(null), isFalse);
    });
  });
}
