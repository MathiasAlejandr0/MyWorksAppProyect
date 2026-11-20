import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/oauth_config.dart';
import '../../../../core/database/supabase_db.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/design_system/app_auth_scaffold.dart';

typedef PasswordResetSender = Future<void> Function(
  String email, {
  required String redirectTo,
});

/// Pide el correo de recuperación y vuelve a la app (`cl.myworksapp.auth://login-callback`).
Future<void> sendPasswordResetEmail(
  String email, {
  PasswordResetSender? sender,
}) {
  final redirectTo = OAuthConfig.redirectUrl;
  final send = sender ?? _supabasePasswordReset;
  return send(email.trim().toLowerCase(), redirectTo: redirectTo);
}

Future<void> _supabasePasswordReset(
  String email, {
  required String redirectTo,
}) {
  return supabase.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
}

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key, this.sendReset});

  final Future<void> Function(String email)? sendReset;

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final send = widget.sendReset ?? sendPasswordResetEmail;
      await send(_emailController.text);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorHandler.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppAuthScaffold(
      title: '¿Olvidaste tu contraseña?',
      subtitle: _emailSent
          ? 'Revisa tu bandeja de entrada y sigue el enlace para crear una nueva contraseña.'
          : 'Te enviaremos un enlace de recuperación a tu correo',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_emailSent) ...[
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
                    : const Text('Enviar enlace'),
              ),
            ] else ...[
              const Icon(
                Icons.mark_email_read_outlined,
                size: 64,
                color: AppColors.success,
              ),
              const SizedBox(height: 16),
              const Text(
                'Si el correo está registrado, recibirás instrucciones en unos minutos.',
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
