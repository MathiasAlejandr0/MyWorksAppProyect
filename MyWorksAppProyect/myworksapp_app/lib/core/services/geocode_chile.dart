import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Dirección o barrio en Chile → GPS. Misma lógica que la web (`geocodeChile.ts`).
class GeocodedSite {
  const GeocodedSite({
    required this.latitude,
    required this.longitude,
    required this.label,
    this.city,
    this.region,
  });

  final double latitude;
  final double longitude;
  final String label;
  final String? city;
  final String? region;
}

const _userAgent = 'MyWorksApp/1.0 (tesis; demo.myworksapp)';
const _timeout = Duration(seconds: 5);

Future<GeocodedSite?> geocodeChileAddress(String query) async {
  final trimmed = query.trim();
  if (trimmed.length < 3) return null;
  final search =
      trimmed.toLowerCase().contains('chile') ? trimmed : '$trimmed, Chile';
  final q = Uri.encodeQueryComponent(search);

  final photon = geocodedSiteFromPhoton(
    await geocodeFetchJson(Uri.parse('https://photon.komoot.io/api/?q=$q&limit=8')),
    search,
  );
  if (photon != null) return photon;

  return geocodedSiteFromNominatim(
    await geocodeFetchJson(
      Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?format=jsonv2&q=$q&limit=5&countrycodes=cl',
      ),
    ),
    search,
  );
}

Future<GeocodedSite?> reverseGeocodeChile(
  double latitude,
  double longitude,
) async {
  return geocodedSiteFromNominatimReverse(
    await geocodeFetchJson(
      Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$latitude&lon=$longitude&format=json&accept-language=es',
      ),
    ),
  );
}

@visibleForTesting
Future<Object?> geocodeFetchJson(Uri uri) async {
  try {
    final headers = <String, String>{'Accept': 'application/json'};
    if (!kIsWeb) {
      headers['User-Agent'] = _userAgent;
    }
    final response = await http.get(uri, headers: headers).timeout(_timeout);
    if (response.statusCode != 200) return null;
    return jsonDecode(response.body);
  } catch (_) {
    return null;
  }
}

@visibleForTesting
GeocodedSite? geocodedSiteFromPhoton(Object? payload, String fallback) {
  if (payload is! Map) return null;
  final features = payload['features'];
  if (features is! List || features.isEmpty) return null;

  Map? hit;
  for (final feature in features) {
    if (feature is Map && _photonInChile(feature)) {
      hit = feature;
      break;
    }
  }
  hit ??= features.first is Map ? features.first as Map : null;
  if (hit == null) return null;

  final geometry = hit['geometry'];
  if (geometry is! Map) return null;
  final coords = geometry['coordinates'];
  if (coords is! List || coords.length < 2) return null;
  final longitude = (coords[0] as num?)?.toDouble();
  final latitude = (coords[1] as num?)?.toDouble();
  if (latitude == null || longitude == null) return null;
  if (!latitude.isFinite || !longitude.isFinite) return null;

  final properties = hit['properties'] is Map ? hit['properties'] as Map : const {};
  final city = _firstText(properties, const ['city', 'district', 'name']);
  final region = _firstText(properties, const ['state', 'county']);
  return GeocodedSite(
    latitude: latitude,
    longitude: longitude,
    label: _photonLabel(properties, fallback),
    city: city,
    region: region,
  );
}

@visibleForTesting
GeocodedSite? geocodedSiteFromNominatim(Object? payload, String fallback) {
  if (payload is! List || payload.isEmpty) return null;
  final hit = payload.first;
  if (hit is! Map) return null;
  final latitude = double.tryParse('${hit['lat']}');
  final longitude = double.tryParse('${hit['lon']}');
  if (latitude == null || longitude == null) return null;
  if (!latitude.isFinite || !longitude.isFinite) return null;
  final label = '${hit['display_name'] ?? ''}'.trim();
  final address = hit['address'] is Map ? hit['address'] as Map : const {};
  return GeocodedSite(
    latitude: latitude,
    longitude: longitude,
    label: label.isEmpty ? fallback : label,
    city: _firstText(address, const ['city', 'town', 'municipality', 'village']),
    region: _firstText(address, const ['state', 'region']),
  );
}

@visibleForTesting
GeocodedSite? geocodedSiteFromNominatimReverse(Object? payload) {
  if (payload is! Map) return null;
  final latitude = (payload['lat'] is num)
      ? (payload['lat'] as num).toDouble()
      : double.tryParse('${payload['lat']}');
  final longitude = (payload['lon'] is num)
      ? (payload['lon'] as num).toDouble()
      : double.tryParse('${payload['lon']}');
  if (latitude == null || longitude == null) return null;
  if (!latitude.isFinite || !longitude.isFinite) return null;
  final address = payload['address'] is Map ? payload['address'] as Map : const {};
  final city = _firstText(address, const [
    'city',
    'town',
    'municipality',
    'village',
    'county',
  ]);
  final region = _firstText(address, const ['state', 'region']);
  final label = '${payload['display_name'] ?? ''}'.trim();
  return GeocodedSite(
    latitude: latitude,
    longitude: longitude,
    label: label.isEmpty ? (city ?? 'Chile') : label,
    city: city,
    region: region,
  );
}

bool _photonInChile(Map feature) {
  final properties = feature['properties'];
  if (properties is! Map) return false;
  final country = '${properties['country'] ?? ''}';
  final code = '${properties['countrycode'] ?? ''}';
  return RegExp(r'chile', caseSensitive: false).hasMatch(country) ||
      RegExp(r'^cl$', caseSensitive: false).hasMatch(code);
}

String _photonLabel(Map properties, String fallback) {
  final street = [
    properties['street'],
    properties['housenumber'],
  ].where((part) => part != null && '$part'.trim().isNotEmpty).join(' ');
  final parts = <String>[];
  for (final value in [
    properties['name'],
    street,
    properties['district'],
    properties['city'],
    properties['state'],
  ]) {
    final text = '$value'.trim();
    if (text.isEmpty || text == 'null') continue;
    if (!parts.contains(text)) parts.add(text);
  }
  return parts.isEmpty ? fallback : parts.join(', ');
}

String? _firstText(Map map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}
