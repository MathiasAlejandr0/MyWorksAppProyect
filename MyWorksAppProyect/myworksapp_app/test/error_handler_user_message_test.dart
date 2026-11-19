import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/utils/app_error.dart';
import 'package:myworksapp/core/utils/error_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const fallback = 'Algo salió mal. Intenta de nuevo en un momento.';

  group('ErrorHandler.userMessageFor', () {
    test('no muestra el detalle de una RPC que no existe', () {
      const e = PostgrestException(
        message:
            'Could not find the function public.acuerdo_pendiente(p_id_trabajo) in the schema cache',
        code: 'PGRST202',
        details: 'Searched for the function public.acuerdo_pendiente',
      );
      final text = ErrorHandler.userMessageFor(e);
      expect(text, fallback);
      expect(text, isNot(contains('acuerdo_pendiente')));
    });

    test('muestra el PIN incorrecto y los intentos que quedan', () {
      const wrong = PostgrestException(
        message: 'PIN incorrecto. Te quedan 3 intentos.',
        code: 'P0001',
      );
      const locked = PostgrestException(
        message:
            'Demasiados intentos fallidos. Espera 15 minutos para volver a ingresar el PIN.',
        code: 'P0001',
      );
      expect(ErrorHandler.userMessageFor(wrong), wrong.message);
      expect(ErrorHandler.userMessageFor(locked), locked.message);
    });

    test('un segundo cobro y la falta de evidencia se explican en español', () {
      const duplicate = PostgrestException(
        message: 'ya hay un cobro en curso para este trabajo',
        code: 'P0001',
      );
      const evidence = PostgrestException(
        message:
            'sube al menos una evidencia antes de declarar el trabajo terminado',
        code: 'P0001',
      );
      expect(
        ErrorHandler.userMessageFor(duplicate),
        contains('cobro en curso'),
      );
      expect(
        ErrorHandler.userMessageFor(evidence),
        contains('evidencia'),
      );
    });

    test('muestra los mensajes de negocio de RAISE EXCEPTION', () {
      const e = PostgrestException(
        message: 'El trabajo queda a más de 30 km del profesional',
        code: 'P0001',
      );
      expect(
        ErrorHandler.userMessageFor(e),
        'El trabajo queda a más de 30 km del profesional',
      );
    });

    test('un P0001 con pinta técnica no se muestra', () {
      const e = PostgrestException(
        message: 'function public.foo() does not exist',
        code: 'P0001',
      );
      expect(ErrorHandler.userMessageFor(e), fallback);
    });

    test('permiso denegado de Postgres no filtra nombres', () {
      const e = PostgrestException(
        message: 'permission denied for table trabajadores',
        code: '42501',
      );
      expect(ErrorHandler.userMessageFor(e, fallback: 'X'), 'X');
    });

    test('un hint que dice connection no se muestra como falla de internet',
        () {
      const e = PostgrestException(
        message: 'permission denied for table trabajadores',
        code: '42501',
        hint: 'Grant the table to the connection role',
      );
      expect(ErrorHandler.userMessageFor(e, fallback: 'X'), 'X');
    });

    test('AppError y errores comunes conservan su texto', () {
      expect(
        ErrorHandler.userMessageFor(AppError.validation('Falta la fecha')),
        'Falta la fecha',
      );
      expect(
        ErrorHandler.userMessageFor(Exception('connection reset')),
        contains('conexión'),
      );
    });

    test('una excepción cualquiera usa el fallback', () {
      expect(
        ErrorHandler.userMessageFor(StateError('Bad state: x'), fallback: 'F'),
        'F',
      );
    });
  });
}
