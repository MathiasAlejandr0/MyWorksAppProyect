/// Texto comparable para buscar: minúsculas y sin tildes ni diéresis.
///
/// «electrico» encuentra «Eléctrico», y «Jardín» encuentra «jardin». Es la misma
/// regla que `foldSearchText` de la web (`myworksapp_web/src/data/searchText.ts`).
String foldSearchText(String value) {
  const from = 'áàâãäåéèêëíìîïóòôõöúùûüñçÿ';
  const to = 'aaaaaaeeeeiiiiooooouuuuncy';
  final buffer = StringBuffer();
  for (final rune in value.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    final index = from.indexOf(char);
    buffer.write(index < 0 ? char : to[index]);
  }
  return buffer.toString();
}

/// True si [haystack] contiene [query], sin distinguir tildes ni mayúsculas.
bool matchesSearchText(String haystack, String query) {
  final needle = foldSearchText(query).trim();
  if (needle.isEmpty) return true;
  return foldSearchText(haystack).contains(needle);
}

/// Palabras que llevan a cada categoría de servicio. Son las mismas que usa la
/// web (`resolveCategory` en `myworksapp_web/src/data/resolveServiceQuery.ts`),
/// ya sin tildes: «electrico» y «Eléctrico» llevan a «electricidad».
const Map<String, List<String>> serviceQueryKeywords = {
  'plomeria': ['fuga', 'agua', 'lavaplatos', 'llave', 'plomer'],
  'gasfiteria': ['gasfiter'],
  'ensamblaje': ['mueble', 'armar', 'closet', 'rack', 'armado', 'ensamblaje'],
  'limpieza': ['limpieza', 'aseo'],
  'pintura': ['pintura', 'pintor'],
  'jardineria': ['jardin', 'poda'],
  'cerrajeria': ['cerraj', 'chapa'],
  'construccion': ['construc', 'remodel', 'maestro'],
  'soporte_tecnico': ['soporte', 'comput'],
  'mudanza': ['mudanza', 'traslado'],
  'climatizacion': ['climat', 'aire acondicionado', 'calefacc'],
  'electricidad': ['electric', 'electricista'],
};

/// Categorías a las que apunta lo que escribió la persona, igual que la web.
/// «gas» y «pc» valen solo como palabra completa.
Set<String> serviceCategoriesForQuery(String query) {
  final text = foldSearchText(query);
  if (text.trim().isEmpty) return const {};
  final words = text.split(RegExp(r'\s+'));
  final found = <String>{};
  serviceQueryKeywords.forEach((category, stems) {
    if (stems.any(text.contains)) found.add(category);
  });
  if (words.contains('gas')) found.add('gasfiteria');
  if (words.contains('pc')) found.add('soporte_tecnico');
  return found;
}
