import 'dart:async';
import 'dart:ui' show Codec, ImmutableBuffer;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;

/// Baldosas del mapa pensadas para un teléfono: pocas, sin animación de
/// fundido y con caché en memoria para que ampliar el mapa no las baje otra vez.
///
/// CARTO Voyager responde mucho más rápido que el servidor público de
/// OpenStreetMap (medido ~0,4 s contra ~1,2 s por baldosa). Si CARTO falla,
/// se usa OpenStreetMap para esa baldosa.
class AppMapTiles extends StatelessWidget {
  const AppMapTiles({super.key});

  static final _provider = _CachedMapTileProvider();

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: _CachedMapTileProvider.urlTemplate,
      subdomains: const ['a', 'b', 'c', 'd'],
      userAgentPackageName: 'com.myworksapp.myworksapp',
      tileProvider: _provider,
      // Sin {r}: una baldosa retina pesa cuatro veces más y traba el teléfono.
      retinaMode: false,
      maxZoom: 19,
      // Solo lo visible. El margen por defecto (pan 1 + keep 2) multiplica
      // las baldosas y es lo que congela la entrada del mapa.
      panBuffer: 0,
      keepBuffer: 1,
      tileDisplay: const TileDisplay.instantaneous(),
      evictErrorTileStrategy: EvictErrorTileStrategy.notVisible,
      // Un transformador por capa: si se comparte, el temporizador de un mapa
      // se come los eventos del otro.
      tileUpdateTransformer: TileUpdateTransformers.throttle(
        const Duration(milliseconds: 220),
      ),
    );
  }
}

/// Crédito mínimo que piden OpenStreetMap y CARTO. No intercepta toques.
class MapTileCredits extends StatelessWidget {
  const MapTileCredits({super.key, this.alignment = Alignment.bottomLeft});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: const IgnorePointer(
        child: Padding(
          padding: EdgeInsets.all(4),
          child: ColoredBox(
            color: Color(0xB3FFFFFF),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              child: Text(
                '© OpenStreetMap · CARTO',
                style: TextStyle(fontSize: 9, color: Color(0xFF334155), height: 1.1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Avisa cuando la primera baldosa de la sesión ya está en memoria.
class MapTileCache {
  MapTileCache._();

  static const maxEntries = 160;
  static final _entries = <String, Uint8List>{};
  static int served = 0;
  static final List<VoidCallback> _waiters = [];

  static String keyOf(String url) {
    final segments = Uri.parse(url).pathSegments;
    if (segments.length < 3) return url;
    return segments.sublist(segments.length - 3).join('/');
  }

  /// Misma z/x/y en el servidor público de OSM.
  static String osmUrlFor(String url) {
    return 'https://tile.openstreetmap.org/${keyOf(url)}';
  }

  static Uint8List? get(String url) {
    final key = keyOf(url);
    final bytes = _entries.remove(key);
    if (bytes == null) return null;
    _entries[key] = bytes;
    return bytes;
  }

  static void put(String url, Uint8List bytes) {
    if (bytes.isEmpty) return;
    final key = keyOf(url);
    _entries.remove(key);
    _entries[key] = bytes;
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
    markServed();
  }

  static void markServed() {
    served++;
    if (_waiters.isEmpty) return;
    final pending = List<VoidCallback>.of(_waiters);
    _waiters.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final waiter in pending) {
        waiter();
      }
    });
  }

  static void whenServed(VoidCallback onServed) {
    if (served > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onServed());
      return;
    }
    _waiters.add(onServed);
  }

  static void cancel(VoidCallback onServed) {
    _waiters.remove(onServed);
  }

  @visibleForTesting
  static void debugReset() {
    _entries.clear();
    served = 0;
    _waiters.clear();
    _CachedMapTileProvider.preferOsm = false;
  }
}

class _CachedMapTileProvider extends TileProvider {
  static const urlTemplate =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

  /// Un cliente para todos los mapas. [TileLayer] llama a [dispose] al
  /// destruirse; cerrar el cliente aquí dejaría mudos a los demás mapas.
  static final http.Client _client = http.Client();
  static bool preferOsm = false;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final primary = getTileUrl(coordinates, options);
    final cached = MapTileCache.get(primary);
    if (cached != null) {
      return _CachedTileImage.memory(primary, cached);
    }
    return _CachedTileImage.network(
      url: preferOsm ? MapTileCache.osmUrlFor(primary) : primary,
      fallbackUrl: MapTileCache.osmUrlFor(primary),
      headers: headers,
      client: _client,
    );
  }
}

@immutable
class _CachedTileImage extends ImageProvider<_CachedTileImage> {
  const _CachedTileImage._({
    required this.url,
    required this.fallbackUrl,
    required this.headers,
    required this.client,
    required this.memory,
  });

  factory _CachedTileImage.memory(String url, Uint8List bytes) {
    return _CachedTileImage._(
      url: url,
      fallbackUrl: null,
      headers: const {},
      client: null,
      memory: bytes,
    );
  }

  factory _CachedTileImage.network({
    required String url,
    required String fallbackUrl,
    required Map<String, String> headers,
    required http.Client client,
  }) {
    return _CachedTileImage._(
      url: url,
      fallbackUrl: fallbackUrl,
      headers: headers,
      client: client,
      memory: null,
    );
  }

  final String url;
  final String? fallbackUrl;
  final Map<String, String> headers;
  final http.Client? client;
  final Uint8List? memory;

  @override
  Future<_CachedTileImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_CachedTileImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _CachedTileImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _decode(decode),
      scale: 1,
      debugLabel: url,
    );
  }

  Future<Codec> _decode(ImageDecoderCallback decode) async {
    final bytes = memory ?? await _download();
    MapTileCache.put(url, bytes);
    return decode(await ImmutableBuffer.fromUint8List(bytes));
  }

  Future<Uint8List> _download() async {
    final httpClient = client;
    if (httpClient == null) {
      throw StateError('Sin cliente HTTP para la baldosa');
    }
    try {
      return await _read(httpClient, url);
    } catch (error) {
      final fallback = fallbackUrl;
      if (fallback == null || fallback == url) rethrow;
      if (error is TimeoutException || error is http.ClientException) {
        _CachedMapTileProvider.preferOsm = true;
      }
      return _read(httpClient, fallback);
    }
  }

  Future<Uint8List> _read(http.Client httpClient, String target) async {
    final response = await httpClient
        .get(Uri.parse(target), headers: headers)
        .timeout(const Duration(seconds: 7));
    if (response.statusCode == 401 ||
        response.statusCode == 403 ||
        response.statusCode == 429) {
      _CachedMapTileProvider.preferOsm = true;
      throw StateError('baldosa ${response.statusCode}');
    }
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw StateError('baldosa ${response.statusCode}');
    }
    return response.bodyBytes;
  }

  @override
  bool operator ==(Object other) =>
      other is _CachedTileImage &&
      MapTileCache.keyOf(other.url) == MapTileCache.keyOf(url);

  @override
  int get hashCode => MapTileCache.keyOf(url).hashCode;
}
