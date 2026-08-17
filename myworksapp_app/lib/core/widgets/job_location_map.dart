import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as ll;

import '../config/google_maps_config.dart';
import '../theme/app_colors.dart';
import '../utils/external_map_launcher.dart';
import '../utils/platform_support.dart';

/// Modo del mapa embebido.
enum JobMapDisplayMode {
  /// Vista compacta: punto destacado, sin gestos, abre navegación al tocar.
  preview,

  /// Vista interactiva para seleccionar/confirmar ubicación en formularios.
  interactive,
}

/// Mapa de ubicación: Google Maps en móvil/web, OpenStreetMap en escritorio.
class JobLocationMap extends StatelessWidget {
  const JobLocationMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.mode = JobMapDisplayMode.preview,
    this.height = 96,
    this.onTap,
  });

  final double latitude;
  final double longitude;
  final JobMapDisplayMode mode;
  final double height;

  /// Si se define, reemplaza la acción por defecto (selector de navegación).
  final VoidCallback? onTap;

  bool get _isPreview => mode == JobMapDisplayMode.preview;

  double get _zoom => _isPreview ? 17.5 : 15;

  Future<void> _handleTap(BuildContext context) async {
    if (onTap != null) {
      onTap!();
      return;
    }
    await ExternalMapLauncher.showNavigationChooser(
      context,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Widget _previewHint(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.55),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.navigation_outlined, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(
                'Toca para navegar',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emphasisPin() {
    if (!_isPreview) return const SizedBox.shrink();

    return IgnorePointer(
      child: Center(
        child: Icon(
          Icons.location_on,
          color: const Color(0xFFE53935),
          size: 38,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
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
              initialZoom: _zoom,
              interactionOptions: InteractionOptions(
                flags: _isPreview
                    ? InteractiveFlag.none
                    : InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.myworksapp.myworksapp',
              ),
              if (!_isPreview)
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
          _emphasisPin(),
          if (_isPreview) _previewHint(context),
          if (!_isPreview)
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
        ],
      ),
    );
  }

  Widget _googleMap(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          gmaps.GoogleMap(
            initialCameraPosition: gmaps.CameraPosition(
              target: gmaps.LatLng(latitude, longitude),
              zoom: _zoom,
            ),
            markers: _isPreview
                ? {}
                : {
                    gmaps.Marker(
                      markerId: const gmaps.MarkerId('job_location'),
                      position: gmaps.LatLng(latitude, longitude),
                    ),
                  },
            zoomControlsEnabled: !_isPreview,
            myLocationButtonEnabled: !_isPreview,
            myLocationEnabled: !_isPreview,
            scrollGesturesEnabled: !_isPreview,
            zoomGesturesEnabled: !_isPreview,
            rotateGesturesEnabled: !_isPreview,
            tiltGesturesEnabled: !_isPreview,
            mapType: gmaps.MapType.normal,
          ),
          _emphasisPin(),
          if (_isPreview) _previewHint(context),
        ],
      ),
    );
  }

  Widget _mapBody(BuildContext context) {
    if (AppPlatform.supportsEmbeddedGoogleMap &&
        GoogleMapsConfig.useEmbeddedGoogleMap) {
      return _googleMap(context);
    }
    return _desktopMap(context);
  }

  @override
  Widget build(BuildContext context) {
    final map = SizedBox(
      height: height,
      width: double.infinity,
      child: _mapBody(context),
    );

    if (!_isPreview) {
      return map;
    }

    return Material(
      color: AppColors.brandOrange.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _handleTap(context),
        child: map,
      ),
    );
  }
}
