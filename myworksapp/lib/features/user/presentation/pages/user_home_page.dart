import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/models/service_model.dart';
import '../../../../core/database/repositories/service_repository.dart';
import '../../../../core/design_system/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/service_card_palettes.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/app_guided_tour.dart';
import '../../../../core/widgets/demo_tour_overlay.dart';
import '../../../../core/widgets/design_system/app_brand_logo.dart';
import '../../../../core/widgets/design_system/auth_soft_background.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/profile_avatar_picker.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class UserHomePage extends ConsumerStatefulWidget {
  const UserHomePage({super.key});

  @override
  ConsumerState<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends ConsumerState<UserHomePage> {
  final ServiceRepository _serviceRepository = ServiceRepository();
  final _searchController = TextEditingController();
  final _profileKey = GlobalKey();
  final _settingsKey = GlobalKey();
  final _searchKey = GlobalKey();
  final _servicesKey = GlobalKey();
  final _firstServiceKey = GlobalKey();
  List<ServiceModel> _allServices = [];
  String _query = '';

  List<GuidedTourStep> get _homeTourSteps => [
        const GuidedTourStep(
          title: 'Bienvenido a MyWorks',
          description:
              'Te mostraremos cómo pedir un servicio paso a paso. Puedes omitir la guía en cualquier momento.',
          align: TourTooltipAlign.center,
        ),
        GuidedTourStep(
          targetKey: _filteredServices.isNotEmpty ? _firstServiceKey : _servicesKey,
          title: 'Servicios disponibles',
          description:
              'Aquí tienes los trabajos que puedes solicitar: limpieza, electricidad, plomería y más. Toca una tarjeta para ver profesionales.',
          align: TourTooltipAlign.below,
        ),
        GuidedTourStep(
          targetKey: _searchKey,
          title: 'Búsqueda rápida',
          description:
              'Si ya sabes qué necesitas, escribe aquí (por ejemplo "llave" o "luz") para filtrar los servicios.',
          align: TourTooltipAlign.below,
        ),
        GuidedTourStep(
          targetKey: _profileKey,
          title: 'Tu perfil',
          description:
              'Desde tu avatar revisas tus datos, foto y el historial de solicitudes que has hecho.',
          align: TourTooltipAlign.below,
        ),
        GuidedTourStep(
          targetKey: _settingsKey,
          title: 'Configuración',
          description:
              'Acá tienes las configuraciones: notificaciones, cuenta y preferencias de la app.',
          align: TourTooltipAlign.below,
        ),
      ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ServiceModel> get _filteredServices {
    if (_query.trim().isEmpty) return _allServices;
    final q = _query.toLowerCase();
    return _allServices.where((s) {
      final label = _ServiceCard.displayName(s).toLowerCase();
      return label.contains(q) ||
          s.name.toLowerCase().contains(q) ||
          (s.description ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final userName = user?.name.split(' ').first ?? 'Usuario';

    return DemoTourOverlay(
      steps: _homeTourSteps,
      child: Scaffold(
        body: AuthSoftBackground(
          showDecorations: false,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(
                  userName: user?.name ?? 'Usuario',
                  photoPath: user?.profilePhotoPath,
                  profileKey: _profileKey,
                  settingsKey: _settingsKey,
                  onProfile: () => context.push(AppConstants.routeUserProfile),
                  onSettings: () => context.push(AppConstants.routeSettings),
                ),
                Expanded(
                  child: FutureBuilder<List<ServiceModel>>(
                    future: _serviceRepository.getMainServices(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          _allServices.isEmpty) {
                        return const LoadingWidget();
                      }

                      if (snapshot.hasError) {
                        return ErrorDisplayWidget(
                          message: 'Error al cargar servicios: ${snapshot.error}',
                          onRetry: () => setState(() {}),
                        );
                      }

                      if (snapshot.hasData) {
                        _allServices = snapshot.data!;
                      }

                      final services = _filteredServices;
                      final crossCount = AppBreakpoints.gridColumns(
                        context,
                        phone: 2,
                        tablet: 3,
                        desktopCols: 4,
                      );

                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          AppBreakpoints.screenPadding(context) + 4,
                          2,
                          AppBreakpoints.screenPadding(context) + 4,
                          20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '¡Hola de nuevo, $userName!',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.grayDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '¿Qué necesitas hoy?',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.grayMedium.withValues(alpha: 0.95),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TourTarget(
                              tourKey: _searchKey,
                              width: double.infinity,
                              child: _SearchBar(
                                controller: _searchController,
                                onChanged: (value) => setState(() => _query = value),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TourTarget(
                              tourKey: _servicesKey,
                              width: double.infinity,
                              child: const Text(
                                'Servicios Disponibles',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.grayDark,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (services.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 48, bottom: 24),
                                child: Text(
                                  _query.isEmpty
                                      ? 'No hay servicios disponibles'
                                      : 'Sin resultados para "$_query"',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.grayMedium,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossCount,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio:
                                      AppBreakpoints.isTablet(context) ? 0.96 : 0.9,
                                ),
                                itemCount: services.length,
                                itemBuilder: (context, index) {
                                  final service = services[index];
                                  final card = _ServiceCard(
                                    service: service,
                                    compact: true,
                                    onRequest: () => context.push(
                                      AppConstants.routeWorkerList,
                                      extra: {'serviceId': service.id},
                                    ),
                                  );
                                  if (index == 0) {
                                    return TourTarget(
                                      tourKey: _firstServiceKey,
                                      child: card,
                                    );
                                  }
                                  return card;
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.userName,
    required this.photoPath,
    required this.profileKey,
    required this.settingsKey,
    required this.onProfile,
    required this.onSettings,
  });

  final String userName;
  final String? photoPath;
  final GlobalKey profileKey;
  final GlobalKey settingsKey;
  final VoidCallback onProfile;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          const AppBrandLogo(size: 32, textSize: 16),
          const Spacer(),
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                TourTarget(
                  tourKey: profileKey,
                  child: GestureDetector(
                    onTap: onProfile,
                    child: ProfileAvatarView(
                      displayName: userName,
                      photoPath: photoPath,
                      radius: 20,
                      onDarkBackground: false,
                    ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: TourTarget(
                    tourKey: settingsKey,
                    child: GestureDetector(
                      onTap: onSettings,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.brandOrange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.settings_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
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
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.grayMedium.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.grayDark,
        ),
        decoration: InputDecoration(
          hintText: "Buscar servicios (ej. 'llave')",
          hintStyle: TextStyle(
            fontSize: 12,
            color: AppColors.grayMedium.withValues(alpha: 0.85),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          suffixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.grayMedium.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.onRequest,
    this.compact = false,
  });

  final ServiceModel service;
  final VoidCallback onRequest;
  final bool compact;

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

  @override
  Widget build(BuildContext context) {
    final palette = ServiceCardPalette.forCategory(service.category);
    final label = displayName(service);
    final tagline = _taglineFor(service.category);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onRequest,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                palette.background,
              ],
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
          padding: EdgeInsets.all(compact ? 12 : 16),
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
                  border:
                      Border.all(color: palette.accent.withValues(alpha: 0.16)),
                ),
                child: Icon(
                  _iconFor(service.category),
                  size: compact ? 22 : 26,
                  color: palette.accent,
                ),
              ),
              const Spacer(),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 13 : 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grayDark,
                  letterSpacing: -0.2,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                tagline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 10.5 : 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grayMedium,
                  height: 1.15,
                ),
              ),
              SizedBox(height: compact ? 10 : 14),
              Row(
                children: [
                  Text(
                    'Solicitar',
                    style: TextStyle(
                      fontSize: compact ? 12 : 13,
                      fontWeight: FontWeight.w700,
                      color: palette.accent,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(width: 5),
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

  static String _taglineFor(String category) {
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

  static IconData _iconFor(String category) {
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

}
