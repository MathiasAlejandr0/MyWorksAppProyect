import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_decorations.dart';

/// Layout para pantallas de autenticación (login, registro, recuperar clave).
class AppAuthScaffold extends StatelessWidget {
  const AppAuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.badge,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDecorations.screenBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
              decoration: BoxDecoration(
                gradient: AppDecorations.headerGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppDecorations.headerShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primaryLight.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        badge!.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
