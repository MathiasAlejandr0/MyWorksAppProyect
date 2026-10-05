import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/database/supabase_db.dart';
import '../../../../core/services/gps_publish_gate.dart';
import '../../../../core/theme/app_colors.dart';

/// Publica la ubicación solo en primer plano, con el trabajo en camino o en curso.
class WorkerGpsPublisher extends StatefulWidget {
  const WorkerGpsPublisher({
    super.key,
    required this.jobId,
    required this.active,
  });

  final String jobId;
  final bool active;

  @override
  State<WorkerGpsPublisher> createState() => _WorkerGpsPublisherState();
}

class _WorkerGpsPublisherState extends State<WorkerGpsPublisher> with WidgetsBindingObserver {
  final GpsPublishGate _gate = GpsPublishGate();
  StreamSubscription<Position>? _sub;
  String? _notice;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.active) unawaited(_start());
  }

  @override
  void didUpdateWidget(WorkerGpsPublisher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_sending && _sub == null) {
      unawaited(_start());
    } else if (!widget.active) {
      unawaited(_stop());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.active) {
      unawaited(_start());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(_stop(keepNotice: true));
    }
  }

  Future<void> _start() async {
    if (_sub != null) return;
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      if (mounted) setState(() => _notice = 'Activa el GPS del teléfono para compartir el trayecto.');
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() => _notice = 'Sin permiso de ubicación el cliente no ve el pin en el mapa.');
      }
      return;
    }
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 40,
      ),
    ).listen((position) async {
      if (!widget.active) return;
      if (!_gate.shouldPublish(
        now: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
      )) {
        return;
      }
      try {
        await supabase.rpc('publicar_ubicacion_trabajo', params: {
          'p_trabajo_id': widget.jobId,
          'p_lat': position.latitude,
          'p_lng': position.longitude,
          'p_precision': position.accuracy,
        });
        if (mounted) setState(() => _notice = 'Ubicación compartida con el cliente de este pedido.');
      } catch (e) {
        if (mounted) setState(() => _notice = 'No se pudo publicar la ubicación. Revisa la migración de GPS.');
      }
    }, onError: (_) {
      if (mounted) setState(() => _notice = 'El GPS del teléfono no entregó una posición.');
    });
    if (mounted) {
      setState(() {
        _sending = true;
        _notice = 'Compartiendo ubicación en primer plano. Se detiene si cierras la app o termina el trabajo.';
      });
    }
  }

  Future<void> _stop({bool keepNotice = false}) async {
    await _sub?.cancel();
    _sub = null;
    _sending = false;
    if (mounted && !keepNotice && !widget.active) {
      setState(() => _notice = 'Se dejó de publicar la ubicación.');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active && _notice == null) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              widget.active ? Icons.my_location : Icons.location_off_outlined,
              color: AppColors.brandOrange,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(_notice ?? 'GPS del pedido')),
          ],
        ),
      ),
    );
  }
}
