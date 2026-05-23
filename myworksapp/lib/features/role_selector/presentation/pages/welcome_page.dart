import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/design_system/app_brand_logo.dart';
import '../../../../core/widgets/design_system/auth_soft_background.dart';
import '../../../../core/widgets/design_system/wave_bottom_clipper.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const AppBrandLogo(size: 52, textSize: 24),
              const SizedBox(height: 6),
              Text(
                'Soluciones Profesionales para tu Hogar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grayMedium,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
              _HeroImage(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Text(
                      '¡Bienvenido a myworksapp!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.grayDark,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Encuentra y contrata a los mejores profesionales para tu hogar de forma rápida y segura.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.grayMedium,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _ServiceCategoriesRow(),
                    const SizedBox(height: 28),
                    BrandPrimaryButton(
                      label: 'Comenzar Ahora',
                      onPressed: () => context.push(
                        AppConstants.routeLogin,
                        extra: {'role': AppConstants.roleUser},
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LoginLink(
                      onTap: () => context.push(AppConstants.routeLogin),
                    ),
                    const SizedBox(height: 24),
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

class _HeroImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return SizedBox(
      height: width * 0.52,
      width: width,
      child: ClipPath(
        clipper: WaveBottomClipper(),
        child: Image.asset(
          'assets/images/welcome_hero.jpg',
          fit: BoxFit.cover,
          width: width,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.brandBlueSoft,
            child: const Center(
              child: Icon(
                Icons.people_alt_rounded,
                size: 64,
                color: AppColors.brandNavy,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceCategoriesRow extends StatelessWidget {
  static const _items = [
    _ServiceItem(Icons.cleaning_services_outlined, 'Limpieza'),
    _ServiceItem(Icons.plumbing_outlined, 'Plomería'),
    _ServiceItem(Icons.bolt_outlined, 'Electricidad'),
    _ServiceItem(Icons.handyman_outlined, 'Hogar'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _items
          .map(
            (item) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: item,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ServiceItem extends StatelessWidget {
  const _ServiceItem(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.brandOrangeSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.brandOrange.withValues(alpha: 0.12),
            ),
          ),
          child: Icon(icon, color: AppColors.brandNavy, size: 26),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.grayDark,
          ),
        ),
      ],
    );
  }
}

class _LoginLink extends StatelessWidget {
  const _LoginLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            fontSize: 14,
            color: AppColors.grayMedium,
            fontWeight: FontWeight.w500,
          ),
          children: [
            const TextSpan(text: '¿Ya tienes cuenta? '),
            TextSpan(
              text: 'Inicia Sesión',
              style: TextStyle(
                color: AppColors.brandTeal,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
