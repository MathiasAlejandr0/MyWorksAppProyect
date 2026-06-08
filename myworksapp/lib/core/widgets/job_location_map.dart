import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as ll;
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../utils/platform_support.dart';

/// Mapa de ubicación: Google Maps en móvil/web, OpenStreetMap en escritorio.
class JobLocationMap extends StatelessWidget {
  const JobLocationMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.height = 200,
    this.square = false,
  });

  final double latitude;
  final double longitude;
  final double height;
  final bool square;

  Future<void> _openExternalMap() async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Widget _wrapMap(Widget map) {
    if (square) {
      return AspectRatio(aspectRatio: 1, child: map);
    }
    return SizedBox(height: height, child: map);
  }

  Widget _openMapsButton(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: _openExternalMap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.open_in_new, size: 16, color: AppColors.brandOrange),
              const SizedBox(width: 6),
              Text(
                'Abrir en Maps',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandNavy,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _desktopMap(BuildContext context) {
    final point = ll.LatLng(latitude, longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: point,
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.myworksapp.myworksapp',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 36,
                    height: 36,
                    child: const Icon(
                      Icons.location_on,
                      color: Color(0xFFE53935),
                      size: 36,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  '© OpenStreetMap',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: _openMapsButton(context),
          ),
        ],
      ),
    );
  }

  Widget _googleMap() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: gmaps.GoogleMap(
        initialCameraPosition: gmaps.CameraPosition(
          target: gmaps.LatLng(latitude, longitude),
          zoom: 15,
        ),
        markers: {
          gmaps.Marker(
            markerId: const gmaps.MarkerId('job_location'),
            position: gmaps.LatLng(latitude, longitude),
          ),
        },
        zoomControlsEnabled: !square,
        myLocationButtonEnabled: !square,
        myLocationEnabled: !square,
        mapType: gmaps.MapType.normal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (AppPlatform.supportsEmbeddedGoogleMap) {
      return _wrapMap(_googleMap());
    }

    if (AppPlatform.isDesktopNative) {
      return _wrapMap(_desktopMap(context));
    }

    return _wrapMap(_desktopMap(context));
  }
}
