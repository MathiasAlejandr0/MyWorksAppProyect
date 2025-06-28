import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/worker.dart';
import '../database/worker_database_helper.dart';
import '../services/worker_security_service.dart';
import '../utils/app_colors.dart';

class WorkerRegisterPage extends StatefulWidget {
  const WorkerRegisterPage({super.key});

  @override
  State<WorkerRegisterPage> createState() => _WorkerRegisterPageState();
}

class _WorkerRegisterPageState extends State<WorkerRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _databaseHelper = WorkerDatabaseHelper();
  final _securityService = WorkerSecurityService();

  // Controladores de texto
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _titleController = TextEditingController();
  final _titleInstitutionController = TextEditingController();
  final _titleYearController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _hourlyRateController = TextEditingController();

  // Variables de estado
  String _selectedProfession = 'Plomero';
  bool _hasTitle = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Imágenes
  File? _profileImage;
  List<File> _workImages = [];
  List<File> _certificateFiles = [];

  // Lista de profesiones
  final List<String> _professions = [
    'Plomero',
    'Electricista',
    'Albañil',
    'Jardinero',
    'Cerrajero',
    'Pintor',
    'Carpintero',
    'Técnico',
    'Limpieza',
    'Otros',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _titleController.dispose();
    _titleInstitutionController.dispose();
    _titleYearController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  // Seleccionar imagen de perfil
  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  // Seleccionar imágenes de trabajos
  Future<void> _pickWorkImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (images.isNotEmpty) {
      setState(() {
        _workImages.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  // Seleccionar certificados
  Future<void> _pickCertificates() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _certificateFiles.addAll(
          result.paths.map((path) => File(path!)).toList(),
        );
      });
    }
  }

  // Eliminar imagen de trabajo
  void _removeWorkImage(int index) {
    setState(() {
      _workImages.removeAt(index);
    });
  }

  // Eliminar certificado
  void _removeCertificate(int index) {
    setState(() {
      _certificateFiles.removeAt(index);
    });
  }

  // Registrar trabajador
  Future<void> _registerWorker() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Validar contraseñas
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Las contraseñas no coinciden'),
            backgroundColor: AppColors.errorColor,
          ),
        );
        return;
      }

      // Verificar si el email ya existe
      final existingWorker =
          await _databaseHelper.getWorkerByEmail(_emailController.text);
      if (existingWorker != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El email ya está registrado'),
            backgroundColor: AppColors.errorColor,
          ),
        );
        return;
      }

      // Crear trabajador
      final worker = Worker(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _securityService.hashPassword(_passwordController.text),
        profession: _selectedProfession,
        title: _hasTitle ? _titleController.text.trim() : null,
        titleInstitution:
            _hasTitle ? _titleInstitutionController.text.trim() : null,
        titleYear: _hasTitle ? int.parse(_titleYearController.text) : null,
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        hourlyRate: _hourlyRateController.text.isNotEmpty
            ? double.parse(_hourlyRateController.text)
            : null,
        profileImage: _profileImage?.path,
        workImages: _workImages.map((file) => file.path).toList(),
        certificates: _certificateFiles.map((file) => file.path).toList(),
        createdAt: DateTime.now(),
        isAvailable:
            false, // Por defecto no disponible hasta que complete el perfil
      );

      // Guardar en base de datos
      final workerId = await _databaseHelper.insertWorker(worker);

      if (workerId > 0) {
        // Guardar sesión
        final savedWorker = worker.copyWith(id: workerId);
        await _securityService.saveWorkerSession(savedWorker);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registro exitoso'),
              backgroundColor: AppColors.successColor,
            ),
          );

          // Navegar a la página principal
          Navigator.of(context).pushReplacementNamed('/worker_home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar: $e'),
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
      appBar: AppBar(
        title: const Text('Registro de Trabajador'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textOnPrimaryColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Imagen de perfil
                    _buildProfileImageSection(),
                    const SizedBox(height: 24),

                    // Información personal
                    _buildPersonalInfoSection(),
                    const SizedBox(height: 24),

                    // Información profesional
                    _buildProfessionalInfoSection(),
                    const SizedBox(height: 24),

                    // Título profesional
                    _buildTitleSection(),
                    const SizedBox(height: 24),

                    // Imágenes de trabajos
                    _buildWorkImagesSection(),
                    const SizedBox(height: 24),

                    // Certificados
                    _buildCertificatesSection(),
                    const SizedBox(height: 24),

                    // Botón de registro
                    _buildRegisterButton(),
                    const SizedBox(height: 16),

                    // Enlace para iniciar sesión
                    _buildLoginLink(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Foto de Perfil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickProfileImage,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryLightColor,
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(
                    color: AppColors.primaryColor,
                    width: 2,
                  ),
                ),
                child: _profileImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(58),
                        child: Image.file(
                          _profileImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.person_add,
                        size: 50,
                        color: AppColors.primaryColor,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _pickProfileImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Seleccionar Foto'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Personal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es requerido';
                }
                if (value.trim().length < 2) {
                  return 'El nombre debe tener al menos 2 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
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
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Teléfono *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El teléfono es requerido';
                }
                if (!_securityService.isValidPhone(value)) {
                  return 'El teléfono no es válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Contraseña *',
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
                if (!_securityService.isValidPassword(value)) {
                  return 'La contraseña debe tener al menos 8 caracteres, una letra y un número';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirmar Contraseña *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              obscureText: _obscureConfirmPassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirma tu contraseña';
                }
                if (value != _passwordController.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Profesional',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedProfession,
              decoration: const InputDecoration(
                labelText: 'Profesión *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work),
              ),
              items: _professions.map((String profession) {
                return DropdownMenuItem<String>(
                  value: profession,
                  child: Text(profession),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedProfession = newValue!;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Selecciona una profesión';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción de servicios',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Dirección',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hourlyRateController,
              decoration: const InputDecoration(
                labelText: 'Tarifa por hora (\$)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final rate = double.tryParse(value);
                  if (rate == null || rate <= 0) {
                    return 'La tarifa debe ser un número mayor a 0';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Título Profesional',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Switch(
                  value: _hasTitle,
                  onChanged: (value) {
                    setState(() {
                      _hasTitle = value;
                    });
                  },
                  activeColor: AppColors.primaryColor,
                ),
              ],
            ),
            if (_hasTitle) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
                validator: (value) {
                  if (_hasTitle && (value == null || value.trim().isEmpty)) {
                    return 'El título es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleInstitutionController,
                decoration: const InputDecoration(
                  labelText: 'Institución *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (_hasTitle && (value == null || value.trim().isEmpty)) {
                    return 'La institución es requerida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleYearController,
                decoration: const InputDecoration(
                  labelText: 'Año de obtención *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_hasTitle) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El año es requerido';
                    }
                    final year = int.tryParse(value);
                    if (year == null ||
                        year < 1950 ||
                        year > DateTime.now().year) {
                      return 'El año debe ser válido';
                    }
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWorkImagesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fotos de Trabajos Anteriores',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            if (_workImages.isNotEmpty) ...[
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _workImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderColor),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _workImages[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeWorkImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.errorColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: _pickWorkImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Agregar Fotos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.textOnPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificatesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Certificados y Documentos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            if (_certificateFiles.isNotEmpty) ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _certificateFiles.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.description),
                    title: Text(_certificateFiles[index].path.split('/').last),
                    trailing: IconButton(
                      icon:
                          const Icon(Icons.delete, color: AppColors.errorColor),
                      onPressed: () => _removeCertificate(index),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: _pickCertificates,
              icon: const Icon(Icons.upload_file),
              label: const Text('Subir Certificados'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryColor,
                foregroundColor: AppColors.textOnPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _registerWorker,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textOnPrimaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
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
              'Registrarse',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('¿Ya tienes cuenta? '),
        TextButton(
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/worker_login');
          },
          child: const Text(
            'Iniciar Sesión',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
