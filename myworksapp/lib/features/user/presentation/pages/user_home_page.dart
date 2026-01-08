import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/database/repositories/service_repository.dart';
import '../../../../core/database/models/service_model.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class UserHomePage extends ConsumerStatefulWidget {
  const UserHomePage({super.key});

  @override
  ConsumerState<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends ConsumerState<UserHomePage> {
  final ServiceRepository _serviceRepository = ServiceRepository();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final userName = user?.name.split(' ').first ?? 'Usuario';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar personalizado
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Hola, $userName 👋',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
            actions: [
              IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                onPressed: () => context.push(AppConstants.routeNotifications),
                tooltip: 'Notificaciones',
              ),
              IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () => context.push(AppConstants.routeUserProfile),
                tooltip: 'Perfil',
              ),
              const SizedBox(width: 8),
            ],
          ),
          // Contenido
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿Qué servicio necesitas?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Selecciona el tipo de servicio que necesitas',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.grayMedium,
                        ),
                  ),
                  const SizedBox(height: 24),
                  FutureBuilder<List<ServiceModel>>(
                    future: _serviceRepository.getMainServices(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const LoadingWidget();
                      }

                      if (snapshot.hasError) {
                        return ErrorDisplayWidget(
                          message: 'Error al cargar servicios: ${snapshot.error}',
                          onRetry: () => setState(() {}),
                        );
                      }

                      final services = snapshot.data ?? [];

                      if (services.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text('No hay servicios disponibles'),
                          ),
                        );
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.9,
                        ),
                        itemCount: services.length,
                        itemBuilder: (context, index) {
                          final service = services[index];
                          return _PremiumServiceCard(service: service);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Acceso rápido al historial
                  PremiumCard(
                    onTap: () => context.push(AppConstants.routeJobHistory),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.history,
                            color: AppColors.primaryLight,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ver Historial',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Revisa tus trabajos anteriores',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.grayMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumServiceCard extends StatelessWidget {
  final ServiceModel service;

  const _PremiumServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: () {
        context.push(
          AppConstants.routeServiceRequest,
          extra: {'serviceId': service.id},
        );
      },
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryLight.withOpacity(0.2),
                  AppColors.primaryLight.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getServiceIcon(service.name),
              size: 32,
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            service.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (service.description != null) ...[
            const SizedBox(height: 4),
            Text(
              service.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grayMedium,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  IconData _getServiceIcon(String serviceName) {
    // Iconos únicos para cada servicio principal
    final name = serviceName.toLowerCase();
    
    if (name.contains('limpieza') || name.contains('cleaning')) return Icons.cleaning_services;
    if (name.contains('construcción') || name.contains('construction')) return Icons.home_work;
    if (name.contains('plomería') || name.contains('plumbing') || name.contains('gasfiter')) return Icons.plumbing;
    if (name.contains('electricidad') || name.contains('electrical') || name.contains('electricista')) return Icons.electrical_services;
    if (name.contains('cerrajero') || name.contains('locksmith')) return Icons.lock;
    if (name.contains('pintor') || name.contains('painter')) return Icons.format_paint;
    if (name.contains('armado') || name.contains('assembly') || name.contains('muebles')) return Icons.build_circle;
    if (name.contains('soporte técnico') || name.contains('tech support')) return Icons.computer;
    if (name.contains('jardinería') || name.contains('gardening')) return Icons.local_florist;
    if (name.contains('mudanza') || name.contains('moving')) return Icons.local_shipping;
    
    return Icons.build;
  }
}
