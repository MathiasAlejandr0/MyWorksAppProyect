import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/gdpr_service.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/design_system/app_auth_scaffold.dart';
import '../../../gdpr/presentation/widgets/consent_checkbox.dart';
import '../providers/auth_provider.dart';

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

  @override
  void dispose() {
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
    return Validators.validatePassword(value);
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_consentAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los términos y condiciones para continuar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final role = widget.role ?? AppConstants.roleUser;
    final authNotifier = ref.read(authProvider.notifier);
    final success = await authNotifier.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: role,
    );

    if (!mounted) return;

    if (success) {
      final authState = ref.read(authProvider);
      final user = authState.user;

      if (user != null) {
        try {
          await GdprService.instance.recordConsent(
            userId: user.id,
            accepted: true,
          );
        } catch (e) {
          ErrorHandler.showError(context, e);
        }

        if (user.role == AppConstants.roleUser) {
          context.go(AppConstants.routeUserHome);
        } else {
          context.go(AppConstants.routeWorkerRegister);
        }
      }
    } else {
      final authState = ref.read(authProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.error ?? 'Error al registrar usuario'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final role = widget.role ?? AppConstants.roleUser;
    final roleText = role == AppConstants.roleWorker ? 'Trabajador' : 'Usuario';

    return AppAuthScaffold(
      badge: roleText,
      title: 'Crea tu cuenta',
      subtitle: 'Completa tus datos para comenzar',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
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
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: Validators.validatePassword,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirmar contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
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
                extra: {'role': widget.role},
              ),
              child: const Text('¿Ya tienes cuenta? Inicia sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
