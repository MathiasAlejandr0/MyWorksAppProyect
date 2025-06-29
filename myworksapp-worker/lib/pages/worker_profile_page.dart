import 'package:flutter/material.dart';
import '../database/worker_database_helper.dart';
import '../models/worker.dart';
import '../utils/app_colors.dart';

class WorkerProfilePage extends StatefulWidget {
  final int workerId;
  const WorkerProfilePage({super.key, required this.workerId});

  @override
  State<WorkerProfilePage> createState() => _WorkerProfilePageState();
}

class _WorkerProfilePageState extends State<WorkerProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = WorkerDatabaseHelper();

  Worker? _worker;
  bool _isLoading = true;
  String? _error;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _professionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _hourlyRateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Para demo, buscamos por ID (en app real, usar sesión)
    final worker = await _dbHelper.getWorkerById(widget.workerId);
    if (worker != null) {
      _worker = worker;
      _nameController.text = _worker!.name;
      _phoneController.text = _worker!.phone;
      _professionController.text = _worker!.profession;
      _descriptionController.text = _worker!.description ?? '';
      _addressController.text = _worker!.address ?? '';
      _hourlyRateController.text = _worker!.hourlyRate?.toString() ?? '';
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _worker == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final updated = _worker!.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        profession: _professionController.text.trim(),
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        hourlyRate: double.tryParse(_hourlyRateController.text),
      );
      await _dbHelper.updateWorker(updated);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = 'Error al guardar: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textOnPrimaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _worker == null
              ? const Center(child: Text('No se pudo cargar el perfil.'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration:
                              const InputDecoration(labelText: 'Nombre'),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Campo requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration:
                              const InputDecoration(labelText: 'Teléfono'),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Campo requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _professionController,
                          decoration:
                              const InputDecoration(labelText: 'Profesión'),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Campo requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration:
                              const InputDecoration(labelText: 'Descripción'),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration:
                              const InputDecoration(labelText: 'Dirección'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _hourlyRateController,
                          decoration: const InputDecoration(
                              labelText: 'Tarifa por hora'),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 24),
                        if (_error != null)
                          Text(_error!,
                              style: const TextStyle(color: Colors.red)),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: AppColors.textOnPrimaryColor,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text('Guardar cambios'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
