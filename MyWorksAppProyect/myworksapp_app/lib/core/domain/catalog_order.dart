import 'distance_match.dart';

/// Orden único del catálogo de profesionales (app, web y RPC).
///
/// Es la misma regla que `listar_profesionales_catalogo` en Postgres
/// (migraciones 20261117215046_catalogo_orden_cercania_nota_precio y
/// 20261117215659_catalogo_orden_tarifa_cero_al_final) y que
/// `shared/src/catalogOrder.ts` en la web:
///   1. Cercanía: banda de 1 km (floor de la distancia haversine) ASC.
///      Sin ubicación del cliente o sin base del profesional va al final.
///   2. Calificación pública DESC (0 si no tiene reseñas).
///   3. Tarifa de visita ASC (sin tarifa o tarifa 0 al final).
///   4. id del profesional ASC (desempate estable).
/// La base del profesional se compara redondeada a 2 decimales, como la
/// entrega la RPC pública.
class CatalogOrderItem {
  const CatalogOrderItem({
    required this.id,
    this.rating,
    this.price,
    this.latitude,
    this.longitude,
  });

  final String id;
  final double? rating;
  final double? price;
  final double? latitude;
  final double? longitude;
}

/// Redondeo a 2 decimales igual a `round(numeric, 2)` de Postgres.
double roundCoord2(double value) {
  final sign = value < 0 ? -1 : 1;
  return sign * (value.abs() * 100 + 1e-9).round() / 100;
}

bool _finite(double? value) => value != null && value.isFinite;

/// Banda de cercanía en km completos, o null si no se puede calcular.
int? catalogDistanceBand(
  double? latitude,
  double? longitude, {
  double? originLatitude,
  double? originLongitude,
}) {
  if (!_finite(originLatitude) || !_finite(originLongitude)) return null;
  if (!_finite(latitude) || !_finite(longitude)) return null;
  final km = haversineKm(
    roundCoord2(latitude!),
    roundCoord2(longitude!),
    originLatitude!,
    originLongitude!,
  );
  return km.floor();
}

int compareCatalogOrder(
  CatalogOrderItem a,
  CatalogOrderItem b, {
  double? originLatitude,
  double? originLongitude,
}) {
  final bandA = catalogDistanceBand(
    a.latitude,
    a.longitude,
    originLatitude: originLatitude,
    originLongitude: originLongitude,
  );
  final bandB = catalogDistanceBand(
    b.latitude,
    b.longitude,
    originLatitude: originLatitude,
    originLongitude: originLongitude,
  );
  if (bandA != bandB) {
    if (bandA == null) return 1;
    if (bandB == null) return -1;
    return bandA.compareTo(bandB);
  }
  final ratingA = _finite(a.rating) ? a.rating! : 0.0;
  final ratingB = _finite(b.rating) ? b.rating! : 0.0;
  if (ratingA != ratingB) return ratingB.compareTo(ratingA);
  final priceA = _finite(a.price) && a.price! > 0 ? a.price : null;
  final priceB = _finite(b.price) && b.price! > 0 ? b.price : null;
  if (priceA != priceB) {
    if (priceA == null) return 1;
    if (priceB == null) return -1;
    return priceA.compareTo(priceB);
  }
  return a.id.compareTo(b.id);
}

/// Ordena [list] en su lugar; [toItem] adapta el modelo de cada pantalla.
void sortCatalog<T>(
  List<T> list,
  CatalogOrderItem Function(T value) toItem, {
  double? originLatitude,
  double? originLongitude,
}) {
  final entries = [for (final value in list) (value: value, item: toItem(value))];
  entries.sort(
    (x, y) => compareCatalogOrder(
      x.item,
      y.item,
      originLatitude: originLatitude,
      originLongitude: originLongitude,
    ),
  );
  for (var i = 0; i < entries.length; i++) {
    list[i] = entries[i].value;
  }
}

/// Orden estable: ante empate conserva el orden previo (el orden único).
void stableSortBy<T>(List<T> list, int Function(T a, T b) compare) {
  final indexed = [for (var i = 0; i < list.length; i++) (index: i, value: list[i])];
  indexed.sort((x, y) {
    final byKey = compare(x.value, y.value);
    return byKey != 0 ? byKey : x.index.compareTo(y.index);
  });
  for (var i = 0; i < indexed.length; i++) {
    list[i] = indexed[i].value;
  }
}
