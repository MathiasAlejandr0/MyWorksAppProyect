import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/models/service_model.dart';
import '../../../../core/database/repositories/service_repository.dart';
import '../../../../core/design_system/app_breakpoints.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/widgets/design_system/service_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/app_guided_tour.dart';
import '../../../../core/widgets/demo_tour_overlay.dart';
import '../../../../core/services/app_feedback.dart';
import '../../../../core/widgets/design_system/empty_state_widget.dart';
import '../../../../core/widgets/design_system/loading_skeleton.dart';
import '../../../../core/widgets/design_system/myworks_guarantee_badge.dart';
import '../../../../core/widgets/design_system/app_brand_logo.dart';
import '../../../../core/widgets/design_system/auth_soft_background.dart';
import '../../../../core/widgets/design_system/error_state_widget.dart';
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
  late Future<List<ServiceModel>> _servicesFuture;

  @override
  void initState() {
    super.initState();
    _servicesFuture = _serviceRepository.getMainServices();
  }

  List<GuidedTourStep> get _homeTourSteps => [
        const GuidedTourStep(
          title: 'Bienvenido a MyWorks',
          description:
              'Te mostraremos cómo pedir un servicio paso a paso. Puedes omitir la guía en cualquier momento.',
          align: TourTooltipAlign.center,
        ),
        GuidedTourStep(
          targetKey:
              _filteredServices.isNotEmpty ? _firstServiceKey : _servicesKey,
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
      final label = ServiceCard.displayName(s).toLowerCase();
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
    final brightness = Theme.of(context).brightness;
    final titleColor = AppColors.onCanvas(brightness);
    final mutedColor = AppColors.onCanvasMuted(brightness);
    final isAdmin = user?.role == AppConstants.roleAdmin;

    return DemoTourOverlay(
      steps: _homeTourSteps,
      child: Scaffold(
          backgroundColor: AppDecorations.canvasOf(context),
          bottomNavigationBar: _UserBottomNav(
            onProjects: () => context.push(AppConstants.routeJobHistory),
            onMessages: () => context.push(AppConstants.routeNotifications),
            onProfile: () => context.push(AppConstants.routeUserProfile),
          ),
          body: AuthSoftBackground(
            showDecorations: true,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(
                    userName: user?.name ?? 'Usuario',
                    photoPath: user?.profilePhotoPath,
                    profileKey: _profileKey,
                    settingsKey: _settingsKey,
                    onProfile: () =>
                        context.push(AppConstants.routeUserProfile),
                    onSettings: () => context.push(AppConstants.routeSettings),
                  ),
                  Expanded(
                    child: FutureBuilder<List<ServiceModel>>(
                      future: _servicesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            _allServices.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              children: [
                                ListItemSkeleton(),
                                ListItemSkeleton(),
                                ListItemSkeleton(),
                                ListItemSkeleton(),
                              ],
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return ErrorStateWidget(
                            title: 'No se pudieron cargar los servicios',
                            message: '${snapshot.error}',
                            actionLabel: 'Reintentar',
                            onRetry: () => setState(() {
                              _servicesFuture =
                                  _serviceRepository.getMainServices();
                            }),
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
                            6,
                            AppBreakpoints.screenPadding(context) + 4,
                            20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '¡Hola de nuevo, $userName!',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                  height: 1.15,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '¿Qué necesitas hoy?',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: mutedColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TourTarget(
                                tourKey: _searchKey,
                                width: double.infinity,
                                child: _SearchBar(
                                  controller: _searchController,
                                  onChanged: (value) =>
                                      setState(() => _query = value),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const HowItWorksCard(),
                              if (isAdmin) ...[
                                const SizedBox(height: 12),
                                _AdminConsoleTile(
                                  onTap: () => context.push(
                                    AppConstants.routeAdminDesktopHub,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 22),
                              TourTarget(
                                tourKey: _servicesKey,
                                width: double.infinity,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            AppColors.brandOrangeVibrant,
                                            AppColors.brandOrange,
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Servicios disponibles',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.2,
                                        color: titleColor,
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () {},
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.brandOrange,
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Ver todos ›',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (services.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 32,
                                    bottom: 24,
                                  ),
                                  child: EmptyStateWidget(
                                    icon: Icons.search_off_rounded,
                                    title: _query.isEmpty
                                        ? 'Aún no hay servicios'
                                        : 'Sin resultados',
                                    message: _query.isEmpty
                                        ? 'Vuelve a intentar en un momento.'
                                        : 'Prueba con otra palabra o elige una categoría.',
                                  ),
                                )
                              else
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossCount,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio:
                                        AppBreakpoints.isTablet(context)
                                            ? 0.92
                                            : 0.84,
                                  ),
                                  itemCount: services.length,
                                  itemBuilder: (context, index) {
                                    final service = services[index];
                                    final card = ServiceCard.fromService(
                                      service: service,
                                      compact: true,
                                      onTap: () {
                                        AppFeedback.light();
                                        context.push(
                                          AppConstants.routeWorkerList,
                                          extra: {'serviceId': service.id},
                                        );
                                      },
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
                              const SizedBox(height: 16),
                              const MyWorksGuaranteeBadge(),
                              const SizedBox(height: 24),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        4,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppBrandLogo(
                horizontal: true,
                size: 34,
                textSize: 15,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                TourTarget(
                  tourKey: profileKey,
                  child: GestureDetector(
                    onTap: onProfile,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.hairlineOf(context),
                          width: 2,
                        ),
                        boxShadow: isDark
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: ProfileAvatarView(
                        displayName: userName,
                        photoPath: photoPath,
                        radius: 20,
                        onDarkBackground: isDark,
                      ),
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
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.brandOrangeVibrant,
                              AppColors.brandOrange,
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppDecorations.canvasOf(context),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.brandOrange.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppColors.headlineOnScreen(context);
    final muted = AppColors.onCanvasMuted(Theme.of(context).brightness);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.fieldFillOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.hairlineOf(context, accent: AppColors.brandOrange),
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : AppDecorations.appleCardShadow(isDark: false),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        cursorColor: AppColors.brandOrange,
        decoration: InputDecoration(
          hintText: 'Buscar servicios...',
          hintStyle: TextStyle(
            fontSize: 13,
            color: muted.withValues(alpha: 0.75),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.brandOrange.withValues(alpha: 0.95),
          ),
        ),
      ),
    );
  }
}

class _AdminConsoleTile extends StatelessWidget {
  const _AdminConsoleTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final titleColor = AppColors.onCanvas(brightness);
    final muted = AppColors.onCanvasMuted(brightness);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: AppDecorations.surfaceCardOf(
            context,
            accent: AppColors.brandOrange,
            radius: AppRadius.lg,
            overrideColor: AppColors.surfaceElevatedOf(context),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.brandOrange.withValues(alpha: 0.18),
                      AppColors.brandOrange.withValues(alpha: 0.08),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.desktop_windows_rounded,
                  color: AppColors.brandOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consola de administración',
                      style: TextStyle(
                        color: titleColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Gestión de trabajos, usuarios y soporte',
                      style: TextStyle(
                        color: muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: muted,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserBottomNav extends StatelessWidget {
  const _UserBottomNav({
    required this.onProjects,
    required this.onMessages,
    required this.onProfile,
  });

  final VoidCallback onProjects;
  final VoidCallback onMessages;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = AppColors.onCanvasMuted(Theme.of(context).brightness);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        border: Border(
          top: BorderSide(
            color: AppColors.hairlineOf(context),
          ),
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ]
            : null,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Inicio',
                active: true,
                muted: muted,
              ),
              _NavItem(
                icon: Icons.folder_outlined,
                label: 'Mis Proyectos',
                active: false,
                muted: muted,
                onTap: onProjects,
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Mensajes',
                active: false,
                muted: muted,
                onTap: onMessages,
                showDot: true,
              ),
              _NavItem(
                icon: Icons.favorite_border_rounded,
                label: 'Favoritos',
                active: false,
                muted: muted,
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Perfil',
                active: false,
                muted: muted,
                onTap: onProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.muted,
    this.onTap,
    this.showDot = false,
  });

  final IconData icon;
  final String label;
  final bool active;
  final Color muted;
  final VoidCallback? onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.brandOrange : muted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 22, color: color),
                  if (showDot)
                    Positioned(
                      right: -2,
                      top: -1,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.brandOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
