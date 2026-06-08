import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/design_system/app_brand_logo.dart';
import '../../../../core/widgets/design_system/auth_soft_background.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthSoftBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppBreakpoints.screenPadding(context) + 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Center(child: AppBrandLogo(size: 56, textSize: 24)),
                const SizedBox(height: 8),
                Text(
                  'Soluciones profesionales para tu hogar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grayMedium.withValues(alpha: 0.95),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  '¡Bienvenido a ${AppConstants.appBrandDisplayName}!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
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
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.grayMedium.withValues(alpha: 0.95),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                const _WelcomeHeroCard(),
                const SizedBox(height: 28),
                const _ServiceCategoriesRow(),
                const SizedBox(height: 32),
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
                const SizedBox(height: 28),
                const AppBrandFooter(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ilustración principal con paleta blanco + naranjo (como login).
class _WelcomeHeroCard extends StatelessWidget {
  const _WelcomeHeroCard();

  @override
  Widget build(BuildContext context) {
    final height = AppBreakpoints.heroImageHeight(context).clamp(200.0, 340.0);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.brandOrange.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandOrange.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/welcome_hero.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFF8F3),
                      Color(0xFFFFF0E8),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.people_alt_rounded,
                    size: 72,
                    color: AppColors.brandOrange,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: 0.92),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCategoriesRow extends StatelessWidget {
  const _ServiceCategoriesRow();

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
              color: AppColors.brandOrange.withValues(alpha: 0.22),
            ),
          ),
          child: Icon(icon, color: AppColors.brandOrange, size: 26),
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
        text: const TextSpan(
          style: TextStyle(
            fontSize: 14,
            color: AppColors.grayMedium,
            fontWeight: FontWeight.w500,
          ),
          children: [
            TextSpan(text: '¿Ya tienes cuenta? '),
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
