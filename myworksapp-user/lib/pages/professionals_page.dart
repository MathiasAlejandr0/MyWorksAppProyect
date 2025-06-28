import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/worker_sync_service.dart';
import '../utils/app_colors.dart';
import 'professional_detail_page.dart';

class ProfessionalsPage extends StatefulWidget {
  const ProfessionalsPage({super.key});

  @override
  State<ProfessionalsPage> createState() => _ProfessionalsPageState();
}

class _ProfessionalsPageState extends State<ProfessionalsPage> {
  final WorkerSyncService _workerSyncService = WorkerSyncService();

  List<Professional> _professionals = [];
  List<Professional> _filteredProfessionals = [];
  bool _isLoading = true;
  String _selectedProfession = 'Todos';
  String _searchQuery = '';

  final List<String> _professions = [
    'Todos',
    'Plomero',
    'Electricista',
    'Albañil',
    'Jardinero',
    'Cerrajero',
    'Pintor',
    'Carpintero',
    'Técnico',
    'Limpieza',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfessionals();
  }

  Future<void> _loadProfessionals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Inicializar el servicio de sincronización
      await _workerSyncService.initialize();

      // Verificar si hay trabajadores disponibles
      final hasWorkers = await _workerSyncService.hasAvailableWorkers();

      if (hasWorkers) {
        // Cargar trabajadores desde la base de datos de trabajadores
        final workers = await _workerSyncService.getAvailableWorkers();
        setState(() {
          _professionals = workers;
          _filteredProfessionals = workers;
        });
      } else {
        // Si no hay trabajadores registrados, mostrar mensaje
        setState(() {
          _professionals = [];
          _filteredProfessionals = [];
        });
      }
    } catch (e) {
      // print('Error loading professionals: $e');
      setState(() {
        _professionals = [];
        _filteredProfessionals = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterProfessionals() {
    setState(() {
      _filteredProfessionals = _professionals.where((professional) {
        // Filtrar por profesión
        bool matchesProfession = _selectedProfession == 'Todos' ||
            professional.services.any((service) =>
                _getProfessionFromService(service) == _selectedProfession);

        // Filtrar por búsqueda
        bool matchesSearch = _searchQuery.isEmpty ||
            professional.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            professional.bio.toLowerCase().contains(_searchQuery.toLowerCase());

        return matchesProfession && matchesSearch;
      }).toList();
    });
  }

  String _getProfessionFromService(String service) {
    switch (service) {
      case 'plomeria':
        return 'Plomero';
      case 'electricidad':
        return 'Electricista';
      case 'construccion':
        return 'Albañil';
      case 'jardineria':
        return 'Jardinero';
      case 'cerrajeria':
        return 'Cerrajero';
      case 'pintura':
        return 'Pintor';
      case 'carpinteria':
        return 'Carpintero';
      case 'tecnico':
        return 'Técnico';
      case 'limpieza':
        return 'Limpieza';
      default:
        return 'Otros';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Profesionales'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textOnPrimaryColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _professionals.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildSearchAndFilter(),
                    Expanded(
                      child: _filteredProfessionals.isEmpty
                          ? _buildNoResults()
                          : _buildProfessionalsList(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people_outline,
            size: 80,
            color: AppColors.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay profesionales disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Los profesionales registrados aparecerán aquí cuando estén disponibles',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadProfessionals,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.textOnPrimaryColor,
            ),
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 60,
            color: AppColors.textSecondaryColor,
          ),
          SizedBox(height: 16),
          Text(
            'No se encontraron resultados',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Intenta con otros filtros o términos de búsqueda',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            onChanged: (value) {
              _searchQuery = value;
              _filterProfessionals();
            },
            decoration: InputDecoration(
              hintText: 'Buscar profesionales...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // Filtro por profesión
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _professions.length,
              itemBuilder: (context, index) {
                final profession = _professions[index];
                final isSelected = profession == _selectedProfession;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(profession),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedProfession = profession;
                      });
                      _filterProfessionals();
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.textOnPrimaryColor
                          : AppColors.textPrimaryColor,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredProfessionals.length,
      itemBuilder: (context, index) {
        final professional = _filteredProfessionals[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfessionalDetailPage(
                    professional: professional,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Foto de perfil
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primaryColor,
                    backgroundImage: professional.profileImage.isNotEmpty
                        ? AssetImage(professional.profileImage)
                        : null,
                    child: professional.profileImage.isEmpty
                        ? Text(
                            professional.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.textOnPrimaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  // Información del profesional
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                professional.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimaryColor,
                                ),
                              ),
                            ),
                            if (professional.isVerified)
                              const Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 20,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getProfessionFromService(
                              professional.services.first),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: AppColors.ratingColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${professional.rating.toStringAsFixed(1)} (${professional.totalReviews})',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: AppColors.textSecondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                professional.location.isNotEmpty
                                    ? professional.location
                                    : 'Ubicación no especificada',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondaryColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (professional.servicePrices.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Desde \$${professional.servicePrices.values.first.toStringAsFixed(0)}/hora',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Estado de disponibilidad
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: professional.isAvailable
                          ? AppColors.availableColor
                          : AppColors.unavailableColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      professional.isAvailable ? 'Disponible' : 'Ocupado',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
