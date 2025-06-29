import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/worker.dart';
import '../database/worker_database_helper.dart';
import '../utils/app_colors.dart';

class WorkerEditProfilePage extends StatefulWidget {
  const WorkerEditProfilePage({super.key});

  @override
  State<WorkerEditProfilePage> createState() => _WorkerEditProfilePageState();
}

class _WorkerEditProfilePageState extends State<WorkerEditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _databaseHelper = WorkerDatabaseHelper();

  Worker? _worker;
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers para los campos editables
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hourlyRateController = TextEditingController();

  String _selectedProfession = '';
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    _loadWorkerData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkerData() async {
    try {
      // Obtener el trabajador actual desde la sesión
      final prefs = await SharedPreferences.getInstance();
      final workerId = prefs.getInt('worker_id');

      if (workerId != null) {
        final worker = await _databaseHelper.getWorkerById(workerId);

        if (worker != null) {
          setState(() {
            _worker = worker;
            _nameController.text = worker.name;
            _phoneController.text = worker.phone;
            _addressController.text = worker.address ?? '';
            _descriptionController.text = worker.description ?? '';
            _hourlyRateController.text = worker.hourlyRate?.toString() ?? '';
            _selectedProfession = worker.profession;
            _isAvailable = worker.isAvailable;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al cargar datos del perfil'),
                backgroundColor: Colors.red,
              ),
            );
            Navigator.of(context).pop();
          }
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay sesión activa'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      if (_worker != null) {
        final updatedWorker = _worker!.copyWith(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          hourlyRate: _hourlyRateController.text.trim().isEmpty
              ? null
              : double.tryParse(_hourlyRateController.text.trim()),
          profession: _selectedProfession,
          isAvailable: _isAvailable,
        );

        await _databaseHelper.updateWorker(updatedWorker);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context)
              .pop(true); // Retornar true para indicar que se actualizó
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar perfil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPersonalInfoSection(),
              const SizedBox(height: 24),
              _buildProfessionalInfoSection(),
              const SizedBox(height: 24),
              _buildAvailabilitySection(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Personal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
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
                return null;
              },
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
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Profesional',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
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
              items: [
                'Plomero',
                'Electricista',
                'Carpintero',
                'Pintor',
                'Jardinero',
                'Limpieza',
                'Técnico',
                'Otro',
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedProfession = newValue!;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La profesión es requerida';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hourlyRateController,
              decoration: const InputDecoration(
                labelText: 'Tarifa por Hora (\$)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Disponibilidad',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Disponible para trabajo'),
              subtitle: const Text('Los clientes podrán contactarte'),
              value: _isAvailable,
              onChanged: (bool value) {
                setState(() {
                  _isAvailable = value;
                });
              },
              activeColor: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _saveProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: _isSaving
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Guardar Cambios',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
    );
  }
}
