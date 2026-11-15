import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/user_role.dart';
import '../../../../core/services/gdpr_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/utils/role_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/worker_navigation.dart';
import '../../../../core/widgets/design_system/app_auth_scaffold.dart';
import '../../../gdpr/presentation/widgets/consent_checkbox.dart';
import '../providers/auth_provider.dart';
import '../widgets/password_strength_meter.dart';
import '../widgets/role_selector_chips.dart';

class RegisterPage extends ConsumerStatefulWidget {
  final String? role;

  const RegisterPage({super.key, this.role});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _consentAccepted = false;
  late UserRole _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = UserRole.sanitizeForRegistration(
      UserRole.fromDb(widget.role),
    );
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() => setState(() {});

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return Validators.validateSecurePassword(value);
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_consentAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes aceptar los términos y condiciones para continuar',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final authNotifier = ref.read(authProvider.notifier);
    final success = await authNotifier.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole.dbValue,
    );

    if (!mounted) return;

    if (success) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        try {
          await GdprService.instance.recordConsent(
            userId: user.id,
            accepted: true,
          );
        } catch (e) {
          if (!mounted) return;
          ErrorHandler.showError(context, e);
        }

        if (!mounted) return;
        if (user.userRole.isEspecialista) {
          await goToWorkerEntryRoute(context, user.id);
        } else {
          context.go(homeRouteForRole(user.userRole));
        }
      }
    } else {
      final error = ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Error al registrar usuario'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return AppAuthScaffold(
      badge: _selectedRole.label,
      title: 'Crea tu cuenta',
      subtitle: _selectedRole.description,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¿Cómo quieres usar My Works App?',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            RoleSelectorChips(
              selected: _selectedRole,
              onChanged: (role) => setState(() => _selectedRole = role),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: Validators.validateName,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: Validators.validateSecurePassword,
            ),
            PasswordStrengthMeter(value: _passwordController.text),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleRegister(),
              decoration: InputDecoration(
                labelText: 'Confirmar contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                ),
              ),
              validator: _validateConfirmPassword,
            ),
            const SizedBox(height: 18),
            ConsentCheckbox(
              value: _consentAccepted,
              onChanged: (value) => setState(() => _consentAccepted = value),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: authState.isLoading ? null : _handleRegister,
              child: authState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Registrarse'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.push(
                AppConstants.routeLogin,
                extra: {'role': _selectedRole.dbValue},
              ),
              child: const Text('¿Ya tienes cuenta? Inicia sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
