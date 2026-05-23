import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/repositories/password_reset_repository.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/password_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/design_system/app_auth_scaffold.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final UserRepository _userRepository = UserRepository();
  final PasswordResetRepository _resetRepository = PasswordResetRepository();
  bool _isLoading = false;
  bool _codeSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await _userRepository.getUserByEmail(_emailController.text.trim());

      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No existe una cuenta con este email'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final code = PasswordUtils.generateResetCode();
      await _resetRepository.invalidateUserCodes(user.id);
      await _resetRepository.createResetCode(
        userId: user.id,
        email: user.email,
        code: code,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _codeSent = true;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Código de recuperación'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'En producción, este código se enviaría por email.\n\nCódigo para desarrollo:',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  code,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        letterSpacing: 8,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push(
                    AppConstants.routeResetPasswordCode,
                    extra: {'email': user.email},
                  );
                },
                child: const Text('Continuar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppAuthScaffold(
      title: '¿Olvidaste tu contraseña?',
      subtitle: 'Te enviaremos un código para recuperar el acceso',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_codeSent) ...[
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  hintText: 'Ingresa tu email',
                ),
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleReset,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enviar código'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
