import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/services/error_stack_sanitizer.dart';

void main() {
  group('sanitizeErrorStack', () {
    test('devuelve null si la traza está vacía', () {
      expect(sanitizeErrorStack(null), isNull);
      expect(sanitizeErrorStack(''), isNull);
      expect(sanitizeErrorStack('   \n  '), isNull);
    });

    test('oculta correo, token, secreto de URL y teléfono', () {
      const raw = '''
#0      pagar (package:myworksapp/features/payments/pay.dart:12:3)
#1      cliente@example.com llamó oneclick
Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.e2e
https://x.supabase.co/functions/v1/webpay-create?access_token=supersecreto&job=1
contacto +56 9 6471 0361
''';
      final out = sanitizeErrorStack(raw)!;
      expect(out, contains('pagar'));
      expect(out, isNot(contains('cliente@example.com')));
      expect(out, contains('[correo]'));
      expect(out, isNot(contains('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9')));
      expect(out, contains('[token]'));
      expect(out, isNot(contains('supersecreto')));
      expect(out, contains('access_token=[redactado]'));
      expect(out, isNot(contains('6471')));
      expect(out, contains('[telefono]'));
    });

    test('quita los frames del propio reporte y deja al llamador', () {
      const raw = '''
#0      stackForErrorLog (package:myworksapp/core/services/error_stack_sanitizer.dart:24:10)
#1      CrashReportingService.recordError (package:myworksapp/core/services/crash_reporting_service.dart:80:20)
#2      AppLogger.e (package:myworksapp/core/utils/app_logger.dart:46:37)
#3      ErrorHandler.userMessage (package:myworksapp/core/utils/error_handler.dart:141:17)
#4      CheckoutPage._pagar (package:myworksapp/features/payments/checkout_page.dart:90:12)
''';
      final out = sanitizeErrorStack(raw)!;
      expect(out, isNot(contains('error_stack_sanitizer')));
      expect(out, isNot(contains('crash_reporting_service')));
      expect(out, isNot(contains('app_logger.dart')));
      expect(out, isNot(contains('error_handler.dart')));
      expect(out, startsWith('#4      CheckoutPage._pagar'));
    });

    test('recorta una traza larga y avisa', () {
      final raw =
          List.generate(400, (i) => '#$i frame_$i ${'x' * 40}').join('\n');
      final out = sanitizeErrorStack(raw, maxChars: 200)!;
      expect(out.length, lessThan(raw.length));
      expect(out, endsWith('… (traza recortada)'));
      expect(out.startsWith('#0 frame_0'), isTrue);
    });
  });

  group('stackForErrorLog', () {
    test('si no hay stack, usa el actual y no queda vacío', () {
      final out = stackForErrorLog(null);
      expect(out, isNotNull);
      expect(out, isNotEmpty);
      expect(out, contains('error_stack_sanitizer_test.dart'));
    });

    test('guarda el stack que le pasan, ya recortado', () {
      final out = stackForErrorLog(
        StackTrace.fromString('#0 real (package:app/foo.dart:1:1)\n'),
      );
      expect(out, contains('package:app/foo.dart'));
    });
  });
}
