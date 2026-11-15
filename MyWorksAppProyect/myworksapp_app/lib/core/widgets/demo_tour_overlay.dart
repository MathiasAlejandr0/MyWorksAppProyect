import 'package:flutter/material.dart';

import '../services/demo_tour_service.dart';
import 'app_guided_tour.dart';

/// Guía del inicio del usuario con tooltips anclados a la interfaz.
class DemoTourOverlay extends StatelessWidget {
  const DemoTourOverlay({
    super.key,
    required this.child,
    required this.steps,
  });

  final Widget child;
  final List<GuidedTourStep> steps;

  @override
  Widget build(BuildContext context) {
    return AppGuidedTour(
      steps: steps,
      shouldShow: DemoTourService.shouldShowHomeTour,
      onComplete: DemoTourService.completeHomeTour,
      child: child,
    );
  }
}
