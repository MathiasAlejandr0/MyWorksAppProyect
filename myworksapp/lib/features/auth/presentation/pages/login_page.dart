import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/demo_credentials.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/design_system/app_brand_logo.dart';
import '../../../../core/widgets/design_system/auth_soft_background.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  final String? role;

  const LoginPage({super.key, this.role});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.role ?? AppConstants.roleUser;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    await _loginWithCredentials(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  Future<void> _loginWithCredentials(String email, String password) async {
    final authNotifier = ref.read(authProvider.notifier);
    final success = await authNotifier.login(email: email, password: password);

    if (!mounted) return;

    if (success) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        if (user.role == AppConstants.roleUser) {
          context.go(AppConstants.routeUserHome);
        } else {
          context.go(AppConstants.routeWorkerHome);
        }
      }
    } else {
      final error = ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Error al iniciar sesión'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _loginWithDemoAccount() async {
    final isWorker = _selectedRole == AppConstants.roleWorker;
    _emailController.text =
        isWorker ? DemoCredentials.workerEmail : DemoCredentials.userEmail;
    _passwordController.text = DemoCredentials.demoPassword;
    await _loginWithCredentials(_emailController.text, _passwordController.text);
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.grayMedium.withValues(alpha: 0.8)),
      prefixIcon: Icon(icon, color: AppColors.grayMedium, size: 22),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.grayMedium.withValues(alpha: 0.35)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.grayMedium.withValues(alpha: 0.35)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.brandTeal, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: AuthSoftBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go(AppConstants.routeWelcome),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.brandNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Inicia Sesión',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.grayDark,
                    ),
                  ),
                  const SizedBox(height: 28),
                  BrandLabeledField(
                    label: 'Correo electrónico',
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _fieldDecoration(
                        hint: 'Introduce tu correo',
                        icon: Icons.person_outline_rounded,
                      ),
                      validator: Validators.validateEmail,
                    ),
                  ),
                  const SizedBox(height: 18),
                  BrandLabeledField(
                    label: 'Contraseña',
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _fieldDecoration(
                        hint: 'Introduce tu contraseña',
                        icon: Icons.lock_outline_rounded,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.grayMedium,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: Validators.validatePassword,
                    ),
                  ),
                  const SizedBox(height: 24),
                  BrandPrimaryButton(
                    label: 'Entrar',
                    isLoading: authState.isLoading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => context.push(AppConstants.routeForgotPassword),
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(
                        color: AppColors.brandTeal,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'O entra como:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grayDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _RoleSelector(
                    selectedRole: _selectedRole,
                    onRoleChanged: (role) {
                      setState(() => _selectedRole = role);
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: authState.isLoading ? null : _loginWithDemoAccount,
                    icon: const Icon(Icons.play_circle_outline, size: 20),
                    label: Text(
                      _selectedRole == AppConstants.roleWorker
                          ? 'Cuenta demo trabajador'
                          : 'Cuenta demo usuario',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandNavy,
                      side: BorderSide(
                        color: AppColors.brandNavy.withValues(alpha: 0.25),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => context.push(
                      AppConstants.routeRegister,
                      extra: {'role': _selectedRole},
                    ),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grayMedium,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(text: 'Si aún no tienes cuenta, '),
                          TextSpan(
                            text: '¡Regístrate aquí!',
                            style: TextStyle(
                              color: AppColors.brandTeal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const AppBrandFooter(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({
    required this.selectedRole,
    required this.onRoleChanged,
  });

  final String selectedRole;
  final ValueChanged<String> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    final isUser = selectedRole == AppConstants.roleUser;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.grayMedium.withValues(alpha: 0.3),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _RoleOption(
                label: 'Como Usuario',
                icon: Icons.person_outline_rounded,
                selected: isUser,
                selectedColor: AppColors.brandBlueSoft,
                onTap: () => onRoleChanged(AppConstants.roleUser),
              ),
            ),
            VerticalDivider(
              width: 1,
              color: AppColors.grayMedium.withValues(alpha: 0.25),
            ),
            Expanded(
              child: _RoleOption(
                label: 'Como Trabajador',
                icon: Icons.engineering_outlined,
                selected: !isUser,
                selectedColor: AppColors.brandOrangeSoft,
                onTap: () => onRoleChanged(AppConstants.roleWorker),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? selectedColor : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: selected ? AppColors.brandNavy : AppColors.grayMedium,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.brandNavy : AppColors.grayMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
