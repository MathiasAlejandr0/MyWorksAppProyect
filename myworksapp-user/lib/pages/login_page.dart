import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../database/database_helper.dart';
import '../services/security_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Buscar usuario en la base de datos
        final user = await _dbHelper.getUserByEmail(
          _emailController.text.trim(),
        );

        if (user != null) {
          // Para usuarios de prueba, usar contraseña simple
          // En un caso real, la contraseña estaría hasheada en la base de datos
          if (_passwordController.text == '123456') {
            // Generar token de sesión
            final token = SecurityService.generateSessionToken(user.id);

            // Guardar datos de sesión
            await SecurityService.saveAuthToken(token);
            await SecurityService.saveUserId(user.id);
            await SecurityService.saveUserData({
              'id': user.id,
              'name': user.name,
              'email': user.email,
              'phone': user.phone,
            });

            // Actualizar último login en la base de datos
            final db = await _dbHelper.database;
            await db.update(
              'users',
              {'lastLogin': DateTime.now().toIso8601String()},
              where: 'id = ?',
              whereArgs: [user.id],
            );

            if (mounted) {
              setState(() {
                _isLoading = false;
              });

              // Navegar al home
              Navigator.pushReplacementNamed(context, '/home');
            }
          } else {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Contraseña incorrecta. Usa 123456 para usuarios de prueba.',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Usuario no encontrado. Usa juan@test.com, maria@test.com o carlos@test.com',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al iniciar sesión: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo y título
                const Icon(
                  Icons.home_repair_service,
                  size: 80,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(height: 16),
                const Text(
                  'MyWorksApp',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Servicios al hogar',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 48),

                // Campo de email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu email';
                    }
                    if (!SecurityService.isValidEmail(value)) {
                      return 'Por favor ingresa un email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo de contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Botón de login
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Iniciar Sesión',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Enlace para registro
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '¿No tienes cuenta? ',
                      style: TextStyle(color: AppColors.textSecondaryColor),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: const Text('Regístrate'),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Información de prueba
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(0, 122, 255, 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color.fromRGBO(0, 122, 255, 0.3)),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'Datos de prueba:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Email: usuario@ejemplo.com',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Contraseña: 123456',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
