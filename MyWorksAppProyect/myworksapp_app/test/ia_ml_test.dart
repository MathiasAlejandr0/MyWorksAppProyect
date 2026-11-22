import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/ia/clasificar_mensaje.dart';
import 'package:myworksapp/core/ia/documento_foto.dart';
import 'package:myworksapp/core/ia/sugerencia_solicitud.dart';

void main() {
  test('marca pago por fuera y deja pasar un pedido normal', () {
    expect(clasificarMensaje('págame por fuera de la app'), 'fuera');
    expect(clasificarMensaje('el calefont gotea'), 'limpio');
    expect(avisoModeracion('insulto'), contains('No se borra'));
  });

  test('la sugerencia exige el esquema y oculta el RUT', () {
    final ok = parsearSugerencia({
      'categoria': 'gasfiteria',
      'urgencia': 'alta',
      'precio_min_clp': 30000,
      'precio_max_clp': 80000,
      'preguntas': ['¿En qué comuna está el trabajo?'],
    });
    expect(ok?.categoria, 'gasfiteria');
    expect(parsearSugerencia({'categoria': 'magia'}), isNull);
    expect(enmascararParaExterno('RUT 12.345.678-5'), isNot(contains('12.345.678-5')));
  });

  test('prepara el documento en WebP después de recortar', () async {
    final webp = await prepararDocumentoWebp(
      Uint8List.fromList([1, 2, 3, 4]),
      recortar: (origen, fraccion) {
        expect(fraccion, 0.28);
        return origen.sublist(0, 2);
      },
      aWebp: (origen) async {
        expect(origen.length, 2);
        return Uint8List.fromList([
          0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50,
        ]);
      },
    );
    expect(webp[0], 0x52);
  });
}
