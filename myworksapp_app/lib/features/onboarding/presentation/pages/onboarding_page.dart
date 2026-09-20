import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/design_system/app_brand_logo.dart';
import '../../../../core/widgets/design_system/auth_soft_background.dart';
import '../../../../core/widgets/design_system/premium_glyphs.dart';

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
      glyph: PremiumGlyphKind.location,
      title: 'Ubicación automática',
      description:
          'Detectamos tu ubicación para facilitar la solicitud de servicios cerca de ti.',
    ),
    _OnboardingItem(
      glyph: PremiumGlyphKind.verified,
      title: 'Profesionales calificados',
      description:
          'Trabajadores evaluados y listos para ayudarte con confianza.',
    ),
    _OnboardingItem(
      glyph: PremiumGlyphKind.chat,
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
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  0,
                ),
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
                    final bodyColor = AppColors.onCanvasMuted(
                      Theme.of(context).brightness,
                    );
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl - 4,
                        vertical: AppSpacing.md,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (item.useBrandLogo)
                            const AppBrandLogo(size: 96, showText: false)
                          else
                            _OnboardingIcon(kind: item.glyph!),
                          const SizedBox(height: 36),
                          Text(
                            item.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFF7F8FA),
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            item.description,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyLarge(color: bodyColor)
                                .copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
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
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl - 4,
                  0,
                  AppSpacing.xl - 4,
                  AppSpacing.xl - 4,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 88,
                      child: _currentPage > 0
                          ? TextButton(
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
                          : null,
                    ),
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
                    const SizedBox(width: 88),
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

class _OnboardingIcon extends StatelessWidget {
  const _OnboardingIcon({required this.kind});

  final PremiumGlyphKind kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: const Color(0xFFFF7A18),
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.center,
      child: PremiumGlyph(
        kind: kind,
        size: 46,
        color: const Color(0xFF00205B),
      ),
    );
  }
}

class _OnboardingItem {
  final PremiumGlyphKind? glyph;
  final bool useBrandLogo;
  final String title;
  final String description;

  const _OnboardingItem({
    this.glyph,
    this.useBrandLogo = false,
    required this.title,
    required this.description,
  });
}
