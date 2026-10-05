import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../../core/theme/app_colors.dart';

class WorkerBaseLocationCard extends StatefulWidget {
  const WorkerBaseLocationCard({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.origin,
    required this.enabled,
    required this.onSave,
  });

  final double? latitude;
  final double? longitude;
  final double radiusKm;
  final String? origin;
  final bool enabled;
  final Future<void> Function(double latitude, double longitude, double radiusKm) onSave;

  @override
  State<WorkerBaseLocationCard> createState() => _WorkerBaseLocationCardState();
}

class _WorkerBaseLocationCardState extends State<WorkerBaseLocationCard> {
  final _search = TextEditingController();
  final _map = MapController();
  late double? _lat = widget.latitude;
  late double? _lng = widget.longitude;
  late double _radius = widget.radiusKm.clamp(1, 80);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _geocode() async {
    final query = _search.text.trim();
    if (query.length < 3) {
      setState(() => _error = 'Escribe una dirección de al menos 3 caracteres.');
      return;
    }
    setState(() => _error = null);
    try {
      final hits = await Geocoding(locale: const Locale('es')).locationFromAddress('$query, Chile');
      if (hits.isEmpty) {
        setState(() => _error = 'No encontramos esa dirección.');
        return;
      }
      setState(() {
        _lat = hits.first.latitude;
        _lng = hits.first.longitude;
      });
      _map.move(ll.LatLng(_lat!, _lng!), 15);
    } catch (_) {
      setState(() => _error = 'La geocodificación no respondió. Marca el punto en el mapa.');
    }
  }

  Future<void> _save() async {
    if (_lat == null || _lng == null) {
      setState(() => _error = 'Elige un punto en el mapa.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_lat!, _lng!, _radius);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se guardó. Aplica la migración de ubicación base.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = ll.LatLng(_lat ?? -33.45, _lng ?? -70.66);
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ubicación base',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              widget.origin == 'comuna' && widget.latitude != null
                  ? 'Hoy está el centro de tu comuna. Confírmalo en el mapa para que el pin deje de ser aproximado.'
                  : 'Este punto y el radio se usan en el mapa y para ofrecer trabajos cercanos.',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _search,
              enabled: widget.enabled,
              decoration: const InputDecoration(
                labelText: 'Buscar dirección',
                hintText: 'Calle, comuna',
              ),
              onSubmitted: (_) => _geocode(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: widget.enabled ? _geocode : null, child: const Text('Buscar')),
            ),
            SizedBox(
              height: 220,
              child: FlutterMap(
                mapController: _map,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: _lat == null ? 11 : 14,
                  onTap: widget.enabled
                      ? (_, point) => setState(() {
                            _lat = point.latitude;
                            _lng = point.longitude;
                          })
                      : null,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.myworksapp.myworksapp',
                  ),
                  if (_lat != null && _lng != null)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: ll.LatLng(_lat!, _lng!),
                          radius: _radius * 1000,
                          useRadiusInMeter: true,
                          color: AppColors.brandOrange.withValues(alpha: 0.15),
                          borderColor: AppColors.brandOrange,
                          borderStrokeWidth: 1,
                        ),
                      ],
                    ),
                  if (_lat != null && _lng != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: ll.LatLng(_lat!, _lng!),
                          width: 36,
                          height: 36,
                          child: const Icon(Icons.location_on, color: AppColors.brandOrange, size: 36),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Text('Radio de servicio: ${_radius.round()} km'),
            Slider(
              min: 1,
              max: 80,
              divisions: 79,
              value: _radius,
              label: '${_radius.round()} km',
              onChanged: widget.enabled ? (value) => setState(() => _radius = value) : null,
            ),
            if (_error != null) Text(_error!, style: const TextStyle(color: AppColors.error)),
            FilledButton(
              onPressed: widget.enabled && !_saving ? _save : null,
              child: Text(_saving ? 'Guardando…' : 'Guardar ubicación'),
            ),
          ],
        ),
      ),
    );
  }
}
