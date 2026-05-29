import 'package:flutter/material.dart';

import '../services/demo_tour_service.dart';
import '../theme/app_colors.dart';

/// Overlay de tour guiado sobre el home del usuario.
class DemoTourOverlay extends StatefulWidget {
  const DemoTourOverlay({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<DemoTourOverlay> createState() => _DemoTourOverlayState();
}

class _DemoTourOverlayState extends State<DemoTourOverlay> {
  bool _visible = false;
  int _step = 0;

  static const _steps = [
    ('1. Elige un servicio', 'Toca la categoría que necesitas (limpieza, electricidad, etc.).'),
    ('2. Compara trabajadores', 'Revisa calificación, perfil y trabajos anteriores.'),
    ('3. Envía tu solicitud', 'El profesional revisa tu pedido y te envía una cotización.'),
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final show = await DemoTourService.shouldShowTour();
    if (mounted) setState(() => _visible = show);
  }

  Future<void> _finish() async {
    await DemoTourService.completeTour();
    if (mounted) setState(() => _visible = false);
  }

  void _next() {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_visible)
          Positioned.fill(
            child: Material(
              color: Colors.black.withValues(alpha: 0.55),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: TextButton(
                          onPressed: _finish,
                          child: const Text('Omitir', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Modo guía',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppColors.primaryLight,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _steps[_step].$1,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(_steps[_step].$2, style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 16),
                            Row(
                              children: List.generate(
                                _steps.length,
                                (i) => Container(
                                  width: i == _step ? 20 : 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: i == _step
                                        ? AppColors.primaryLight
                                        : AppColors.grayMedium.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _next,
                              child: Text(
                                _step < _steps.length - 1 ? 'Siguiente' : 'Empezar',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
