import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/utils/search_text.dart';

void main() {
  keywordTests();
  test('«electrico» encuentra «Eléctrico» y al revés', () {
    expect(matchesSearchText('Eléctrico', 'electrico'), isTrue);
    expect(matchesSearchText('Electrico', 'ELÉCTRICO'), isTrue);
    expect(matchesSearchText('Jardín y poda', 'jardin'), isTrue);
    expect(matchesSearchText('Cerrajería', 'cerrajeria'), isTrue);
  });

  test('la ñ y las mayúsculas acentuadas se pliegan igual', () {
    expect(foldSearchText('Ñuñoa'), 'nunoa');
    expect(foldSearchText('ÁÉÍÓÚ'), 'aeiou');
  });

  test('una búsqueda vacía no filtra y un texto distinto no coincide', () {
    expect(matchesSearchText('Plomería', '  '), isTrue);
    expect(matchesSearchText('Plomería', 'pintura'), isFalse);
  });
}

void keywordTests() {
  test('«electrico» y «Eléctrico» llevan a electricidad, como en la web', () {
    expect(serviceCategoriesForQuery('electrico'), contains('electricidad'));
    expect(serviceCategoriesForQuery('Eléctrico'), contains('electricidad'));
    expect(serviceCategoriesForQuery('Jardín'), contains('jardineria'));
    expect(serviceCategoriesForQuery('quiero un gas'), contains('gasfiteria'));
    expect(serviceCategoriesForQuery('gasolina'), isNot(contains('gasfiteria')));
    expect(serviceCategoriesForQuery('xyz'), isEmpty);
  });
}
