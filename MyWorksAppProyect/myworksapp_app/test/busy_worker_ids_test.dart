import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/repositories/job_repository.dart';

void main() {
  group('JobRepository.parseBusyWorkerIds', () {
    test('lista de strings (SETOF uuid)', () {
      expect(JobRepository.parseBusyWorkerIds(['a', 'b', 'a']), {'a', 'b'});
    });

    test('lista de mapas con el nombre de la función', () {
      expect(
        JobRepository.parseBusyWorkerIds([
          {'profesionales_ocupados': 'x'},
          {'otra': 'y'},
        ]),
        {'x', 'y'},
      );
    });

    test('respuestas vacías o raras', () {
      expect(JobRepository.parseBusyWorkerIds(null), isEmpty);
      expect(JobRepository.parseBusyWorkerIds(const []), isEmpty);
      expect(JobRepository.parseBusyWorkerIds(['', 3, null]), isEmpty);
    });
  });
}
