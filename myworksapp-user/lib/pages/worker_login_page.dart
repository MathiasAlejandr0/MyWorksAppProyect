import 'package:flutter/material.dart';
import '../services/worker_security_service.dart';
import '../database/worker_database_helper.dart';
import '../utils/app_colors.dart';

class WorkerLoginPage extends StatefulWidget {
  const WorkerLoginPage({super.key});

  @override
  State<WorkerLoginPage> createState() => _WorkerLoginPageState();
}

class _WorkerLoginPageState extends State<WorkerLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _securityService = WorkerSecurityService();
  final _databaseHelper = WorkerDatabaseHelper();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Buscar trabajador por email
      final worker =
          await _databaseHelper.getWorkerByEmail(_emailController.text.trim());

      if (worker == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email no registrado'),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
        return;
      }

      // Verificar contraseña
      if (!_securityService.verifyPassword(
          _passwordController.text, worker.password)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contraseña incorrecta'),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
        return;
      }

      // Guardar sesión
      await _securityService.saveWorkerSession(worker);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inicio de sesión exitoso'),
            backgroundColor: AppColors.successColor,
          ),
        );

        // Navegar a la página principal
        Navigator.of(context).pushReplacementNamed('/worker_home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar sesión: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo y título
                  _buildHeader(),
                  const SizedBox(height: 48),

                  // Formulario de login
                  _buildLoginForm(),
                  const SizedBox(height: 24),

                  // Botón de login
                  _buildLoginButton(),
                  const SizedBox(height: 16),

                  // Enlaces adicionales
                  _buildAdditionalLinks(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(60),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.work,
            size: 60,
            color: AppColors.textOnPrimaryColor,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'My Worker App',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Inicia sesión en tu cuenta',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El email es requerido';
                }
                if (!_securityService.isValidEmail(value)) {
                  return 'El email no es válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La contraseña es requerida';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _login,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textOnPrimaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Iniciar Sesión',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildAdditionalLinks() {
    return Column(
      children: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pushNamed('/worker_register');
          },
          child: const Text(
            '¿No tienes cuenta? Regístrate',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            _showPasswordRecoveryDialog();
          },
          child: const Text(
            '¿Olvidaste tu contraseña?',
            style: TextStyle(
              color: AppColors.textSecondaryColor,
            ),
          ),
        ),
      ],
    );
  }

  void _showPasswordRecoveryDialog() {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Recuperar Contraseña'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Ingresa tu email para recuperar tu contraseña',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El email es requerido';
                        }
                        if (!_securityService.isValidEmail(value)) {
                          return 'El email no es válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: newPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Nueva Contraseña',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNewPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              obscureNewPassword = !obscureNewPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: obscureNewPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La contraseña es requerida';
                        }
                        if (value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirmar Contraseña',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              obscureConfirmPassword = !obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: obscureConfirmPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirma la contraseña';
                        }
                        if (value != newPasswordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (emailController.text.trim().isEmpty ||
                              newPasswordController.text.isEmpty ||
                              confirmPasswordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Por favor completa todos los campos'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (newPasswordController.text !=
                              confirmPasswordController.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Las contraseñas no coinciden'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setState(() {
                            isLoading = true;
                          });

                          try {
                            // Verificar si el trabajador existe
                            final worker = await _databaseHelper
                                .getWorkerByEmail(emailController.text.trim());

                            if (worker == null) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'No se encontró una cuenta con este email'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              setState(() {
                                isLoading = false;
                              });
                              return;
                            }

                            // Actualizar la contraseña
                            final updatedWorker = worker.copyWith(
                              password: _securityService
                                  .hashPassword(newPasswordController.text),
                            );

                            await _databaseHelper.updateWorker(updatedWorker);

                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Contraseña actualizada exitosamente'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Error al actualizar la contraseña: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Recuperar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
