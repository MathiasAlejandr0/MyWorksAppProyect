import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/demo_credentials.dart';
import '../../../../core/database/repositories/worker_repository.dart';
import '../../../../core/domain/worker_login_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/worker_navigation.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/design_system/auth_soft_background.dart';
import '../providers/auth_provider.dart';

/// Login 1:1 con mockup-mobile-02-login.png
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
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final WorkerRepository _workerRepository = WorkerRepository();
  bool _obscurePassword = true;
  late String _selectedRole;
  List<WorkerLoginItem> _demoWorkers = [];
  WorkerLoginItem? _selectedWorker;
  bool _loadingWorkers = false;
  String? _workersError;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.role ?? AppConstants.roleUser;
    if (_selectedRole == AppConstants.roleWorker) {
      _loadDemoWorkers();
    }
    if (kDebugMode) {
      _applyDemoCredentials(_selectedRole);
    }
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  void _applyDemoCredentials(String role) {
    if (role == AppConstants.roleUser) {
      _emailController.text = DemoCredentials.userEmail;
      _passwordController.text = DemoCredentials.demoPassword;
    } else if (role == AppConstants.roleAdmin) {
      _emailController.text = DemoCredentials.adminEmail;
      _passwordController.text = DemoCredentials.demoPassword;
    } else if (role == AppConstants.roleWorker) {
      final worker = _selectedWorker;
      if (worker != null) {
        _emailController.text = worker.email;
        _passwordController.text = DemoCredentials.demoPassword;
      } else {
        _emailController.text = DemoCredentials.workerEmail;
        _passwordController.text = DemoCredentials.demoPassword;
      }
    }
  }

  void _onRoleChanged(String role) {
    setState(() => _selectedRole = role);
    if (role == AppConstants.roleWorker && _demoWorkers.isEmpty) {
      _loadDemoWorkers();
    }
    if (!kDebugMode) return;
    _applyDemoCredentials(role);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
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
      _navigateAfterLogin();
    } else {
      _showAuthError();
    }
  }

  void _navigateAfterLogin() {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    if (user.role == AppConstants.roleAdmin) {
      context.go(AppConstants.routeAdminDashboard);
    } else if (user.role == AppConstants.roleUser) {
      context.go(AppConstants.routeUserHome);
    } else {
      unawaited(goToWorkerEntryRoute(context, user.id));
    }
  }

  void _showAuthError() {
    final error = ref.read(authProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Error al iniciar sesión'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _loadDemoWorkers() async {
    setState(() {
      _loadingWorkers = true;
      _workersError = null;
    });
    try {
      final workers = await _workerRepository.getWorkersForLogin();
      if (!mounted) return;
      setState(() {
        _demoWorkers = workers;
        _selectedWorker = workers.isNotEmpty ? workers.first : null;
        _loadingWorkers = false;
        if (workers.isEmpty) {
          _workersError = 'No hay trabajadores demo disponibles';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingWorkers = false;
        _workersError =
            'No se pudieron cargar los trabajadores demo. Reintenta.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final brightness = Theme.of(context).brightness;
    final title = AppColors.onCanvas(brightness);
    final muted = AppColors.onCanvasMuted(brightness);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.user == null && next.user != null && !next.isLoading) {
        _navigateAfterLogin();
      }
    });

    return Scaffold(
      backgroundColor: AppDecorations.canvasOf(context),
      body: AuthSoftBackground(
        showDecorations: true,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: _LoginLogo()),
                  const SizedBox(height: 32),
                  Text(
                    'Iniciar sesión',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: title,
                      letterSpacing: -0.6,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Selecciona tu rol e inicia sesión para continuar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: muted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 26),
                  _RoleChips(
                    selected: _selectedRole,
                    onChanged: _onRoleChanged,
                  ),
                  const SizedBox(height: 22),
                  _AuthField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    hint: 'Correo electrónico',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                    emphasized: true,
                    focused: _emailFocus.hasFocus,
                  ),
                  const SizedBox(height: 12),
                  _AuthField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    hint: 'Contraseña',
                    icon: Icons.lock_outline_rounded,
                    obscure: _obscurePassword,
                    validator: Validators.validatePassword,
                    emphasized: false,
                    focused: _passwordFocus.hasFocus,
                    suffix: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.brandOrange,
                      ),
                    ),
                  ),
                  if (_selectedRole == AppConstants.roleWorker &&
                      kDebugMode) ...[
                    const SizedBox(height: 12),
                    _WorkerPicker(
                      workers: _demoWorkers,
                      selected: _selectedWorker,
                      loading: _loadingWorkers,
                      error: _workersError,
                      onRetry: _loadDemoWorkers,
                      onSelect: (w) {
                        setState(() {
                          _selectedWorker = w;
                          _emailController.text = w.email;
                          _passwordController.text =
                              DemoCredentials.demoPassword;
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: authState.isLoading ? null : _handleLogin,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandOrange,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor:
                            AppColors.brandOrange.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                      child: authState.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: AppColors.white,
                              ),
                            )
                          : const Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Entrar',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () =>
                        context.push(AppConstants.routeForgotPassword),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: muted,
                        ),
                        children: const [
                          TextSpan(text: '¿Olvidaste tu '),
                          TextSpan(
                            text: 'contraseña?',
                            style: TextStyle(
                              color: AppColors.brandOrange,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const _DemoHintCard(),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 13,
                        color: muted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Seguro',
                        style: TextStyle(
                          fontSize: 12,
                          color: muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '•',
                          style: TextStyle(
                            color: AppColors.brandOrange.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        'Confiable',
                        style: TextStyle(
                          fontSize: 12,
                          color: muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '•',
                          style: TextStyle(
                            color: AppColors.brandOrange.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        'Diseñado para equipos',
                        style: TextStyle(
                          fontSize: 12,
                          color: muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginLogo extends StatelessWidget {
  const _LoginLogo();

  @override
  Widget build(BuildContext context) {
    final title = AppColors.headlineOnScreen(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.brandOrange,
            boxShadow: [
              BoxShadow(
                color: AppColors.brandOrange.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.keyboard_arrow_up_rounded,
            color: AppColors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          AppConstants.appBrandDisplayName,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: title,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class _RoleChips extends StatelessWidget {
  const _RoleChips({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final inactiveFg = AppColors.onCanvasMuted(brightness);
    final roles = [
      (AppConstants.roleUser, 'Usuario', Icons.person_outline_rounded),
      (AppConstants.roleWorker, 'Trabajador', Icons.engineering_outlined),
      (AppConstants.roleAdmin, 'Admin', Icons.shield_outlined),
    ];

    return Row(
      children: [
        for (var i = 0; i < roles.length; i++) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(roles[i].$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected == roles[i].$1
                      ? AppColors.brandOrange
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected == roles[i].$1
                        ? AppColors.brandOrange
                        : AppColors.hairlineOf(context),
                    width: 1.2,
                  ),
                  boxShadow: selected == roles[i].$1
                      ? [
                          BoxShadow(
                            color:
                                AppColors.brandOrange.withValues(alpha: 0.28),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Icon(
                      roles[i].$3,
                      size: 22,
                      color: selected == roles[i].$1
                          ? AppColors.white
                          : inactiveFg,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      roles[i].$2,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: selected == roles[i].$1
                            ? AppColors.white
                            : inactiveFg,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (i < roles.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.focusNode,
    this.keyboardType,
    this.obscure = false,
    this.validator,
    this.suffix,
    this.focused = false,
    this.emphasized = false,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final bool obscure;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final bool focused;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final textColor = AppColors.onCanvas(brightness);
    final hintColor = AppColors.onCanvasMuted(brightness);
    final idleBorder = emphasized
        ? AppColors.brandOrange.withValues(alpha: 0.85)
        : AppColors.hairlineOf(context);
    const activeBorder = AppColors.brandOrange;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
      cursorColor: AppColors.brandOrange,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: hintColor,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AppColors.fieldFillOf(context),
        prefixIcon: Icon(icon, color: AppColors.brandOrange, size: 22),
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: focused ? activeBorder : idleBorder,
            width: focused || emphasized ? 1.5 : 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.brandOrange,
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.6),
        ),
      ),
    );
  }
}

class _DemoHintCard extends StatelessWidget {
  const _DemoHintCard();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.fieldFillOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairlineOf(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.brandOrange,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Demo',
                  style: TextStyle(
                    color: AppColors.onCanvas(brightness),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Usa las credenciales de demostración para explorar la app.',
                  style: TextStyle(
                    color: AppColors.onCanvasMuted(brightness),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkerPicker extends StatelessWidget {
  const _WorkerPicker({
    required this.workers,
    required this.selected,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onSelect,
  });

  final List<WorkerLoginItem> workers;
  final WorkerLoginItem? selected;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<WorkerLoginItem> onSelect;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(color: AppColors.brandOrange),
        ),
      );
    }
    if (error != null) {
      return TextButton(
        onPressed: onRetry,
        child: Text(error!, style: const TextStyle(color: AppColors.error)),
      );
    }
    if (workers.isEmpty) return const SizedBox.shrink();

    final brightness = Theme.of(context).brightness;
    final textColor = AppColors.onCanvas(brightness);

    return DropdownButtonFormField<String>(
      initialValue: selected?.userId,
      dropdownColor: AppColors.surfaceElevatedOf(context),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.fieldFillOf(context),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.brandOrange.withValues(alpha: 0.55),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.brandOrange, width: 1.6),
        ),
      ),
      items: workers
          .map(
            (w) => DropdownMenuItem(
              value: w.userId,
              child: Text(
                '${w.name} · ${w.profession}',
                style: TextStyle(color: textColor, fontSize: 13),
              ),
            ),
          )
          .toList(),
      onChanged: (id) {
        if (id == null) return;
        onSelect(workers.firstWhere((w) => w.userId == id));
      },
    );
  }
}
