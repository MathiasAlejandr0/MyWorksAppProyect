import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Cliente de Auth y de la base.
///
/// En varios celulares la red anuncia IPv6 pero no lo enruta. Dart intenta
/// esa dirección primero y el login termina en «no hay conexión» aunque el
/// correo y la contraseña estén bien. Se conecta por IPv4 y, si no hay,
/// por el nombre. El certificado se valida contra el nombre de Supabase,
/// no contra la IP.
http.Client? createSupabaseHttpClient() {
  final inner = HttpClient()
    ..connectionTimeout = const Duration(seconds: 20)
    ..idleTimeout = const Duration(seconds: 15)
    ..findProxy = (_) => 'DIRECT';
  inner.connectionFactory = (uri, proxyHost, proxyPort) {
    if (proxyHost != null && proxyPort != null) {
      return Socket.startConnect(proxyHost, proxyPort);
    }
    var cancelled = false;
    Socket? live;
    final opened = () async {
      final socket = await _open(uri);
      if (cancelled) {
        socket.destroy();
        throw const SocketException('Conexión cancelada');
      }
      live = socket;
      return socket;
    }();
    return Future.value(
      ConnectionTask.fromSocket(opened, () {
        cancelled = true;
        live?.destroy();
      }),
    );
  };
  return IOClient(inner);
}

Future<Socket> _open(Uri uri) async {
  final port = uri.port;
  Socket socket;
  try {
    socket = await _connectIpv4(uri.host, port);
  } catch (_) {
    socket = await Socket.connect(
      uri.host,
      port,
      timeout: const Duration(seconds: 15),
    );
  }
  if (uri.scheme != 'https') return socket;
  try {
    return await SecureSocket.secure(socket, host: uri.host);
  } catch (e) {
    socket.destroy();
    rethrow;
  }
}

Future<Socket> _connectIpv4(String host, int port) async {
  final addresses = await InternetAddress.lookup(
    host,
    type: InternetAddressType.IPv4,
  ).timeout(const Duration(seconds: 4));
  if (addresses.isEmpty) {
    throw const SocketException('Sin dirección IPv4');
  }
  return Socket.connect(
    addresses.first,
    port,
    timeout: const Duration(seconds: 15),
  );
}
