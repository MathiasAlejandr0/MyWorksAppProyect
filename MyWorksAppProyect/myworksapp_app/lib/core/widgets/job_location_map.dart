import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../map/app_map_tiles.dart';
import '../theme/app_colors.dart';
import '../utils/external_map_launcher.dart';

/// Modo del mapa embebido.
enum JobMapDisplayMode {
  /// Vista compacta: punto destacado, sin gestos, abre navegación al tocar.
  preview,

  /// Vista interactiva para seleccionar/confirmar ubicación en formularios.
  interactive,
}

/// Mapa de ubicación con OpenFreeMap Positron (el recorte estático de OSM fallaba en web).
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

  double get _zoom => _isPreview ? 15 : 15;

  static bool hasUsablePoint(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    if (!latitude.isFinite || !longitude.isFinite) return false;
    if (latitude.abs() > 90 || longitude.abs() > 180) return false;
    if (latitude.abs() < 0.01 && longitude.abs() < 0.01) return false;
    return true;
  }

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

  Widget _osmMap(BuildContext context) {
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
                cursorKeyboardRotationOptions:
                    CursorKeyboardRotationOptions.disabled(),
              ),
            ),
            children: [
              const AppMapTiles(),
              const MapTileCredits(alignment: Alignment.topLeft),
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
          if (_isPreview) _previewHint(context),
        ],
      ),
    );
  }

  Widget _mapBody(BuildContext context) {
    return _osmMap(context);
  }

  @override
  Widget build(BuildContext context) {
    if (!hasUsablePoint(latitude, longitude)) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.brandOrange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text('Sin coordenadas para mostrar el mapa'),
          ),
        ),
      );
    }

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
