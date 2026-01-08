import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/database/repositories/service_repository.dart';
import '../../../../core/database/repositories/service_config_repository.dart';
import '../../../../core/database/repositories/job_repository.dart';
import '../../../../core/database/models/job_model.dart';
import '../../../../core/database/models/service_model.dart';
import '../../../../core/database/models/service_config_model.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/location_picker_widget.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/job_service.dart';
import '../../../../core/services/service_legal_validator.dart';
import '../../../../core/database/repositories/worker_repository.dart';
import '../../../../core/widgets/service_disclaimer_dialog.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/dynamic_service_form.dart';
import '../widgets/price_estimate_card.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ServiceRequestPage extends ConsumerStatefulWidget {
  final String? serviceId;

  const ServiceRequestPage({super.key, this.serviceId});

  @override
  ConsumerState<ServiceRequestPage> createState() => _ServiceRequestPageState();
}

class _ServiceRequestPageState extends ConsumerState<ServiceRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _dynamicFormKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final ServiceRepository _serviceRepository = ServiceRepository();
  final ServiceConfigRepository _configRepository = ServiceConfigRepository();
  final JobService _jobService = JobService.instance;
  final ServiceLegalValidator _legalValidator = ServiceLegalValidator.instance;
  bool _isLoading = false;
  String? _selectedServiceId;
  ServiceModel? _selectedService;
  ServiceConfigModel? _serviceConfig;
  Map<String, dynamic> _serviceMetadata = {};
  String? _selectedVariant; // Variante seleccionada (para servicios con variantes)
  List<Map<String, dynamic>> _serviceVariants = []; // Variantes disponibles
  String _selectedAddress = '';
  double? _selectedLatitude;
  double? _selectedLongitude;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedServiceId = widget.serviceId;
    if (_selectedServiceId != null) {
      _loadServiceConfig(_selectedServiceId!);
    }
  }

  Future<void> _loadServiceConfig(String serviceId) async {
    try {
      final service = await _serviceRepository.getServiceById(serviceId);
      final config = await _configRepository.getConfigByServiceId(serviceId);
      
      // Extraer variantes si existen
      List<Map<String, dynamic>> variants = [];
      String? selectedVariant;
      
      if (config != null && config.configSchema.containsKey('variants')) {
        final variantsList = config.configSchema['variants'] as List<dynamic>?;
        if (variantsList != null) {
          variants = variantsList.map((v) => v as Map<String, dynamic>).toList();
          // Seleccionar la primera variante por defecto
          if (variants.isNotEmpty) {
            selectedVariant = variants.first['id'] as String?;
          }
        }
      }
      
      setState(() {
        _selectedService = service;
        _serviceConfig = config;
        _serviceVariants = variants;
        _selectedVariant = selectedVariant;
        // Agregar variante seleccionada a metadata
        if (selectedVariant != null) {
          _serviceMetadata['variant'] = selectedVariant;
        }
      });
    } catch (e) {
      // Ignorar errores, simplemente no mostrar campos dinámicos
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validar formulario dinámico si existe
    if (_serviceConfig != null && _dynamicFormKey.currentState != null) {
      if (!_dynamicFormKey.currentState!.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor completa todos los campos requeridos')),
        );
        return;
      }
    }
    
    if (_selectedServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un servicio')),
      );
      return;
    }
    if (_selectedAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una ubicación en el mapa')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final user = authState.user;

      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes iniciar sesión')),
        );
        return;
      }

      // Obtener información del servicio para el diálogo
      final service = await _serviceRepository.getServiceById(_selectedServiceId!);
      if (service == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Servicio no encontrado')),
        );
        return;
      }

      // Mostrar confirmación legal explícita
      final accepted = await ServiceDisclaimerDialog.show(
        context,
        serviceId: _selectedServiceId!,
        serviceName: service.name,
      );

      if (!accepted) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      DateTime? scheduledDate;
      if (_selectedDate != null && _selectedTime != null) {
        scheduledDate = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
      }

      // Crear trabajo usando JobService (incluye validaciones legales)
      final job = await _jobService.createJob(
        userId: user.id,
        serviceId: _selectedServiceId!,
        description: _descriptionController.text.trim(),
        address: _selectedAddress,
        latitude: _selectedLatitude,
        longitude: _selectedLongitude,
        scheduledDate: scheduledDate,
        serviceMetadata: _serviceMetadata.isNotEmpty ? _serviceMetadata : null,
      );

      if (job == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al crear la solicitud')),
        );
        return;
      }

      // Notificar a trabajadores disponibles del mismo servicio que no tienen trabajos activos
      final WorkerRepository _workerRepository = WorkerRepository();
      final JobRepository _jobRepository = JobRepository();
      final workers = await _workerRepository.getWorkersByProfession(
        await _getProfessionFromService(_selectedServiceId!),
      );

      for (var worker in workers) {
        if (worker.isAvailable) {
          // Verificar que no tenga trabajos activos
          final hasActiveJobs = await _jobRepository.hasActiveJobs(worker.userId);
          if (!hasActiveJobs) {
            await NotificationService.instance.showNotification(
              title: 'Nueva Solicitud',
              body: 'Hay una nueva solicitud de servicio disponible',
              userId: worker.userId,
              type: 'new_job',
              relatedId: job.id,
            );
          }
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud creada exitosamente')),
      );

      context.push(
        AppConstants.routeWorkerList,
        extra: {
          'serviceId': _selectedServiceId,
          'jobId': job.id,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar Servicio'),
      ),
      body: FutureBuilder(
        future: _serviceRepository.getAllServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          final services = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Completa los datos de tu solicitud',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedServiceId,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de servicio',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: services.map((service) {
                      return DropdownMenuItem(
                        value: service.id,
                        child: Text(service.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedServiceId = value;
                        _serviceConfig = null;
                        _selectedService = null;
                        _serviceMetadata = {};
                        _serviceVariants = [];
                        _selectedVariant = null;
                      });
                      if (value != null) {
                        _loadServiceConfig(value);
                      }
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecciona un servicio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ubicación',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tu ubicación se detectará automáticamente',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  LocationPickerWidget(
                    onLocationSelected: (address, latitude, longitude) {
                      setState(() {
                        _selectedAddress = address;
                        _selectedLatitude = latitude;
                        _selectedLongitude = longitude;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Selector de variantes (si el servicio tiene variantes)
                  if (_serviceVariants.isNotEmpty) ...[
                    Text(
                      'Tipo de servicio',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...(_serviceVariants.map((variant) {
                      final variantId = variant['id'] as String;
                      final variantName = variant['name'] as String;
                      final variantDesc = variant['description'] as String?;
                      final isSelected = _selectedVariant == variantId;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isSelected 
                          ? AppColors.primaryLight.withOpacity(0.1)
                          : null,
                        child: RadioListTile<String>(
                          title: Text(
                            variantName,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          subtitle: variantDesc != null ? Text(variantDesc) : null,
                          value: variantId,
                          groupValue: _selectedVariant,
                          onChanged: (value) {
                            setState(() {
                              _selectedVariant = value;
                              _serviceMetadata['variant'] = value;
                              // Actualizar metadata con información de la variante
                              _serviceMetadata['variantName'] = variantName;
                              _serviceMetadata['variantDescription'] = variantDesc;
                            });
                          },
                        ),
                      );
                    }).toList()),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción del problema',
                      prefixIcon: Icon(Icons.description),
                      hintText: 'Describe el problema o trabajo a realizar',
                    ),
                    maxLines: 5,
                    validator: Validators.validateDescription,
                  ),
                  // Campos dinámicos del servicio
                  if (_serviceConfig != null) ...[
                    const SizedBox(height: 24),
                    DynamicServiceForm(
                      key: ValueKey('${_selectedServiceId}_${_serviceConfig!.id}'), // Clave única para evitar rebuilds innecesarios
                      config: _serviceConfig!,
                      formKey: _dynamicFormKey,
                      initialValues: null, // No pasar initialValues para evitar reinicializaciones
                      onChanged: (values) {
                        // Solo actualizar si realmente hay cambios y el widget está montado
                        if (!mounted) return;
                        
                        final newMetadata = Map<String, dynamic>.from(values);
                        // Comparar para evitar actualizaciones innecesarias que causan rebuilds
                        if (_mapsAreDifferent(_serviceMetadata, newMetadata)) {
                          // Usar Future.microtask para evitar setState durante build
                          Future.microtask(() {
                            if (mounted) {
                              setState(() {
                                _serviceMetadata = newMetadata;
                              });
                            }
                          });
                        }
                      },
                    ),
                  ],
                  // Precio estimado
                  if (_selectedService != null) ...[
                    const SizedBox(height: 24),
                    PriceEstimateCard(
                      service: _selectedService!,
                      serviceMetadata: _serviceMetadata.isNotEmpty ? _serviceMetadata : null,
                      itemCount: _serviceMetadata['quantity'] as int?,
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Fecha y hora
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: Text(
                            _selectedDate == null
                                ? 'Seleccionar fecha'
                                : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() => _selectedDate = date);
                            }
                          },
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          leading: const Icon(Icons.access_time),
                          title: Text(
                            _selectedTime == null
                                ? 'Seleccionar hora'
                                : _selectedTime!.format(context),
                          ),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              setState(() => _selectedTime = time);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Continuar'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<String> _getProfessionFromService(String serviceId) async {
    final serviceProfessionMap = {
      '1': 'Maestro Constructor',
      '2': 'Gasfiter',
      '3': 'Electricista',
      '4': 'Cerrajero',
      '5': 'Pintor',
      '6': 'Técnico en General',
    };
    return serviceProfessionMap[serviceId] ?? 'Técnico en General';
  }

  /// Compara dos mapas para determinar si son diferentes
  bool _mapsAreDifferent(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return true;
    for (final key in map1.keys) {
      if (map1[key] != map2[key]) return true;
    }
    return false;
  }
}

