import 'package:flutter/material.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/database/repositories/service_repository.dart';
import '../../../../core/database/repositories/service_config_repository.dart';
import '../../../../core/database/repositories/job_repository.dart';
import '../../../../core/database/models/service_model.dart';
import '../../../../core/domain/pricing_constants.dart';
import '../../../../core/domain/price_quote.dart';
import '../../../../core/services/job_booking_service.dart';
import '../../../../core/services/open_quote_notification_service.dart';
import '../../../../core/services/pricing_service.dart';
import '../../../../core/utils/comuna_utils.dart';
import '../../../../core/utils/sku_utils.dart';
import '../../../../core/domain/pricing_mode_recommendation.dart';
import '../widgets/pricing_mode_questionnaire.dart';
import '../widgets/open_quote_submitted_dialog.dart';
import '../../../../core/widgets/pricing_quote_card.dart';
import '../../../../core/widgets/escrow_checkout_sheet.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/location_picker_widget.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/job_service.dart';
import '../../../../core/database/models/user_model.dart';
import '../../../../core/database/models/worker_model.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/database/repositories/worker_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/widgets/service_disclaimer_dialog.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class ServiceRequestPage extends ConsumerStatefulWidget {
  final String? serviceId;
  final String? workerId;

  const ServiceRequestPage({super.key, this.serviceId, this.workerId});

  @override
  ConsumerState<ServiceRequestPage> createState() => _ServiceRequestPageState();
}

class _ServiceRequestPageState extends ConsumerState<ServiceRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final ServiceRepository _serviceRepository = ServiceRepository();
  final ServiceConfigRepository _configRepository = ServiceConfigRepository();
  final JobService _jobService = JobService.instance;
  final WorkerRepository _workerRepository = WorkerRepository();
  final UserRepository _userRepository = UserRepository();
  bool _isLoading = false;
  String? _selectedServiceId;
  String? _selectedWorkerId;
  WorkerModel? _selectedWorker;
  UserModel? _selectedWorkerUser;
  Map<String, dynamic> _serviceMetadata = {};
  String? _selectedVariant; // Variante seleccionada (para servicios con variantes)
  List<Map<String, dynamic>> _serviceVariants = []; // Variantes disponibles
  String _selectedAddress = '';
  double? _selectedLatitude;
  double? _selectedLongitude;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _pricingMode = '';
  int _blockHours = 4;
  PriceQuote? _pricePreview;
  PricingModeRecommendation? _pricingRecommendation;
  bool _questionnaireComplete = false;
  late final Future<List<ServiceModel>> _servicesFuture;
  List<ServiceModel> _services = [];
  bool _servicesReady = false;

  @override
  void initState() {
    super.initState();
    _servicesFuture = _serviceRepository.getAllServices();
    _servicesFuture.then((list) {
      if (mounted) {
        setState(() {
          _services = list;
          _servicesReady = true;
        });
      }
    });
    _selectedServiceId = widget.serviceId;
    _selectedWorkerId = widget.workerId;
    if (_selectedServiceId != null) {
      _loadServiceConfig(_selectedServiceId!);
    }
    if (_selectedWorkerId != null) {
      _loadSelectedWorker(_selectedWorkerId!);
    }
  }

  Future<void> _loadSelectedWorker(String workerId) async {
    final worker = await _workerRepository.getWorkerByUserId(workerId);
    final user = await _userRepository.getUserById(workerId);
    if (mounted) {
      setState(() {
        _selectedWorker = worker;
        _selectedWorkerUser = user;
      });
      _refreshPricePreview();
    }
  }

  String? _categoryForSelectedService() {
    if (_selectedServiceId == null) return null;
    for (final s in _services) {
      if (s.id == _selectedServiceId) return s.category;
    }
    return null;
  }

  Future<void> _refreshPricePreview() async {
    if (_selectedAddress.length < 5) return;
    final comuna = inferComunaKey(_selectedAddress);
    PriceQuote? preview;

    try {
      if (_pricingMode == PricingConstants.modeFixedPrice) {
        final sku = _pricingRecommendation?.skuCode ??
            variantToSkuCode(_selectedVariant);
        if (sku != null) {
          preview = await PricingService.instance.calculateFixedPrice(
            skuCode: sku,
            comunaKey: comuna,
          );
        }
      } else if (_pricingMode == PricingConstants.modeHourlyBlock &&
          _selectedWorker != null) {
        final rate = PricingService.instance
            .estimateHourlyRateFromVisitFee(_selectedWorker!.visitFee.round());
        preview = await PricingService.instance.calculateHourlyBlock(
          hourlyRateClp: rate,
          blockHours: _blockHours,
          comunaKey: comuna,
        );
      }
    } catch (_) {
      preview = null;
    }

    if (mounted) setState(() => _pricePreview = preview);
  }

  Future<void> _loadServiceConfig(String serviceId) async {
    try {
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

    if (_selectedServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un servicio')),
      );
      return;
    }
    if (!_questionnaireComplete || _pricingMode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Responde el cuestionario para definir la forma de cobro'),
        ),
      );
      return;
    }
    if (_pricingMode != PricingConstants.modeLegacy && _selectedWorkerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Elige un profesional desde su perfil para enviarle la solicitud',
          ),
        ),
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

      final comuna = inferComunaKey(_selectedAddress);
      final metadata =
          _serviceMetadata.isNotEmpty ? Map<String, dynamic>.from(_serviceMetadata) : null;
      final description = _descriptionController.text.trim();

      if (_pricingMode == PricingConstants.modeFixedPrice) {
        final sku = _pricingRecommendation?.skuCode ??
            variantToSkuCode(_selectedVariant) ??
            'FAUCET_REPLACE';
        final booking = await JobBookingService.instance.createFixedSkuBooking(
          userId: user.id,
          workerId: _selectedWorkerId!,
          serviceId: _selectedServiceId!,
          address: _selectedAddress,
          skuCode: sku,
          description: description,
          scheduledDate: scheduledDate,
          comunaKey: comuna,
          latitude: _selectedLatitude,
          longitude: _selectedLongitude,
          serviceMetadata: metadata,
        );
        if (!mounted) return;
        final paid = await EscrowCheckoutSheet.show(
          context,
          jobId: booking.job.id,
          quote: booking.quote,
        );
        if (paid) {
          await JobBookingService.instance.confirmEscrowAndAccept(
            jobId: booking.job.id,
            userId: user.id,
          );
        }
        if (!mounted) return;
        context.push('${AppConstants.routeJobDetail}/${booking.job.id}');
        return;
      }

      if (_pricingMode == PricingConstants.modeHourlyBlock) {
        final rate = PricingService.instance
            .estimateHourlyRateFromVisitFee(_selectedWorker!.visitFee.round());
        final booking = await JobBookingService.instance.createHourlyBlockBooking(
          userId: user.id,
          workerId: _selectedWorkerId!,
          serviceId: _selectedServiceId!,
          address: _selectedAddress,
          hourlyRateClp: rate,
          blockHours: _blockHours,
          description: description,
          scheduledDate: scheduledDate,
          comunaKey: comuna,
          latitude: _selectedLatitude,
          longitude: _selectedLongitude,
          serviceMetadata: metadata,
        );
        if (!mounted) return;
        final paid = await EscrowCheckoutSheet.show(
          context,
          jobId: booking.job.id,
          quote: booking.quote,
        );
        if (paid) {
          await JobBookingService.instance.confirmEscrowAndAccept(
            jobId: booking.job.id,
            userId: user.id,
          );
        }
        if (!mounted) return;
        context.push('${AppConstants.routeJobDetail}/${booking.job.id}');
        return;
      }

      if (_pricingMode == PricingConstants.modeOpenQuote) {
        final workerId = _selectedWorkerId!;
        final workerName = _selectedWorkerUser?.name ?? 'el profesional';

        final job = await JobBookingService.instance.createOpenQuoteJob(
          userId: user.id,
          invitedWorkerId: workerId,
          serviceId: _selectedServiceId!,
          address: _selectedAddress,
          description: description,
          scheduledDate: scheduledDate,
          comunaKey: comuna,
          latitude: _selectedLatitude,
          longitude: _selectedLongitude,
          serviceMetadata: metadata,
        );

        await OpenQuoteNotificationService.instance.notifyInvitedWorker(
          jobId: job.id,
          workerId: workerId,
        );

        if (!mounted) return;
        await OpenQuoteSubmittedDialog.show(
          context,
          workerName: workerName,
        );
        if (!mounted) return;
        context.push('${AppConstants.routeJobDetail}/${job.id}');
        return;
      }

      // Legacy: sin escrow
      final job = await _jobService.createJob(
        userId: user.id,
        serviceId: _selectedServiceId!,
        description: description,
        address: _selectedAddress,
        latitude: _selectedLatitude,
        longitude: _selectedLongitude,
        scheduledDate: scheduledDate,
        serviceMetadata: metadata,
      );

      if (job == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al crear la solicitud')),
        );
        return;
      }

      final jobRepository = JobRepository();
      final workers = await _workerRepository.getWorkersByServiceCategory(service.category);
      for (final worker in workers) {
        if (worker.isAvailable && !await jobRepository.hasActiveJobs(worker.userId)) {
          await NotificationService.instance.showNotification(
            title: 'Nueva solicitud',
            body: 'Hay una nueva solicitud de servicio disponible',
            userId: worker.userId,
            type: 'new_job',
            relatedId: job.id,
          );
        }
      }

      if (_selectedWorkerId != null) {
        await jobRepository.assignWorker(job.id, _selectedWorkerId!);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud creada exitosamente')),
      );

      if (_selectedWorkerId != null) {
        context.push('${AppConstants.routeJobDetail}/${job.id}');
      } else {
        context.push(
          AppConstants.routeWorkerList,
          extra: {
            'serviceId': _selectedServiceId,
            'jobId': job.id,
          },
        );
      }
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
      appBar: AppGradientAppBar(
        title: const Text('Solicitar Servicio'),
      ),
      body: !_servicesReady
          ? const LoadingWidget(message: 'Cargando servicios...')
          : SingleChildScrollView(
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
                  if (_selectedWorker != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primaryLight.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trabajador seleccionado',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppColors.primaryLight,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedWorkerUser?.name ?? _selectedWorker!.profession,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            _selectedWorker!.profession,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'El profesional revisará tu solicitud y te enviará una cotización. Pagas el total aprobado; la comisión del servicio (5%, mínimo \$1.000) se descuenta del profesional.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedServiceId,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de servicio',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _services.map((service) {
                      return DropdownMenuItem(
                        value: service.id,
                        child: Text(service.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedServiceId = value;
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
                      if (_selectedAddress == address &&
                          _selectedLatitude == latitude &&
                          _selectedLongitude == longitude) {
                        return;
                      }
                      setState(() {
                        _selectedAddress = address;
                        _selectedLatitude = latitude;
                        _selectedLongitude = longitude;
                      });
                      _refreshPricePreview();
                    },
                  ),
                  const SizedBox(height: 20),
                  PricingModeQuestionnaire(
                    workerPreselected: _selectedWorkerId != null,
                    category: _categoryForSelectedService(),
                    initialRecommendation: _pricingRecommendation,
                    onRecommendation: _applyPricingRecommendation,
                  ),
                  if (_pricePreview != null) ...[
                    const SizedBox(height: 12),
                    PricingQuoteCard(quote: _pricePreview!),
                  ],
                  const SizedBox(height: 16),
                  // Variantes del catálogo (solo si el cuestionario no fijó ítem)
                  if (_serviceVariants.isNotEmpty &&
                      _pricingRecommendation?.variantKey == null) ...[
                    Text(
                      'Tipo de servicio',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    RadioGroup<String>(
                      groupValue: _selectedVariant,
                      onChanged: (value) {
                        if (value == null) return;
                        final variant = _serviceVariants
                            .firstWhere((v) => v['id'] == value);
                        setState(() {
                          _selectedVariant = value;
                          _serviceMetadata['variant'] = value;
                          _serviceMetadata['variantName'] = variant['name'];
                          _serviceMetadata['variantDescription'] =
                              variant['description'];
                        });
                        _refreshPricePreview();
                      },
                      child: Column(
                        children: _serviceVariants.map((variant) {
                          final variantId = variant['id'] as String;
                          final variantName = variant['name'] as String;
                          final variantDesc = variant['description'] as String?;
                          final isSelected = _selectedVariant == variantId;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: isSelected
                                ? AppColors.primaryLight.withValues(alpha: 0.1)
                                : null,
                            child: RadioListTile<String>(
                              title: Text(
                                variantName,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle:
                                  variantDesc != null ? Text(variantDesc) : null,
                              value: variantId,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
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
                        : Text(
                            !_questionnaireComplete
                                ? 'Solicitar al profesional'
                                : _pricingMode == PricingConstants.modeOpenQuote
                                    ? 'Enviar solicitud al profesional'
                                    : _pricingMode == PricingConstants.modeLegacy
                                        ? 'Continuar'
                                        : 'Continuar al pago',
                          ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _applyPricingRecommendation(PricingModeRecommendation rec) {
    setState(() {
      _pricingRecommendation = rec;
      _pricingMode = rec.mode;
      _questionnaireComplete = true;
      if (rec.blockHours != null) {
        _blockHours = rec.blockHours!;
      }
      if (rec.variantKey != null) {
        _selectedVariant = rec.variantKey;
        _serviceMetadata['variant'] = rec.variantKey;
      }
      _serviceMetadata['pricing_questionnaire'] = rec.questionnaireAnswers;
    });
    _refreshPricePreview();
  }

}

