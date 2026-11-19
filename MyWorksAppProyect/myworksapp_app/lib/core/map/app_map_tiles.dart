import 'dart:async';
import 'dart:ui' show Codec, ImmutableBuffer;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:http/http.dart' as http;

/// Baldosas del mapa pensadas para un teléfono: OpenFreeMap Positron
/// (vectorial, sin clave), el mismo estilo claro que la web. Si el estilo no
/// carga, se usa el servidor público de OpenStreetMap para esa sesión.
class AppMapTiles extends StatefulWidget {
  const AppMapTiles({super.key});

  static const styleUrl = 'https://tiles.openfreemap.org/styles/positron';
  static const attribution =
      'OpenFreeMap © OpenMapTiles © OpenStreetMap contributors';

  @override
  State<AppMapTiles> createState() => _AppMapTilesState();
}

class _AppMapTilesState extends State<AppMapTiles> {
  vt.Style? _style;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final style = await _AppMapStyle.load();
    if (!mounted) return;
    setState(() {
      _style = style;
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    final style = _style;
    if (style == null) return const _OsmFallbackTiles();
    return vt.VectorTileLayer(
      theme: style.theme,
      tileProviders: style.providers,
      rasterSources: style.rasterSources,
      sprites: style.sprites,
      glyphs: style.glyphs,
      tileOffset: vt.TileOffset.maplibre,
      // En el teléfono las etiquetas van en la baldosa, sin costo por frame.
      labelMode: vt.LabelMode.tile,
      tileFadeDuration: Duration.zero,
    );
  }
}

/// Carga una sola vez el estilo Positron y lo reutilizan todos los mapas.
/// No se libera al cerrar un mapa: otro puede seguir usándolo.
class _AppMapStyle {
  _AppMapStyle._();

  /// En web el estilo, los glifos y el sprite bajan por XHR y el decodificado
  /// corre en el hilo principal: se da más margen antes de usar el respaldo.
  static const _timeout = Duration(seconds: kIsWeb ? 25 : 8);
  static const _userAgent = 'com.myworksapp.myworksapp';
  static const _retryAfter = Duration(seconds: 30);
  static Future<vt.Style?>? _future;
  static DateTime? _failedAt;

  /// En los tests de widgets no se pide el estilo (evita path_provider, aislados
  /// y una espera de red). El mapa cae a OpenStreetMap, como cuando falla.
  @visibleForTesting
  static bool debugForceOsmFallback = false;

  static bool get _inWidgetTest {
    return WidgetsBinding.instance.runtimeType.toString().contains('Test');
  }

  static Future<vt.Style?> load() {
    if (debugForceOsmFallback || _inWidgetTest) {
      return Future<vt.Style?>.value(null);
    }
    final failedAt = _failedAt;
    if (failedAt != null && DateTime.now().difference(failedAt) > _retryAfter) {
      // El estilo falló hace un rato (red caída): el próximo mapa lo reintenta.
      _future = null;
      _failedAt = null;
    }
    return _future ??= _read();
  }

  static Future<vt.Style?> _read() async {
    try {
      final style = await _readWith(cache: _useDiskCache);
      MapTileCache.markServed();
      return style;
    } catch (_) {
      if (_useDiskCache) {
        try {
          final style = await _readWith(cache: false);
          MapTileCache.markServed();
          return style;
        } catch (_) {
          _failedAt = DateTime.now();
          return null;
        }
      }
      _failedAt = DateTime.now();
      return null;
    }
  }

  static Future<vt.Style> _readWith({required bool cache}) {
    return vt.StyleReader(
      uri: AppMapTiles.styleUrl,
      language: 'es',
      // Un navegador no deja fijar User-Agent: lo ignora y avisa en consola.
      headers: kIsWeb ? const {} : const {'User-Agent': _userAgent},
      cache: cache,
    ).read().timeout(_timeout);
  }

  /// En web no hay caché en disco. En tests, path_provider no está disponible.
  static bool get _useDiskCache {
    if (kIsWeb) return false;
    return !_inWidgetTest;
  }

  @visibleForTesting
  static void debugReset() {
    _future = null;
    _failedAt = null;
    debugForceOsmFallback = false;
  }
}

/// Crédito que piden OpenFreeMap, OpenMapTiles y OpenStreetMap. No intercepta toques.
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
                AppMapTiles.attribution,
                style: TextStyle(
                  fontSize: 8,
                  color: Color(0xFF334155),
                  height: 1.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Avisa cuando la primera baldosa de la sesión ya está en memoria.
/// Con OpenFreeMap se marca al cargar el estilo; con el respaldo OSM, al
/// recibir la primera baldosa raster.
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
    _AppMapStyle.debugReset();
  }
}

/// PNG de 1×1 transparente. Una baldosa que falla (400, timeout, sin red)
/// se pinta vacía en vez de lanzar un error suelto.
final Uint8List blankMapTilePng = Uint8List.fromList(const <int>[
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1,
  0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 13, 73, 68, 65, 84,
  120, 218, 99, 252, 207, 192, 80, 15, 0, 4, 133, 1, 128, 132, 169, 140, 33,
  0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
]);

class _OsmFallbackTiles extends StatelessWidget {
  const _OsmFallbackTiles();

  static final _provider = _CachedMapTileProvider();

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      // En tests no se llama a OpenStreetMap: evita el aviso de política
      // y el 400 que flutter_map deja sin capturar.
      urlTemplate: _AppMapStyle._inWidgetTest
          ? 'https://tiles.myworksapp.test/{z}/{x}/{y}.png'
          : _CachedMapTileProvider.urlTemplate,
      userAgentPackageName: 'com.myworksapp.myworksapp',
      tileProvider: _provider,
      retinaMode: false,
      maxZoom: 19,
      panBuffer: 0,
      keepBuffer: 1,
      tileDisplay: const TileDisplay.instantaneous(),
      evictErrorTileStrategy: EvictErrorTileStrategy.notVisible,
      tileUpdateTransformer: TileUpdateTransformers.throttle(
        const Duration(milliseconds: 220),
      ),
    );
  }
}

class _CachedMapTileProvider extends TileProvider {
  static const urlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Un cliente para todos los mapas. [TileLayer] llama a [dispose] al
  /// destruirse; cerrar el cliente aquí dejaría mudos a los demás mapas.
  static final http.Client _client = http.Client();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    if (_AppMapStyle._inWidgetTest) {
      return _CachedTileImage.memory(url, blankMapTilePng);
    }
    final cached = MapTileCache.get(url);
    if (cached != null) {
      return _CachedTileImage.memory(url, cached);
    }
    return _CachedTileImage.network(
      url: url,
      headers: headers,
      client: _client,
    );
  }
}

@immutable
class _CachedTileImage extends ImageProvider<_CachedTileImage> {
  const _CachedTileImage._({
    required this.url,
    required this.headers,
    required this.client,
    required this.memory,
  });

  factory _CachedTileImage.memory(String url, Uint8List bytes) {
    return _CachedTileImage._(
      url: url,
      headers: const {},
      client: null,
      memory: bytes,
    );
  }

  factory _CachedTileImage.network({
    required String url,
    required Map<String, String> headers,
    required http.Client client,
  }) {
    return _CachedTileImage._(
      url: url,
      headers: headers,
      client: client,
      memory: null,
    );
  }

  final String url;
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
    final downloaded = memory == null;
    final bytes = memory ?? await _downloadOrBlank();
    if (downloaded && !identical(bytes, blankMapTilePng)) {
      MapTileCache.put(url, bytes);
    }
    return decode(await ImmutableBuffer.fromUint8List(bytes));
  }

  Future<Uint8List> _downloadOrBlank() async {
    try {
      return await _download();
    } catch (_) {
      return blankMapTilePng;
    }
  }

  Future<Uint8List> _download() async {
    final httpClient = client;
    if (httpClient == null) {
      throw StateError('Sin cliente HTTP para la baldosa');
    }
    return _read(httpClient, url);
  }

  Future<Uint8List> _read(http.Client httpClient, String target) async {
    final response = await httpClient
        .get(Uri.parse(target), headers: headers)
        .timeout(const Duration(seconds: 7));
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
