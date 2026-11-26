// Plataformas falsas de plugins federados (path_provider, image_picker y
// flutter_image_compress): en los tests no hay implementación nativa y los
// flujos de fotos se cortarían en el primer paso.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress_platform_interface/flutter_image_compress_platform_interface.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// Si es false, el selector de imágenes simula que el usuario canceló.
bool fakePickerReturnsImage = true;

/// Si es true, la compresión simula fallar devolviendo null.
bool fakeCompressReturnsNull = false;

final Uint8List fakeJpegBytes = Uint8List.fromList([
  0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, //
  ...List<int>.filled(2048, 0x11),
  0xFF, 0xD9,
]);

String fakeImagePath() {
  final dir = Directory('${Directory.systemTemp.path}/mwa_test_fotos')
    ..createSync(recursive: true);
  final f = File('${dir.path}/foto.jpg');
  if (!f.existsSync()) f.writeAsBytesSync(fakeJpegBytes);
  return f.path;
}

class _FakePaths extends PathProviderPlatform {
  String get _base {
    final d = Directory('${Directory.systemTemp.path}/mwa_test_docs')
      ..createSync(recursive: true);
    return d.path;
  }

  @override
  Future<String?> getTemporaryPath() async => _base;
  @override
  Future<String?> getApplicationSupportPath() async => _base;
  @override
  Future<String?> getApplicationDocumentsPath() async => _base;
  @override
  Future<String?> getApplicationCachePath() async => _base;
  @override
  Future<String?> getLibraryPath() async => _base;
  @override
  Future<String?> getDownloadsPath() async => _base;
}

class _FakePicker extends ImagePickerPlatform {
  XFile? get _f => fakePickerReturnsImage ? XFile(fakeImagePath()) : null;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async =>
      _f;

  @override
  Future<XFile?> getImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async =>
      _f;

  @override
  Future<XFile?> getVideo({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) async =>
      _f;

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async =>
      [if (_f != null) _f!];

  @override
  Future<List<XFile>> getMedia({required MediaOptions options}) async =>
      [if (_f != null) _f!];
}

class _FakeCompress extends FlutterImageCompressPlatform {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString();
    if (name.contains('compressWithFile') ||
        name.contains('compressAssetImage')) {
      return Future<Uint8List?>.value(
        fakeCompressReturnsNull
            ? null
            : Uint8List.fromList(fakeJpegBytes.take(512).toList()),
      );
    }
    if (name.contains('compressWithList')) {
      // Cabecera RIFF/WEBP mínima: basta para isWebpBytes.
      return Future<Uint8List>.value(Uint8List.fromList([
        0x52, 0x49, 0x46, 0x46, 0x00, 0x02, 0x00, 0x00, //
        0x57, 0x45, 0x42, 0x50, ...List<int>.filled(500, 0x22),
      ]));
    }
    if (name.contains('compressAndGetFile')) {
      return Future<XFile?>.value(XFile(fakeImagePath()));
    }
    if (name.contains('showNativeLog')) return Future<void>.value();
    return null;
  }
}

/// Reproductor de video falso: inicializa con 12 s y 640×360, o falla.
class FakeVideoPlatform extends VideoPlayerPlatform {
  FakeVideoPlatform({this.fails = false});
  final bool fails;
  int _next = 1;
  final Map<int, StreamController<VideoEvent>> _streams = {};

  @override
  Future<void> init() async {}
  @override
  Future<int?> create(DataSource dataSource) async => _next++;
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async => _next++;
  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    final c = _streams[playerId] = StreamController<VideoEvent>();
    scheduleMicrotask(() {
      if (fails) {
        c.addError(PlatformException(code: 'VideoError', message: 'falla'));
      } else {
        c.add(VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(seconds: 12),
          size: const Size(640, 360),
        ));
      }
    });
    return c.stream;
  }

  @override
  Future<void> dispose(int playerId) async =>
      _streams.remove(playerId)?.close();
  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> play(int playerId) async {}
  @override
  Future<void> pause(int playerId) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> seekTo(int playerId, Duration position) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<Duration> getPosition(int playerId) async =>
      const Duration(seconds: 1);
  @override
  Widget buildView(int playerId) => const SizedBox.expand();
  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const SizedBox.expand();
  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
}

VideoPlayerPlatform? _videoOriginal;

/// Activa el reproductor falso solo para la prueba que lo pide.
void installFakeVideo({bool fails = false}) {
  _videoOriginal ??= VideoPlayerPlatform.instance;
  VideoPlayerPlatform.instance = FakeVideoPlatform(fails: fails);
}

/// Instala las plataformas falsas (idempotente).
void installFakePlugins() {
  fakePickerReturnsImage = true;
  fakeCompressReturnsNull = false;
  if (_videoOriginal != null) VideoPlayerPlatform.instance = _videoOriginal!;
  if (PathProviderPlatform.instance is! _FakePaths) {
    PathProviderPlatform.instance = _FakePaths();
  }
  if (ImagePickerPlatform.instance is! _FakePicker) {
    ImagePickerPlatform.instance = _FakePicker();
  }
  if (FlutterImageCompressPlatform.instance is! _FakeCompress) {
    FlutterImageCompressPlatform.instance = _FakeCompress();
  }
}
