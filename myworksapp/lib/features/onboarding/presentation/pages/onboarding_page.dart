import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/design_system/app_brand_logo.dart';
import '../../../../core/widgets/design_system/auth_soft_background.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _pages = const [
    _OnboardingItem(
      useBrandLogo: true,
      title: 'Bienvenido a My Works App',
      description:
          'Conectamos usuarios con profesionales de servicios de manera rápida y segura.',
    ),
    _OnboardingItem(
      icon: Icons.location_on_rounded,
      title: 'Ubicación automática',
      description:
          'Detectamos tu ubicación para facilitar la solicitud de servicios cerca de ti.',
    ),
    _OnboardingItem(
      icon: Icons.verified_user_rounded,
      title: 'Profesionales calificados',
      description:
          'Trabajadores evaluados y listos para ayudarte con confianza.',
    ),
    _OnboardingItem(
      icon: Icons.forum_rounded,
      title: 'Comunicación directa',
      description:
          'Chatea con el trabajador para coordinar cada detalle del servicio.',
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (!mounted) return;
    context.go(AppConstants.routeWelcome);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthSoftBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: const Text(
                      'Omitir',
                      style: TextStyle(
                        color: AppColors.brandOrange,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final item = _pages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (item.useBrandLogo)
                            const AppBrandLogo(size: 96, showText: false)
                          else
                            _OnboardingIcon(icon: item.icon!),
                          const SizedBox(height: 36),
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.grayDark,
                              height: 1.25,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            item.description,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: AppColors.grayMedium.withValues(alpha: 0.95),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppColors.brandOrange
                            : AppColors.grayMedium.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      TextButton(
                        onPressed: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        child: const Text(
                          'Anterior',
                          style: TextStyle(
                            color: AppColors.grayMedium,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 84),
                    Expanded(
                      child: BrandPrimaryButton(
                        label: _currentPage == _pages.length - 1
                            ? 'Comenzar'
                            : 'Siguiente',
                        onPressed: _currentPage == _pages.length - 1
                            ? _completeOnboarding
                            : () => _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icono de slide con paleta naranjo (como categorías de servicio en welcome).
class _OnboardingIcon extends StatelessWidget {
  const _OnboardingIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.brandOrangeSoft,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.brandOrange.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandOrange.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, size: 52, color: AppColors.brandOrange),
    );
  }
}

class _OnboardingItem {
  final IconData? icon;
  final bool useBrandLogo;
  final String title;
  final String description;

  const _OnboardingItem({
    this.icon,
    this.useBrandLogo = false,
    required this.title,
    required this.description,
  });
}
