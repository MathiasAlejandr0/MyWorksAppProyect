import 'package:flutter/material.dart';

import '../../../../core/services/demo_tour_service.dart';
import '../../../../core/widgets/app_guided_tour.dart';

/// Guía del panel del trabajador con tooltips anclados.
class WorkerDemoTourOverlay extends StatelessWidget {
  const WorkerDemoTourOverlay({
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
      shouldShow: DemoTourService.shouldShowWorkerHomeTour,
      onComplete: DemoTourService.completeWorkerHomeTour,
      badgeLabel: 'Guía profesional',
      child: child,
    );
  }
}
