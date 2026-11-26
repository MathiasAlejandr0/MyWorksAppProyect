import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myworksapp/core/services/photo_service.dart';
import 'package:myworksapp/core/services/profile_photo_service.dart';

import 'support/fake_plugins.dart';
import 'support/fake_supabase.dart';

File _archivo(String nombre, int kb) {
  final dir = Directory('${Directory.systemTemp.path}/mwa_test_entrada')
    ..createSync(recursive: true);
  return File('${dir.path}/$nombre')..writeAsBytesSync(Uint8List(kb * 1024));
}

void main() {
  final ps = PhotoService.instance;

  setUp(() async {
    await setUpFakeSupabase();
  });

  test('pickImage devuelve archivo o null si se cancela', () async {
    final f = await ps.pickImage(source: ImageSource.camera);
    expect(f, isNotNull);
    expect(f!.existsSync(), isTrue);
    fakePickerReturnsImage = false;
    expect(await ps.pickImage(), isNull);
  });

  test('compressImage: pequeña sin cambios, grande comprimida o fallback',
      () async {
    final chica = _archivo('chica.jpg', 10);
    expect((await ps.compressImage(chica))!.path, chica.path);

    final grande = _archivo('grande.jpg', 600);
    final comprimida = await ps.compressImage(grande);
    expect(comprimida!.path, endsWith('_compressed.jpg'));
    expect(comprimida.lengthSync(), lessThan(grande.lengthSync()));

    fakeCompressReturnsNull = true;
    expect((await ps.compressImage(grande))!.path, grande.path);

    // Archivo inexistente: la lectura falla y se devuelve el original.
    final fantasma = File(
        '${Directory.systemTemp.path}/no_existe_${DateTime.now().microsecondsSinceEpoch}.jpg');
    expect((await ps.compressImage(fantasma))!.path, fantasma.path);
  });

  test('guarda fotos de trabajo, perfil y portafolio y luego las elimina',
      () async {
    final trabajo = await ps.saveJobPhoto(_archivo('t.jpg', 600), 'job-1');
    expect(trabajo, contains('/jobs/job-1/job_job-1_'));
    expect(await ps.fileExists(trabajo!), isTrue);
    expect(await ps.getFileSizeKB(trabajo), greaterThan(0));

    final perfil = await ps.saveProfilePhoto(_archivo('p.jpg', 600), 'u-1');
    expect(perfil, contains('/profiles/u-1/avatar_'));
    final perfilChico = await ps.saveProfilePhoto(_archivo('p2.jpg', 5), 'u-1');
    expect(perfilChico, isNotNull);

    final porta = await ps.savePortfolioPhoto(_archivo('w.jpg', 600), 'w-1');
    expect(porta, contains('/portfolio/w-1/portfolio_w-1_'));
    expect(
        await ps.savePortfolioPhoto(_archivo('w2.jpg', 5), 'w-1'), isNotNull);
    expect(await ps.saveJobPhoto(_archivo('t2.jpg', 5), 'job-1'), isNotNull);

    await ps.deleteJobPhotos('job-1');
    expect(await ps.fileExists(trabajo), isFalse);
    await ps.deletePortfolioPhotos('w-1');
    expect(await ps.fileExists(porta!), isFalse);

    expect(await ps.getFileSizeKB('/no/existe.jpg'), 0);
    expect(await ps.fileExists('/no/existe.jpg'), isFalse);
  });

  test('guardar falla limpio si el origen no existe', () async {
    final fantasma = File(
        '${Directory.systemTemp.path}/fantasma_${DateTime.now().microsecondsSinceEpoch}.jpg');
    expect(await ps.saveJobPhoto(fantasma, 'j'), isNull);
    expect(await ps.saveProfilePhoto(fantasma, 'u'), isNull);
    expect(await ps.savePortfolioPhoto(fantasma, 'w'), isNull);
  });

  group('ProfilePhotoService', () {
    final pps = ProfilePhotoService.instance;

    test('pickAndSave guarda y borra la foto anterior local', () async {
      final anterior = _archivo('anterior.jpg', 1);
      final nueva = await pps.pickAndSave(
        userId: 'u-2',
        source: ImageSource.gallery,
        currentPath: anterior.path,
      );
      expect(nueva, contains('/profiles/u-2/'));
      expect(anterior.existsSync(), isFalse);

      // Rutas remotas o vacías no se tocan.
      await pps.removePhoto('https://cdn/x.jpg');
      await pps.removePhoto('');
      await pps.removePhoto(null);
      await pps.removePhoto(nueva);
      expect(File(nueva!).existsSync(), isFalse);
    });

    test('pickAndSave devuelve null si se cancela', () async {
      fakePickerReturnsImage = false;
      expect(
        await pps.pickAndSave(userId: 'u', source: ImageSource.camera),
        isNull,
      );
    });
  });
}
