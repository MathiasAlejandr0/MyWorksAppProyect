// Cliente HTTP de Supabase (IPv4 primero) contra un servidor local en
// 127.0.0.1: petición http correcta, https contra un servidor sin TLS (falla
// el handshake y se destruye el socket) y host solo IPv6 (fallback por nombre).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/config/supabase_http_client_io.dart';

void main() {
  late HttpServer server;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) {
      req.response
        ..statusCode = 200
        ..write('ok');
      req.response.close();
    });
  });

  tearDown(() => server.close(force: true));

  test('http por IPv4 a localhost responde', () async {
    final client = createSupabaseHttpClient()!;
    final res =
        await client.get(Uri.parse('http://localhost:${server.port}/x'));
    expect(res.statusCode, 200);
    expect(res.body, 'ok');
    client.close();
  });

  test('https contra servidor sin TLS falla el handshake', () async {
    final client = createSupabaseHttpClient()!;
    await expectLater(
      client.get(Uri.parse('https://127.0.0.1:${server.port}/x')),
      throwsA(anything),
    );
    client.close();
  });

  test('host solo IPv6 cae al connect por nombre', () async {
    final client = createSupabaseHttpClient()!;
    try {
      final v6 = await HttpServer.bind(InternetAddress.loopbackIPv6, 0);
      v6.listen((req) {
        req.response.write('v6');
        req.response.close();
      });
      try {
        final res = await client.get(Uri.parse('http://[::1]:${v6.port}/'));
        expect(res.body, 'v6');
      } finally {
        await v6.close(force: true);
      }
    } on SocketException {
      // Sin IPv6 en la máquina: el fallback falla igual que en un celular.
      await expectLater(
        client.get(Uri.parse('http://[::1]:${server.port}/')),
        throwsA(anything),
      );
    }
    client.close();
  });
}
