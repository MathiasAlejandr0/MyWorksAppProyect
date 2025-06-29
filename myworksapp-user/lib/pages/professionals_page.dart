import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/app_colors.dart';
import '../services/app_communication_service.dart';

class ProfessionalsPage extends StatefulWidget {
  final Service service;

  const ProfessionalsPage({
    super.key,
    required this.service,
  });

  @override
  State<ProfessionalsPage> createState() => _ProfessionalsPageState();
}

class _ProfessionalsPageState extends State<ProfessionalsPage> {
  final AppCommunicationService _communicationService =
      AppCommunicationService();
  List<Map<String, dynamic>> _availableWorkers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfessionals();
  }

  Future<void> _loadProfessionals() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Cargar trabajadores disponibles del sistema de comunicación
      final availableWorkers =
          await _communicationService.getAvailableWorkers();

      // Filtrar trabajadores por el servicio actual
      final filteredWorkers = availableWorkers.where((worker) {
        final profession = worker['profession']?.toString().toLowerCase() ?? '';
        final serviceName = widget.service.name.toLowerCase();
        return profession.contains(serviceName) ||
            serviceName.contains(profession) ||
            _isProfessionMatchingService(profession, serviceName);
      }).toList();

      setState(() {
        _availableWorkers = filteredWorkers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar profesionales: $e';
        _isLoading = false;
      });
    }
  }

  bool _isProfessionMatchingService(String profession, String serviceName) {
    final professionMap = {
      'plomero': ['plomeria', 'tuberias', 'agua', 'baño'],
      'electricista': ['electricidad', 'instalacion', 'reparacion'],
      'albañil': ['construccion', 'reparacion', 'obra'],
      'jardinero': ['jardineria', 'poda', 'plantas'],
      'cerrajero': ['cerrajeria', 'cerraduras', 'llaves'],
      'pintor': ['pintura', 'pintar'],
      'carpintero': ['carpinteria', 'muebles', 'madera'],
      'tecnico': ['tecnico', 'reparacion', 'mantenimiento'],
      'limpieza': ['limpieza', 'aseo', 'limpiar'],
    };

    final matchingServices = professionMap[profession] ?? [];
    return matchingServices.any((service) =>
        serviceName.contains(service) || service.contains(serviceName));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text('Profesionales de ${widget.service.name}'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textOnPrimaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfessionals,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProfessionals,
                  child: _availableWorkers.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 80,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No hay profesionales disponibles',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Los profesionales aparecerán aquí cuando estén disponibles',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _availableWorkers.length,
                          itemBuilder: (context, index) {
                            final worker = _availableWorkers[index];
                            return _buildWorkerCard(worker);
                          },
                        ),
                ),
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> worker) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryColor.withValues(alpha: 0.2),
          child: Text(
            (worker['name']?.substring(0, 1).toUpperCase()) ?? 'T',
            style: TextStyle(color: AppColors.primaryColor),
          ),
        ),
        title: Text(
          worker['name'] ?? 'Trabajador',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(worker['profession'] ?? 'Profesional'),
            const Text('Disponible ahora'),
            if (worker['hourlyRate'] != null)
              Text(
                '\$${worker['hourlyRate'].toStringAsFixed(0)}/hora',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            // Navegar a solicitar servicio
            Navigator.pushNamed(
              context,
              '/request_service',
              arguments: {
                'service': widget.service,
                'professional': _convertWorkerToProfessional(worker),
              },
            );
          },
          child: const Text('Solicitar'),
        ),
      ),
    );
  }

  Professional _convertWorkerToProfessional(Map<String, dynamic> worker) {
    return Professional(
      id: worker['id'].toString(),
      name: worker['name'] ?? 'Trabajador',
      email: worker['email'] ?? '',
      phone: worker['phone'] ?? '',
      profileImage: '',
      bio: worker['description'] ?? 'Trabajador disponible',
      services: [widget.service.id],
      rating: 0.0,
      totalReviews: 0,
      completedJobs: 0,
      yearsExperience: 0,
      isVerified: false,
      isAvailable: true,
      location: worker['address'] ?? '',
      certifications: [],
      servicePrices: {
        widget.service.id: worker['hourlyRate'] ?? widget.service.basePrice
      },
    );
  }
}
