import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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
  double? _latitude;
  double? _longitude;

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
    });

    try {
      // Verificar si los servicios de ubicación están habilitados
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

      // Verificar y solicitar permisos
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
          _currentAddress = 'Los permisos de ubicación fueron denegados permanentemente. Por favor, habilítalos en la configuración';
          _isLoading = false;
          _hasError = true;
        });
        return;
      }

      // Obtener ubicación actual con alta precisión
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      // Obtener dirección desde las coordenadas
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
          _isLoading = false;
          _hasError = false;
        });
        if (mounted) {
          widget.onLocationSelected(address, latitude, longitude);
        }
      } else {
        if (!mounted) return;
        setState(() {
          _currentAddress = 'No se pudo obtener la dirección. Ubicación: $latitude, $longitude';
          _isLoading = false;
          _hasError = false;
        });
        // Aún así, notificamos la ubicación con coordenadas
        if (mounted) {
          widget.onLocationSelected(
            'Ubicación: $latitude, $longitude',
            latitude,
            longitude,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentAddress = 'Ubicación detectada: $latitude, $longitude';
        _isLoading = false;
        _hasError = false;
      });
      // Notificamos con coordenadas si no podemos obtener la dirección
      if (mounted) {
        widget.onLocationSelected(
          'Ubicación: $latitude, $longitude',
          latitude,
          longitude,
        );
      }
    }
  }

  String _formatAddress(Placemark place) {
    final parts = <String>[];
    
    // Calle y número
    if (place.street != null && place.street!.isNotEmpty) {
      if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
        parts.add('${place.street!} #${place.subThoroughfare}');
      } else {
        parts.add(place.street!);
      }
    } else if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
      parts.add('#${place.subThoroughfare}');
    }
    
    // Localidad/Comuna
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    } else if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
      parts.add(place.subAdministrativeArea!);
    }
    
    // Región/Provincia
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }
    
    // País (opcional, solo si no hay mucha información)
    if (parts.length < 2 && place.country != null && place.country!.isNotEmpty) {
      parts.add(place.country!);
    }
    
    return parts.isNotEmpty ? parts.join(', ') : 'Ubicación detectada';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _hasError 
            ? Colors.red.shade50 
            : _isLoading 
                ? Colors.blue.shade50 
                : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasError 
              ? Colors.red.shade300 
              : _isLoading 
                  ? Colors.blue.shade300 
                  : Colors.green.shade300,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                        ? Colors.blue 
                        : Colors.green,
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
                                ? Colors.blue.shade700 
                                : Colors.green.shade700,
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
                              Text('Obteniendo tu ubicación GPS...'),
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
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
          if (!_isLoading && !_hasError) ...[
            const SizedBox(height: 8),
            Text(
              '✓ Tu ubicación ha sido detectada automáticamente',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.green.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

