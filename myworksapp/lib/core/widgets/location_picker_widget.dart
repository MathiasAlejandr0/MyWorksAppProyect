import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../theme/app_colors.dart';
import 'job_location_map.dart';

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
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _currentAddress = 'Detectando tu ubicación...';
      _latitude = null;
      _longitude = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _currentAddress = 'Por favor activa los servicios de ubicación en tu dispositivo';
          _isLoading = false;
          _hasError = true;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            _currentAddress = 'Se necesitan permisos de ubicación para continuar';
            _isLoading = false;
            _hasError = true;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _currentAddress =
              'Los permisos de ubicación fueron denegados permanentemente. Por favor, habilítalos en la configuración';
          _isLoading = false;
          _hasError = true;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (!mounted) return;
      await _getAddressFromCoordinates(position.latitude, position.longitude);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentAddress = 'Error al obtener ubicación. Intenta nuevamente';
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
        localeIdentifier: 'es',
      );

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
    }
  }

  String _coordsLabel(double latitude, double longitude) {
    return 'Ubicación GPS: ${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
  }

  String _formatAddress(Placemark place) {
    final parts = <String>[];

    if (place.street != null && place.street!.isNotEmpty) {
      if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
        parts.add('${place.street!} #${place.subThoroughfare}');
      } else {
        parts.add(place.street!);
      }
    } else if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
      parts.add('#${place.subThoroughfare}');
    }

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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _hasError
            ? Colors.red.shade50
            : _isLoading
                ? AppColors.brandBlueSoft
                : AppColors.brandOrangeSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasError
              ? Colors.red.shade300
              : _isLoading
                  ? AppColors.brandTeal.withValues(alpha: 0.35)
                  : AppColors.brandOrange.withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasCoords && !_hasError) ...[
            JobLocationMap(
              latitude: _latitude!,
              longitude: _longitude!,
              square: true,
            ),
            const SizedBox(height: 12),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _hasError
                    ? Icons.error_outline
                    : _isLoading
                        ? Icons.my_location
                        : Icons.check_circle,
                color: _hasError
                    ? Colors.red
                    : _isLoading
                        ? AppColors.brandTeal
                        : AppColors.brandOrange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _hasError
                          ? 'Error de ubicación'
                          : _isLoading
                              ? 'Detectando ubicación'
                              : 'Ubicación detectada',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _hasError
                                ? Colors.red.shade700
                                : _isLoading
                                    ? AppColors.brandNavy
                                    : AppColors.brandOrange,
                          ),
                    ),
                    const SizedBox(height: 4),
                    _isLoading
                        ? const Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text('Obteniendo tu ubicación GPS...'),
                              ),
                            ],
                          )
                        : Text(
                            _currentAddress,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                  ],
                ),
              ),
              if (_hasError || (!_isLoading && !_hasError))
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _getCurrentLocation,
                  tooltip: 'Actualizar ubicación',
                  color: AppColors.brandOrange,
                ),
            ],
          ),
          if (!_isLoading && !_hasError) ...[
            const SizedBox(height: 8),
            Text(
              hasCoords
                  ? 'El mapa muestra tu posición actual para que el profesional llegue sin problemas.'
                  : 'Esperando coordenadas GPS...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grayMedium,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
