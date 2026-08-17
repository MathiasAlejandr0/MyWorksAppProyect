import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../database/models/worker_model.dart';
import '../../design_system/app_radius.dart';
import '../../design_system/app_spacing.dart';
import '../../services/app_feedback.dart';
import '../../theme/app_colors.dart';

/// Widget interactivo estilo Radar de Profesionales en Vivo para el Dashboard.
class LiveWorkerRadarWidget extends StatefulWidget {
  final List<WorkerModel> workers;
  final String city;

  const LiveWorkerRadarWidget({
    super.key,
    required this.workers,
    this.city = 'Santiago / Puerto Montt',
  });

  @override
  State<LiveWorkerRadarWidget> createState() => _LiveWorkerRadarWidgetState();
}

class _LiveWorkerRadarWidgetState extends State<LiveWorkerRadarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  late Animation<double> _pulseAnimation;
  WorkerModel? _selectedWorker;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _radarController, curve: Curves.easeOutQuad),
    );
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeCount = widget.workers.isEmpty ? 5 : widget.workers.length;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDark
              ? AppColors.grayBorder.withValues(alpha: 0.12)
              : AppColors.grayBorder.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del Radar
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.emerald,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emerald,
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profesionales en Vivo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.white : AppColors.brandNavy,
                      ),
                    ),
                    Text(
                      '$activeCount activos en ${widget.city}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.grayLight : AppColors.grayMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.brandOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.radar_rounded, size: 14, color: AppColors.brandOrange),
                    SizedBox(width: 4),
                    Text(
                      'RADAR 24/7',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Pantalla Radar Interactivas con Ondas Pulsantes
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF0F172A),
                        const Color(0xFF1E293B),
                      ]
                    : [
                        const Color(0xFF1E293B),
                        const Color(0xFF0F172A),
                      ],
              ),
            ),
            child: Stack(
              children: [
                // 1. Anillos de Ondas de Radar Animadas
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      final scale = _pulseAnimation.value;
                      final opacity = (1.0 - scale).clamp(0.0, 1.0);
                      return Center(
                        child: Container(
                          width: 170 * scale,
                          height: 170 * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.brandOrange.withValues(alpha: opacity * 0.6),
                              width: 1.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Anillo Fijo Central
                Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                  ),
                ),

                // 2. Pines de Profesionales Activos en Posiciones Clave
                _RadarPin(
                  top: 25,
                  left: 45,
                  label: 'Juan E.',
                  profession: 'Electricista',
                  rating: '4.9 ⭐',
                  onTap: () => _showWorkerSheet(context, 'Juan E.', 'Electricista', '4.9 ⭐', 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=400'),
                ),
                _RadarPin(
                  top: 90,
                  right: 35,
                  label: 'Carlos M.',
                  profession: 'Gásfiter',
                  rating: '5.0 ⭐',
                  onTap: () => _showWorkerSheet(context, 'Carlos M.', 'Gásfiter', '5.0 ⭐', 'https://images.unsplash.com/photo-1585703903930-0b8e341a0895?w=400'),
                ),
                _RadarPin(
                  bottom: 30,
                  left: 70,
                  label: 'María P.',
                  profession: 'Limpieza',
                  rating: '4.8 ⭐',
                  onTap: () => _showWorkerSheet(context, 'María P.', 'Limpieza', '4.8 ⭐', 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400'),
                ),
                _RadarPin(
                  top: 40,
                  right: 120,
                  label: 'Pedro A.',
                  profession: 'Constructor',
                  rating: '4.9 ⭐',
                  onTap: () => _showWorkerSheet(context, 'Pedro A.', 'Constructor', '4.9 ⭐', 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=400'),
                ),

                // Centro: Tu Ubicación
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandOrange,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandOrange.withValues(alpha: 0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.my_location_rounded, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Tú',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showWorkerSheet(BuildContext context, String name, String profession, String rating, String img) {
    AppFeedback.light();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                radius: 26,
                backgroundImage: NetworkImage(img),
              ),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              subtitle: Text('$profession • $rating', style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w600)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Text('Disponible', style: TextStyle(color: AppColors.emerald, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/search');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandOrange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
              ),
              child: const Text('Ver perfil y solicitar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarPin extends StatelessWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final String label;
  final String profession;
  final String rating;
  final VoidCallback onTap;

  const _RadarPin({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.label,
    required this.profession,
    required this.rating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: AppColors.brandNavy, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.emerald,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.brandNavy,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
