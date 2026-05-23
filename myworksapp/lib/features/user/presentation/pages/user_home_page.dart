import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/models/service_model.dart';
import '../../../../core/database/repositories/service_repository.dart';
import '../../../../core/design_system/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
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
  List<ServiceModel> _allServices = [];
  String _query = '';

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
                        padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
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
                            _SearchBar(
                              controller: _searchController,
                              onChanged: (value) => setState(() => _query = value),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Servicios Disponibles',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.grayDark,
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
                                  return _ServiceCard(
                                    service: service,
                                    compact: true,
                                    onRequest: () => context.push(
                                      AppConstants.routeWorkerList,
                                      extra: {'serviceId': service.id},
                                    ),
                                  );
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
    required this.onProfile,
    required this.onSettings,
  });

  final String userName;
  final String? photoPath;
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
                GestureDetector(
                  onTap: onProfile,
                  child: ProfileAvatarView(
                    displayName: userName,
                    photoPath: photoPath,
                    radius: 20,
                    onDarkBackground: false,
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
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
    final palette = _paletteFor(service.category);
    final label = displayName(service);
    final iconSize = compact ? 28.0 : 36.0;
    final margin = compact ? 6.0 : 8.0;
    final btnHeight = compact ? 28.0 : 32.0;
    final labelSize = compact ? 10.5 : 12.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              margin: EdgeInsets.all(margin),
              decoration: BoxDecoration(
                color: palette.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    _iconFor(service.category),
                    size: iconSize,
                    color: palette.primary,
                  ),
                  if (palette.secondaryIcon != null && !compact)
                    Positioned(
                      right: 12,
                      bottom: 10,
                      child: Icon(
                        palette.secondaryIcon,
                        size: 18,
                        color: palette.secondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: margin),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: labelSize,
                fontWeight: FontWeight.w800,
                color: AppColors.grayDark,
                height: 1.15,
              ),
            ),
          ),
          SizedBox(height: compact ? 4 : 6),
          Padding(
            padding: EdgeInsets.fromLTRB(margin + 2, 0, margin + 2, margin),
            child: SizedBox(
              height: btnHeight,
              child: TextButton(
                onPressed: onRequest,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.brandBlueSoft,
                  foregroundColor: AppColors.brandNavy,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Solicitar'),
              ),
            ),
          ),
        ],
      ),
    );
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

  static _ServicePalette _paletteFor(String category) {
    switch (category) {
      case ServiceCategories.construction:
        return const _ServicePalette(
          background: Color(0xFFFFF8E7),
          primary: Color(0xFFF59E0B),
          secondary: Color(0xFF92400E),
          secondaryIcon: Icons.straighten_rounded,
        );
      case ServiceCategories.plumbing:
        return const _ServicePalette(
          background: Color(0xFFE8F6FF),
          primary: Color(0xFF0EA5E9),
          secondary: Color(0xFF0369A1),
          secondaryIcon: Icons.water_drop_outlined,
        );
      case ServiceCategories.electrical:
        return const _ServicePalette(
          background: Color(0xFFFFF7ED),
          primary: Color(0xFFF97316),
          secondary: Color(0xFFCA8A04),
          secondaryIcon: Icons.power_rounded,
        );
      case ServiceCategories.gardening:
        return const _ServicePalette(
          background: Color(0xFFECFDF5),
          primary: Color(0xFF22C55E),
          secondary: Color(0xFF15803D),
          secondaryIcon: Icons.eco_rounded,
        );
      case ServiceCategories.cleaning:
        return const _ServicePalette(
          background: Color(0xFFF0F9FF),
          primary: Color(0xFF38BDF8),
        );
      default:
        return const _ServicePalette(
          background: AppColors.brandOrangeSoft,
          primary: AppColors.brandNavy,
        );
    }
  }
}

class _ServicePalette {
  const _ServicePalette({
    required this.background,
    required this.primary,
    this.secondary,
    this.secondaryIcon,
  });

  final Color background;
  final Color primary;
  final Color? secondary;
  final IconData? secondaryIcon;
}
