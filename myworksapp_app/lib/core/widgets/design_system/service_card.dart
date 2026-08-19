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

  static String imageUrlFor(String category) {
    final cat = category.toLowerCase().trim();
    if (cat.contains('construction') || cat.contains('construc') || cat.contains('obra')) {
      return 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=800&auto=format&fit=crop&q=80';
    } else if (cat.contains('plumb') || cat.contains('gásfiter') || cat.contains('gasfiter') || cat.contains('fuga')) {
      return 'https://images.unsplash.com/photo-1585703903930-0b8e341a0895?w=800&auto=format&fit=crop&q=80';
    } else if (cat.contains('electr') || cat.contains('luz') || cat.contains('enchufe')) {
      return 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=800&auto=format&fit=crop&q=80';
    } else if (cat.contains('garden') || cat.contains('jardin') || cat.contains('poda')) {
      return 'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?w=800&auto=format&fit=crop&q=80';
    } else if (cat.contains('clean') || cat.contains('limpieza') || cat.contains('hogar')) {
      return 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800&auto=format&fit=crop&q=80';
    } else if (cat.contains('assembl') || cat.contains('armado') || cat.contains('mueble')) {
      return 'https://images.unsplash.com/photo-1538688525198-9b88f6f53126?w=800&auto=format&fit=crop&q=80';
    } else if (cat.contains('tech') || cat.contains('soporte') || cat.contains('comput')) {
      return 'https://images.unsplash.com/photo-1588702547923-7093a6c3ba33?w=800&auto=format&fit=crop&q=80';
    } else if (cat.contains('mov') || cat.contains('mudanza') || cat.contains('flete')) {
      return 'https://images.unsplash.com/photo-1600585154340-be6162a9a249?w=800&auto=format&fit=crop&q=80';
    }
    return 'https://images.unsplash.com/photo-1581244277943-fe4a9c777189?w=800&auto=format&fit=crop&q=80';
  }

  static String fallbackImageUrlFor(String category) {
    return 'https://picsum.photos/seed/${category.hashCode}/800/600';
  }


  static String badgeTextFor(String category) {
    switch (category) {
      case ServiceCategories.construction:
        return '⭐ 4.9 · Garantía';
      case ServiceCategories.plumbing:
        return '⚡ LLegada en 30m';
      case ServiceCategories.electrical:
        return '🔥 Más solicitado';
      case ServiceCategories.gardening:
        return '🌿 Eco Pro';
      case ServiceCategories.cleaning:
        return '✨ 100% Sanitizado';
      case ServiceCategories.assembly:
        return '📦 Armado IKEA/Easy';
      case ServiceCategories.techSupport:
        return '💻 Diagnóstico 0\$';
      case ServiceCategories.moving:
        return '🚚 Camión incluido';
      default:
        return '⭐ Verificado';
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
                      // Resplandor de Neón 3D posterior
                      BoxShadow(
                        color: palette.accent.withValues(alpha: 0.35),
                        blurRadius: 20,
                        spreadRadius: -4,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    child: Stack(
                      children: [
                        // 1. Imagen de Fondo HD con Fallback Resiliente
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  palette.accent.withValues(alpha: 0.8),
                                  palette.background,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.network(
                                  ServiceCard.fallbackImageUrlFor(catKey),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, e, s) => Container(
                                    color: palette.accent.withValues(alpha: 0.85),
                                    child: Center(
                                      child: Icon(
                                        widget.icon,
                                        size: 48,
                                        color: Colors.white.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // 2. Capa de Gradiente Vignette (3 niveles de profundidad)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.2),
                                  Colors.black.withValues(alpha: 0.45),
                                  Colors.black.withValues(alpha: 0.92),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        ),

                        // 3. Chip Glassmorphic en esquina superior derecha
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              badgeText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),

                        // 4. Icono circular de categoría en esquina superior izquierda
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
                                  color: palette.accent.withValues(alpha: 0.5),
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

                        // 5. Contenido Textual e Indicador de Acción
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 14,
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
                                  fontSize: widget.compact ? 15 : 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.description ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: widget.compact ? 11 : 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: palette.accent,
                                      borderRadius: BorderRadius.circular(AppRadius.pill),
                                      boxShadow: [
                                        BoxShadow(
                                          color: palette.accent.withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
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
                                ],
                              ),
                            ],
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

