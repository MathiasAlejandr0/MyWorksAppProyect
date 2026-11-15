import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/utils/memo_cache.dart';

void main() {
  group('MemoCache', () {
    test('pedidas simultáneas comparten una sola carga', () async {
      final cache = MemoCache<int>(ttl: const Duration(minutes: 1));
      var calls = 0;
      Future<int> load() async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return 42;
      }

      final results = await Future.wait([
        cache.get('k', load),
        cache.get('k', load),
        cache.get('k', load),
      ]);
      expect(results, [42, 42, 42]);
      expect(calls, 1);
    });

    test('vence después del ttl', () async {
      var now = DateTime(2026, 11, 13, 10);
      final cache =
          MemoCache<int>(ttl: const Duration(seconds: 20), now: () => now);
      var calls = 0;
      Future<int> load() async => ++calls;

      expect(await cache.get('k', load), 1);
      now = now.add(const Duration(seconds: 10));
      expect(await cache.get('k', load), 1);
      now = now.add(const Duration(seconds: 11));
      expect(await cache.get('k', load), 2);
    });

    test('un error no queda guardado', () async {
      final cache = MemoCache<int>(ttl: const Duration(minutes: 1));
      var calls = 0;
      Future<int> load() async {
        calls++;
        if (calls == 1) throw StateError('falla');
        return 7;
      }

      await expectLater(cache.get('k', load), throwsStateError);
      await Future<void>.delayed(Duration.zero);
      expect(await cache.get('k', load), 7);
      expect(calls, 2);
    });

    test('invalidate fuerza una carga nueva', () async {
      final cache = MemoCache<int>(ttl: const Duration(minutes: 1));
      var calls = 0;
      Future<int> load() async => ++calls;
      await cache.get('k', load);
      cache.invalidate('k');
      expect(await cache.get('k', load), 2);
    });
  });
}
