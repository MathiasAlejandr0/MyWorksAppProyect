import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../database/models/service_model.dart';
import '../../design_system/app_radius.dart';
import '../../theme/app_colors.dart';
import '../../theme/service_card_palettes.dart';

/// Card 3D Héroe para categorías de servicio con fotografía HD real, perspectiva 3D táctil y visuales inmersivas.
class ServiceCard extends StatefulWidget {
  final String name;
  final String? description;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final ServiceCardPalette? palette;
  final bool compact;
  final String? actionLabel;
  final String? categoryKey;

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
    this.categoryKey,
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
      actionLabel: 'Pedir servicio',
      categoryKey: service.category,
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
        return 'Limpieza del Hogar';
      case ServiceCategories.assembly:
        return 'Armado de Muebles';
      case ServiceCategories.techSupport:
        return 'Soporte Técnico';
      case ServiceCategories.moving:
        return 'Mudanzas y Fletes';
      default:
        return service.name;
    }
  }

  static String taglineFor(String category) {
    switch (category) {
      case ServiceCategories.construction:
        return 'Remodelación y albañilería';
      case ServiceCategories.plumbing:
        return 'Fugas, calefón y grifería';
      case ServiceCategories.electrical:
        return 'Tableros, enchufes y luces';
      case ServiceCategories.gardening:
        return 'Poda, césped y paisajismo';
      case ServiceCategories.cleaning:
        return 'Casas, oficinas y dptos.';
      case ServiceCategories.assembly:
        return 'Armado de clósets y racks';
      case ServiceCategories.techSupport:
        return 'Redes, PC e impresoras';
      case ServiceCategories.moving:
        return 'Carga y fletes expresos';
      default:
        return 'Profesionales verificados';
    }
  }

  static IconData iconFor(String category) {
    switch (category) {
      case ServiceCategories.construction:
        return Icons.foundation_rounded;
      case ServiceCategories.plumbing:
        return Icons.water_drop_rounded;
      case ServiceCategories.electrical:
        return Icons.bolt_rounded;
      case ServiceCategories.gardening:
        return Icons.park_rounded;
      case ServiceCategories.cleaning:
        return Icons.cleaning_services_rounded;
      case ServiceCategories.assembly:
        return Icons.handyman_rounded;
      case ServiceCategories.techSupport:
        return Icons.devices_other_rounded;
      case ServiceCategories.moving:
        return Icons.local_shipping_rounded;
      default:
        return Icons.build_rounded;
    }
  }

  /// Foto del oficio. Prefijo `asset:` = imagen local; si no, URL remota.
  static String imageUrlFor(String category) {
    final cat = category.toLowerCase().trim();
    const q = 'auto=format&fit=crop&w=900&h=700&q=80';
    if (cat.contains('construction') ||
        cat.contains('construc') ||
        cat.contains('obra') ||
        cat.contains('alba')) {
      return 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?$q';
    }
    if (cat.contains('plumb') ||
        cat.contains('gásfiter') ||
        cat.contains('gasfiter') ||
        cat.contains('plomer') ||
        cat.contains('fuga') ||
        cat.contains('calefon') ||
        cat.contains('calefón') ||
        cat.contains('grifer')) {
      return 'asset:assets/images/services/plumbing.png';
    }
    if (cat.contains('electr') || cat.contains('luz') || cat.contains('enchufe')) {
      return 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?$q';
    }
    if (cat.contains('garden') || cat.contains('jardin') || cat.contains('poda')) {
      return 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?$q';
    }
    if (cat.contains('clean') ||
        cat.contains('limpieza') ||
        cat.contains('aseo') ||
        cat.contains('sanitiz')) {
      return 'asset:assets/images/services/cleaning.png';
    }
    if (cat.contains('assembl') || cat.contains('armado') || cat.contains('mueble')) {
      return 'asset:assets/images/services/assembly.png';
    }
    if (cat.contains('tech') ||
        cat.contains('soporte') ||
        cat.contains('comput') ||
        cat.contains('impresora') ||
        cat.contains('redes')) {
      return 'asset:assets/images/services/tech.png';
    }
    if (cat.contains('mov') ||
        cat.contains('mudanza') ||
        cat.contains('flete') ||
        cat.contains('carga')) {
      return 'asset:assets/images/services/moving.png';
    }
    return 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?$q';
  }

  static String? assetPathFor(String category) {
    final url = imageUrlFor(category);
    if (url.startsWith('asset:')) return url.substring(6);
    return null;
  }

  static String fallbackImageUrlFor(String category) {
    return 'https://images.unsplash.com/photo-1581244277943-fe4a9c777189?auto=format&fit=crop&w=900&h=700&q=80&sig=${category.hashCode.abs()}';
  }


  static String badgeTextFor(String category) {
    switch (category) {
      case ServiceCategories.construction:
        return '4.9 · Garantía';
      case ServiceCategories.plumbing:
        return 'Llegada ~30 min';
      case ServiceCategories.electrical:
        return 'Más solicitado';
      case ServiceCategories.gardening:
        return 'Eco Pro';
      case ServiceCategories.cleaning:
        return 'Sanitizado';
      case ServiceCategories.assembly:
        return 'IKEA / Easy';
      case ServiceCategories.techSupport:
        return 'Diagnóstico 0\$';
      case ServiceCategories.moving:
        return 'Camión incluido';
      default:
        return 'Verificado';
    }
  }

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  // Parámetros de perspectiva 3D (Tilt effect)
  double _rotateX = 0;
  double _rotateY = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onPointerMove(PointerMoveEvent event, BoxConstraints constraints) {
    final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
    final touchOffset = event.localPosition - center;

    setState(() {
      // Inclinación máxima de 0.08 radianes en X e Y
      _rotateX = (-touchOffset.dy / (constraints.maxHeight / 2)) * 0.08;
      _rotateY = (touchOffset.dx / (constraints.maxWidth / 2)) * 0.08;
    });
  }

  void _onPointerDown(PointerDownEvent event) {
    _animController.forward();
  }

  void _onPointerUp(PointerUpEvent event) {
    _animController.reverse();
    setState(() {
      _rotateX = 0;
      _rotateY = 0;
    });
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _animController.reverse();
    setState(() {
      _rotateX = 0;
      _rotateY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final catKey = widget.categoryKey ?? ServiceCategories.electrical;
    final palette = widget.palette ?? ServiceCardPalette.forCategory(catKey);
    final imageUrl = ServiceCard.imageUrlFor(catKey);
    final assetPath = ServiceCard.assetPathFor(catKey);
    final badgeText = ServiceCard.badgeTextFor(catKey);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Listener(
          onPointerDown: _onPointerDown,
          onPointerMove: (event) => _onPointerMove(event, constraints),
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // Perspectiva tridimensional
                ..rotateX(_rotateX)
                ..rotateY(_rotateY),
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: widget.onTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: palette.accent.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            color: const Color(0xFF152033),
                            child: assetPath != null
                                ? Image.asset(
                                    assetPath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFF1A2740),
                                            palette.accent.withValues(alpha: 0.75),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          widget.icon,
                                          size: 48,
                                          color: Colors.white.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 720,
                                    fadeInDuration:
                                        const Duration(milliseconds: 180),
                                    placeholder: (context, url) => Container(
                                      color: const Color(0xFF152033),
                                      alignment: Alignment.center,
                                      child: SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: palette.accent
                                              .withValues(alpha: 0.85),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, error, stackTrace) {
                                      return CachedNetworkImage(
                                        imageUrl: ServiceCard.fallbackImageUrlFor(
                                          catKey,
                                        ),
                                        fit: BoxFit.cover,
                                        memCacheWidth: 720,
                                        errorWidget: (context, e, s) => Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFF1A2740),
                                                palette.accent
                                                    .withValues(alpha: 0.75),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              widget.icon,
                                              size: 48,
                                              color: Colors.white
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),

                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.22),
                                  Colors.black.withValues(alpha: 0.12),
                                  Colors.black.withValues(alpha: 0.58),
                                  Colors.black.withValues(alpha: 0.9),
                                ],
                                stops: const [0.0, 0.35, 0.68, 1.0],
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  widget.compact ? '4.9' : badgeText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            width: widget.compact ? 38 : 44,
                            height: widget.compact ? 38 : 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: palette.accent,
                              boxShadow: [
                                BoxShadow(
                                  color: palette.accent.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.icon,
                              size: widget.compact ? 20 : 24,
                              color: AppColors.white,
                            ),
                          ),
                        ),

                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: widget.compact ? 14.5 : 17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                    height: 1.15,
                                  ),
                                ),
                                if ((widget.description ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    widget.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.88),
                                      fontSize: widget.compact ? 11 : 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: palette.accent,
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.pill),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          widget.actionLabel ?? 'Pedir servicio',
                                          style: const TextStyle(
                                            color: AppColors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 14,
                                          color: AppColors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

