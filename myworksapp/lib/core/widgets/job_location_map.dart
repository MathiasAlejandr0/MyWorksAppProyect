import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/platform_support.dart';

/// Mapa de ubicación del trabajo con fallback en escritorio.
class JobLocationMap extends StatelessWidget {
  const JobLocationMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.height = 200,
  });

  final double latitude;
  final double longitude;
  final double height;

  Future<void> _openExternalMap() async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (AppPlatform.supportsEmbeddedGoogleMap) {
      return SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(latitude, longitude),
              zoom: 15,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('job_location'),
                position: LatLng(latitude, longitude),
              ),
            },
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            mapType: MapType.normal,
          ),
        ),
      );
    }

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 40, color: Colors.grey.shade600),
          const SizedBox(height: 8),
          Text(
            'Coordenadas: $latitude, $longitude',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openExternalMap,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Abrir en Google Maps'),
          ),
        ],
      ),
    );
  }
}
