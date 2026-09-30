import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../../core/database/supabase_db.dart';
import '../../../../core/domain/distance_match.dart';
import '../../../../core/services/gps_publish_gate.dart';
import '../../../../core/theme/app_colors.dart';

class ClientLiveTracking extends StatefulWidget {
  const ClientLiveTracking({
    super.key,
    required this.jobId,
    required this.jobStatus,
    this.destinationLat,
    this.destinationLng,
  });

  final String jobId;
  final String jobStatus;
  final double? destinationLat;
  final double? destinationLng;

  @override
  State<ClientLiveTracking> createState() => _ClientLiveTrackingState();
}

class _ClientLiveTrackingState extends State<ClientLiveTracking> {
  double? _lat;
  double? _lng;
  String? _error;
  bool _loading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _live;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  Future<void> _listen() async {
    try {
      final row = await supabase
          .from('ubicacion_en_vivo')
          .select('latitud, longitud')
          .eq('id_trabajo', widget.jobId)
          .maybeSingle();
      _apply(row);
    } catch (e) {
      _error = 'No se pudo leer la ubicación. Aplica la migración de GPS.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }

    _live = supabase
        .from('ubicacion_en_vivo')
        .stream(primaryKey: ['id_trabajo'])
        .eq('id_trabajo', widget.jobId)
        .listen((rows) {
      if (!mounted) return;
      setState(() => _apply(rows.isEmpty ? null : rows.first));
    }, onError: (_) {
      if (mounted) setState(() => _error = 'El canal en vivo no está disponible.');
    });
  }

  void _apply(Map<String, dynamic>? row) {
    _lat = (row?['latitud'] as num?)?.toDouble();
    _lng = (row?['longitud'] as num?)?.toDouble();
  }

  @override
  void dispose() {
    unawaited(_live?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = publishesLiveGps(widget.jobStatus);
    final hasWorker = _lat != null && _lng != null;
    final hasDest = widget.destinationLat != null && widget.destinationLng != null;
    int? eta;
    double? km;
    if (hasWorker && hasDest) {
      km = haversineKm(_lat!, _lng!, widget.destinationLat!, widget.destinationLng!);
      eta = estimateEtaMinutes(km);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          active ? 'Ubicación en vivo' : 'Última ubicación del pedido',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        if (_loading) const LinearProgressIndicator(minHeight: 3),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: AppColors.error))
        else if (!hasWorker)
          Text(
            active
                ? 'El profesional aún no publica una posición. El GPS corre con su app abierta.'
                : 'No hay un punto en vivo para este pedido.',
          )
        else ...[
          Text(
            eta == null
                ? 'Pin del profesional actualizado.'
                : 'A ${km!.toStringAsFixed(1)} km · llegada estimada $eta min (sin tráfico).',
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: ll.LatLng(_lat!, _lng!),
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.myworksapp.myworksapp',
                ),
                MarkerLayer(
                  markers: [
                    if (hasDest)
                      Marker(
                        point: ll.LatLng(widget.destinationLat!, widget.destinationLng!),
                        width: 32,
                        height: 32,
                        child: const Icon(Icons.home, color: AppColors.brandOrange),
                      ),
                    Marker(
                      point: ll.LatLng(_lat!, _lng!),
                      width: 32,
                      height: 32,
                      child: const Icon(Icons.navigation, color: Colors.blue),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
