import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../services/user_location_service.dart';
import '../theme/app_colors.dart';
import '../utils/chile_comunas.dart';
import 'dialog_controllers_scope.dart';
import 'job_location_map.dart';
import '../map/app_map_tiles.dart';

class LocationPickerWidget extends StatefulWidget {
  final Function(String address, double latitude, double longitude) onLocationSelected;
  final String? initialAddress;

  const LocationPickerWidget({
    super.key,
    required this.onLocationSelected,
    this.initialAddress,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  String _currentAddress = 'Detectando tu ubicación...';
  bool _isLoading = true;
  bool _hasError = false;
  String? _lastEmittedAddress;
  double? _latitude;
  double? _longitude;
  bool _fetching = false;

  void _emitLocation(String address, double latitude, double longitude) {
    if (_lastEmittedAddress == address) return;
    _lastEmittedAddress = address;
    widget.onLocationSelected(address, latitude, longitude);
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted || _fetching) return;
    _fetching = true;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _currentAddress = 'Detectando tu ubicación...';
      _latitude = null;
      _longitude = null;
    });

    try {
      const quick = Duration(seconds: 3);
      final serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(quick, onTimeout: () => false);
      if (!serviceEnabled) {
        _useFallbackLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission()
          .timeout(quick, onTimeout: () => LocationPermission.denied);
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _useFallbackLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _useFallbackLocation();
        return;
      }

      // GPS con límite de tiempo; si no responde, última conocida o la demo.
      final position = await UserLocationService.instance.currentPosition(
        accuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      if (position == null) {
        _useFallbackLocation();
        return;
      }
      if (!ChileComunas.inChile(position.latitude, position.longitude)) {
        _useFallbackLocation();
        return;
      }
      await _getAddressFromCoordinates(position.latitude, position.longitude);
    } catch (e) {
      if (!mounted) return;
      _useFallbackLocation();
    } finally {
      _fetching = false;
    }
  }

  void _useFallbackLocation() {
    if (!mounted) return;
    const fallbackAddr = UserLocationService.demoFallbackLabel;
    const lat = UserLocationService.demoFallbackLatitude;
    const lng = UserLocationService.demoFallbackLongitude;
    setState(() {
      _currentAddress = fallbackAddr;
      _latitude = lat;
      _longitude = lng;
      _isLoading = false;
      _hasError = false;
    });
    _emitLocation(fallbackAddr, lat, lng);
  }

  Future<void> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await Geocoding(locale: const Locale('es'))
          .placemarkFromCoordinates(latitude, longitude)
          .timeout(const Duration(seconds: 5));

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        final address = _formatAddress(place);
        if (!mounted) return;
        setState(() {
          _currentAddress = address;
          _latitude = latitude;
          _longitude = longitude;
          _isLoading = false;
          _hasError = false;
        });
        _emitLocation(address, latitude, longitude);
        unawaited(_cacheLocation(latitude, longitude));
      } else {
        if (!mounted) return;
        setState(() {
          _currentAddress = _coordsLabel(latitude, longitude);
          _latitude = latitude;
          _longitude = longitude;
          _isLoading = false;
          _hasError = false;
        });
        _emitLocation(
          'Ubicación: $latitude, $longitude',
          latitude,
          longitude,
        );
        unawaited(_cacheLocation(latitude, longitude));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentAddress = _coordsLabel(latitude, longitude);
        _latitude = latitude;
        _longitude = longitude;
        _isLoading = false;
        _hasError = false;
      });
      _emitLocation(
        'Ubicación: $latitude, $longitude',
        latitude,
        longitude,
      );
      unawaited(_cacheLocation(latitude, longitude));
    }
  }

  Future<void> _pickOnMap() async {
    final initial = ll.LatLng(
      _latitude ?? UserLocationService.demoFallbackLatitude,
      _longitude ?? UserLocationService.demoFallbackLongitude,
    );
    final picked = await showModalBottomSheet<ll.LatLng>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ClientMapPickerSheet(initial: initial),
    );
    if (picked == null || !mounted) return;
    await _getAddressFromCoordinates(picked.latitude, picked.longitude);
  }

  /// Permite corregir la dirección a mano (p. ej. el GPS del emulador).
  Future<void> _editAddress() async {
    final controller = TextEditingController(
      text: _isLoading ? '' : _currentAddress,
    );
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => DialogControllersScope(
        controllers: [controller],
        child: AlertDialog(
          title: const Text('Editar dirección'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Calle y número, comuna',
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (v) => Navigator.of(ctx).pop(v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: const Text('Usar dirección'),
            ),
          ],
        ),
      ),
    );
    final query = text?.trim() ?? '';
    if (query.isEmpty || !mounted) return;

    double? lat = _latitude;
    double? lng = _longitude;
    var address = query;
    try {
      final geo = await UserLocationService.instance.fromAddress(query);
      if (geo?.latitude != null && geo?.longitude != null) {
        lat = geo!.latitude;
        lng = geo.longitude;
        address = geo.displayLabel;
      }
    } catch (_) {
      // Sin geocodificación: se conserva la coordenada actual.
    }
    if (!mounted) return;
    lat ??= UserLocationService.demoFallbackLatitude;
    lng ??= UserLocationService.demoFallbackLongitude;
    setState(() {
      _currentAddress = address;
      _latitude = lat;
      _longitude = lng;
      _isLoading = false;
      _hasError = false;
    });
    _emitLocation(address, lat, lng);
  }

  Future<void> _cacheLocation(double latitude, double longitude) async {
    try {
      final ctx = await UserLocationService.instance.fromCoordinates(
        latitude,
        longitude,
      );
      await UserLocationService.instance.persist(ctx);
    } catch (_) {
      // El caché es opcional: la ubicación ya se mostró y se emitió.
    }
  }

  String _coordsLabel(double latitude, double longitude) {
    return 'Ubicación GPS: ${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
  }

  String _formatAddress(Placemark place) {
    final parts = <String>[];

    // En Android `street` suele traer la línea completa ("Calle 123, Comuna,
    // Región, País"); usar thoroughfare/subThoroughfare evita duplicados.
    final thoroughfare = place.thoroughfare?.trim() ?? '';
    final number = place.subThoroughfare?.trim() ?? '';
    var streetLine = '';
    if (thoroughfare.isNotEmpty) {
      streetLine = number.isNotEmpty && !thoroughfare.contains(number)
          ? '$thoroughfare $number'
          : thoroughfare;
    } else if ((place.street ?? '').trim().isNotEmpty) {
      streetLine = place.street!.split(',').first.trim();
    } else if (number.isNotEmpty) {
      streetLine = '#$number';
    }
    if (streetLine.isNotEmpty) parts.add(streetLine);

    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    } else if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
      parts.add(place.subAdministrativeArea!);
    }

    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }

    if (parts.length < 2 && place.country != null && place.country!.isNotEmpty) {
      parts.add(place.country!);
    }

    return parts.isNotEmpty ? parts.join(', ') : 'Ubicación detectada';
  }

  @override
  Widget build(BuildContext context) {
    final hasCoords = _latitude != null && _longitude != null;
    final status = _hasError
        ? LocationStatus.error
        : _isLoading
            ? LocationStatus.loading
            : LocationStatus.ready;

    return LocationStatusCard(
      status: status,
      address: _currentAddress,
      hasCoords: hasCoords,
      preview: hasCoords && !_hasError
          ? JobLocationMap(
              latitude: _latitude!,
              longitude: _longitude!,
              // Vista estática: un mapa interactivo dentro del scroll congela
              // el gesto. El punto se elige en el mapa a pantalla completa.
              mode: JobMapDisplayMode.preview,
              height: 120,
              onTap: _pickOnMap,
            )
          : null,
      onPickOnMap: _pickOnMap,
      onEditAddress: _editAddress,
      onRefresh: _getCurrentLocation,
    );
  }
}

enum LocationStatus { loading, ready, error }

/// Colores de la tarjeta de ubicación según estado y tema.
///
/// Todos los textos tienen contraste ≥ 4.5:1 sobre el fondo de la tarjeta
/// (compuesto sobre el fondo de pantalla), en tema claro y oscuro.
class LocationCardPalette {
  const LocationCardPalette({
    required this.background,
    required this.border,
    required this.icon,
    required this.title,
    required this.body,
    required this.hint,
  });

  final Color background;
  final Color border;
  final Color icon;
  final Color title;
  final Color body;
  final Color hint;

  factory LocationCardPalette.of(Brightness brightness, LocationStatus status) {
    final dark = brightness == Brightness.dark;
    if (status == LocationStatus.error) {
      return LocationCardPalette(
        background: dark ? const Color(0x2EFF5A52) : Colors.red.shade50,
        border: dark ? const Color(0x80FF8A80) : Colors.red.shade300,
        icon: dark ? const Color(0xFFFF8A80) : Colors.red.shade700,
        title: dark ? const Color(0xFFFFB4AB) : Colors.red.shade900,
        body: dark ? AppColors.white : AppColors.textPrimary,
        hint: dark ? AppColors.onCanvasMuted(Brightness.dark) : const Color(0xFF55555B),
      );
    }
    final loading = status == LocationStatus.loading;
    return LocationCardPalette(
      background: AppColors.brandOrangeSoft,
      border: AppColors.brandOrange.withValues(alpha: loading ? 0.35 : 0.45),
      icon: dark ? AppColors.brandOrange : const Color(0xFFC2410C),
      title: dark ? AppColors.white : AppColors.textPrimary,
      body: dark ? AppColors.white : AppColors.textPrimary,
      hint: dark ? AppColors.onCanvasMuted(Brightness.dark) : const Color(0xFF55555B),
    );
  }
}

/// Tarjeta de estado de la ubicación del cliente (detectando, lista o error).
class LocationStatusCard extends StatelessWidget {
  const LocationStatusCard({
    super.key,
    required this.status,
    required this.address,
    required this.hasCoords,
    this.preview,
    this.onPickOnMap,
    this.onEditAddress,
    this.onRefresh,
  });

  final LocationStatus status;
  final String address;
  final bool hasCoords;
  final Widget? preview;
  final VoidCallback? onPickOnMap;
  final VoidCallback? onEditAddress;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final hasError = status == LocationStatus.error;
    final isLoading = status == LocationStatus.loading;
    final palette = LocationCardPalette.of(Theme.of(context).brightness, status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (preview != null) ...[
            preview!,
            const SizedBox(height: 12),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                hasError
                    ? Icons.error_outline
                    : isLoading
                        ? Icons.my_location
                        : Icons.check_circle,
                color: palette.icon,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasError
                          ? 'Error de ubicación'
                          : isLoading
                              ? 'Detectando ubicación'
                              : 'Ubicación detectada',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: palette.title,
                          ),
                    ),
                    const SizedBox(height: 4),
                    isLoading
                        ? Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: palette.icon,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Obteniendo tu ubicación GPS...',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: palette.body),
                                ),
                              ),
                            ],
                          )
                        : Text(
                            address,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: palette.body,
                                ),
                          ),
                  ],
                ),
              ),
              if (!isLoading)
                IconButton(
                  icon: const Icon(Icons.map_outlined),
                  onPressed: onPickOnMap,
                  tooltip: 'Marcar en el mapa',
                  color: AppColors.brandOrange,
                ),
              if (!isLoading)
                IconButton(
                  icon: const Icon(Icons.edit_location_alt_outlined),
                  onPressed: onEditAddress,
                  tooltip: 'Editar dirección',
                  color: AppColors.brandOrange,
                ),
              if (!isLoading)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: onRefresh,
                  tooltip: 'Actualizar ubicación',
                  color: AppColors.brandOrange,
                ),
            ],
          ),
          if (!isLoading && !hasError) ...[
            const SizedBox(height: 8),
            Text(
              hasCoords
                  ? 'Toca el mapa o arrastra el pin azul. También puedes usar GPS o una dirección escrita.'
                  : 'Esperando coordenadas GPS...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.hint,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClientMapPickerSheet extends StatefulWidget {
  const _ClientMapPickerSheet({required this.initial});

  final ll.LatLng initial;

  @override
  State<_ClientMapPickerSheet> createState() => _ClientMapPickerSheetState();
}

class _ClientMapPickerSheetState extends State<_ClientMapPickerSheet> {
  late ll.LatLng _point = widget.initial;
  final _map = MapController();
  bool _dragging = false;

  @override
  void dispose() {
    try {
      _map.dispose();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.72;
    return SizedBox(
      height: height,
      child: Column(
        children: [
            const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Toca el mapa o arrastra el pin azul',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: _point,
                initialZoom: 15,
                onTap: _dragging
                    ? null
                    : (_, point) => setState(() => _point = point),
                interactionOptions: InteractionOptions(
                  flags: _dragging
                      ? InteractiveFlag.none
                      : InteractiveFlag.all & ~InteractiveFlag.rotate,
                  cursorKeyboardRotationOptions:
                      CursorKeyboardRotationOptions.disabled(),
                ),
              ),
              children: [
                const AppMapTiles(),
                const MapTileCredits(),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _point,
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (_) => setState(() => _dragging = true),
                        onPanUpdate: (details) {
                          try {
                            final camera = _map.camera;
                            final current = camera.latLngToScreenOffset(_point);
                            final next = camera.screenOffsetToLatLng(
                              current + details.delta,
                            );
                            setState(() => _point = next);
                          } catch (_) {}
                        },
                        onPanEnd: (_) => setState(() => _dragging = false),
                        onPanCancel: () => setState(() => _dragging = false),
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFF2563EB),
                          size: 36,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _point),
                  // El tema global usa ancho mínimo infinito; dentro de un
                  // Row hay que acotarlo para que el botón se pueda dibujar.
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                  child: const Text('Usar este punto'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
