import 'package:flutter/material.dart';

import '../../database/models/service_model.dart';
import '../../design_system/app_radius.dart';
import '../../design_system/app_spacing.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_decorations.dart';
import '../../theme/service_card_palettes.dart';

/// Card para servicios — modo simple o grid del home con paleta por categoría.
class ServiceCard extends StatelessWidget {
  final String name;
  final String? description;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final ServiceCardPalette? palette;
  final bool compact;
  final String? actionLabel;

  const ServiceCard({
    super.key,
    required this.name,
    this.description,
    required this.icon,
    this.onTap,
    this.color,
    this.palette,
    this.compact = false,
    this.actionLabel,
  });

  factory ServiceCard.fromService({
    required ServiceModel service,
    required VoidCallback onTap,
    bool compact = false,
  }) {
    return ServiceCard(
      name: displayName(service),
      description: taglineFor(service.category),
      icon: iconFor(service.category),
      palette: ServiceCardPalette.forCategory(service.category),
      onTap: onTap,
      compact: compact,
      actionLabel: 'Solicitar',
    );
  }

  static String displayName(ServiceModel service) {
    switch (service.category) {
      case ServiceCategories.construction:
        return 'Maestro Constructor';
      case ServiceCategories.plumbing:
        return 'Gásfiter';
      case ServiceCategories.electrical:
        return 'Electricista';
      case ServiceCategories.gardening:
        return 'Jardinero';
      case ServiceCategories.cleaning:
        return 'Limpieza';
      case ServiceCategories.assembly:
        return 'Armado de muebles';
      case ServiceCategories.techSupport:
        return 'Soporte técnico';
      case ServiceCategories.moving:
        return 'Mudanzas';
      default:
        return service.name;
    }
  }

  static String taglineFor(String category) {
    switch (category) {
      case ServiceCategories.construction:
        return 'Obra y reparaciones';
      case ServiceCategories.plumbing:
        return 'Fugas y grifería';
      case ServiceCategories.electrical:
        return 'Enchufes e iluminación';
      case ServiceCategories.gardening:
        return 'Poda y mantención';
      case ServiceCategories.cleaning:
        return 'Hogar y oficina';
      case ServiceCategories.assembly:
        return 'Montaje de muebles';
      case ServiceCategories.techSupport:
        return 'Equipos y redes';
      case ServiceCategories.moving:
        return 'Traslados y fletes';
      default:
        return 'Profesionales verificados';
    }
  }

  static IconData iconFor(String category) {
    switch (category) {
      case ServiceCategories.construction:
        return Icons.architecture_rounded;
      case ServiceCategories.plumbing:
        return Icons.plumbing_rounded;
      case ServiceCategories.electrical:
        return Icons.bolt_rounded;
      case ServiceCategories.gardening:
        return Icons.yard_rounded;
      case ServiceCategories.cleaning:
        return Icons.cleaning_services_rounded;
      case ServiceCategories.assembly:
        return Icons.chair_rounded;
      case ServiceCategories.techSupport:
        return Icons.computer_rounded;
      case ServiceCategories.moving:
        return Icons.local_shipping_rounded;
      default:
        return Icons.handyman_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (palette != null) {
      return _HomeStyleCard(
        name: name,
        tagline: description ?? '',
        icon: icon,
        palette: palette!,
        onTap: onTap,
        compact: compact,
        actionLabel: actionLabel ?? 'Solicitar',
      );
    }

    final accent = color ?? AppColors.brandOrange;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          decoration: AppDecorations.surfaceCard(accent: accent),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.22),
                        accent.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, size: 24, color: accent),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description!,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeStyleCard extends StatelessWidget {
  const _HomeStyleCard({
    required this.name,
    required this.tagline,
    required this.icon,
    required this.palette,
    required this.onTap,
    required this.compact,
    required this.actionLabel,
  });

  final String name;
  final String tagline;
  final IconData icon;
  final ServiceCardPalette palette;
  final VoidCallback? onTap;
  final bool compact;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.white, palette.background],
            ),
            border: Border.all(color: palette.accent.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: palette.accent.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 44 : 52,
                height: compact ? 44 : 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: palette.iconBackground,
                  border: Border.all(
                    color: palette.accent.withValues(alpha: 0.16),
                  ),
                ),
                child: Icon(
                  icon,
                  size: compact ? 22 : 26,
                  color: palette.accent,
                ),
              ),
              const Spacer(),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: compact ? 13 : 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
              ),
              SizedBox(height: compact ? 3 : AppSpacing.xs),
              Text(
                tagline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: compact ? 10.5 : 11.5,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              SizedBox(height: compact ? AppSpacing.sm + 2 : 14),
              Row(
                children: [
                  Text(
                    actionLabel,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.accent,
                        ),
                  ),
                  const SizedBox(width: AppSpacing.xs + 1),
                  Container(
                    width: compact ? 18 : 20,
                    height: compact ? 18 : 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.accent.withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: compact ? 12 : 13,
                      color: palette.accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
