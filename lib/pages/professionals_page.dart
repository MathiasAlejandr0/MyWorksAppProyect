import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/app_colors.dart';
import '../database/database_helper.dart';
import 'professional_detail_page.dart';

class ProfessionalsPage extends StatefulWidget {
  final Service service;

  const ProfessionalsPage({super.key, required this.service});

  @override
  State<ProfessionalsPage> createState() => _ProfessionalsPageState();
}

class _ProfessionalsPageState extends State<ProfessionalsPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Professional> _professionals = [];
  bool _isLoading = true;
  String _sortBy = 'rating';

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
      final professionals = await _dbHelper.getProfessionalsByService(
        widget.service.id,
      );
      setState(() {
        _professionals = professionals;
        _isLoading = false;
      });
      _sortProfessionals();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar profesionales: $e')),
        );
      }
    }
  }

  void _sortProfessionals() {
    switch (_sortBy) {
      case 'rating':
        _professionals.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'experience':
        _professionals.sort(
          (a, b) => b.yearsExperience.compareTo(a.yearsExperience),
        );
        break;
      case 'price':
        _professionals.sort((a, b) {
          final priceA =
              a.servicePrices[widget.service.id] ?? widget.service.basePrice;
          final priceB =
              b.servicePrices[widget.service.id] ?? widget.service.basePrice;
          return priceA.compareTo(priceB);
        });
        break;
      case 'reviews':
        _professionals.sort((a, b) => b.totalReviews.compareTo(a.totalReviews));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profesionales - ${widget.service.name}'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _sortProfessionals();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rating',
                child: Row(
                  children: [
                    Icon(Icons.star),
                    SizedBox(width: 8),
                    Text('Por calificación'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'experience',
                child: Row(
                  children: [
                    Icon(Icons.work),
                    SizedBox(width: 8),
                    Text('Por experiencia'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'price',
                child: Row(
                  children: [
                    Icon(Icons.attach_money),
                    SizedBox(width: 8),
                    Text('Por precio'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reviews',
                child: Row(
                  children: [
                    Icon(Icons.rate_review),
                    SizedBox(width: 8),
                    Text('Por reseñas'),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.sort),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _professionals.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _professionals.length,
              itemBuilder: (context, index) {
                final professional = _professionals[index];
                return ProfessionalCard(
                  professional: professional,
                  service: widget.service,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfessionalDetailPage(
                          professional: professional,
                          service: widget.service,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No hay profesionales disponibles',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Para este servicio en tu área',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Volver a servicios'),
          ),
        ],
      ),
    );
  }
}

class ProfessionalCard extends StatelessWidget {
  final Professional professional;
  final Service service;
  final VoidCallback onTap;

  const ProfessionalCard({
    super.key,
    required this.professional,
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final price = professional.servicePrices[service.id] ?? service.basePrice;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Foto del profesional
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: AppColors.primary.withOpacity(0.1),
                ),
                child: professional.profileImage.startsWith('assets/')
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.asset(
                          professional.profileImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 40,
                              color: AppColors.primary,
                            );
                          },
                        ),
                      )
                    : Icon(Icons.person, size: 40, color: AppColors.primary),
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (professional.isVerified)
                          Icon(Icons.verified, color: Colors.blue, size: 20),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Calificación
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${professional.rating.toStringAsFixed(1)} (${professional.totalReviews})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${professional.completedJobs} trabajos',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Experiencia
                    Text(
                      '${professional.yearsExperience} años de experiencia',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Ubicación
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          professional.location,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Precio
                    Row(
                      children: [
                        Text(
                          '\$${price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          ' / servicio',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Indicador de disponibilidad
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: professional.isAvailable
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    professional.isAvailable ? 'Disponible' : 'Ocupado',
                    style: TextStyle(
                      fontSize: 12,
                      color: professional.isAvailable
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
