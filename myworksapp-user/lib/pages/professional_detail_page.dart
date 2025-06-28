import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/worker_sync_service.dart';
import '../utils/app_colors.dart';

class ProfessionalDetailPage extends StatefulWidget {
  final Professional professional;

  const ProfessionalDetailPage({
    super.key,
    required this.professional,
  });

  @override
  State<ProfessionalDetailPage> createState() => _ProfessionalDetailPageState();
}

class _ProfessionalDetailPageState extends State<ProfessionalDetailPage> {
  final WorkerSyncService _workerSyncService = WorkerSyncService();
  List<Review> _reviews = [];
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      await _workerSyncService.initialize();
      final reviews = await _workerSyncService.getWorkerReviews(
        int.parse(widget.professional.id),
      );
      setState(() {
        _reviews = reviews;
        _isLoadingReviews = false;
      });
    } catch (e) {
      print('Error loading reviews: $e');
      setState(() {
        _isLoadingReviews = false;
      });
    }
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
        title: Text(widget.professional.name),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textOnPrimaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildInfoSection(),
            _buildServicesSection(),
            _buildReviewsSection(),
            const SizedBox(height: 100), // Espacio para el botón flotante
          ],
        ),
      ),
      floatingActionButton: _buildContactButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Foto de perfil
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.textOnPrimaryColor,
            backgroundImage: widget.professional.profileImage.isNotEmpty
                ? AssetImage(widget.professional.profileImage)
                : null,
            child: widget.professional.profileImage.isEmpty
                ? Text(
                    widget.professional.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),

          // Nombre y verificación
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.professional.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnPrimaryColor,
                ),
              ),
              if (widget.professional.isVerified) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.verified,
                  color: Colors.blue,
                  size: 24,
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Profesión
          Text(
            _getProfessionFromService(widget.professional.services.first),
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textOnPrimaryColor,
            ),
          ),

          const SizedBox(height: 16),

          // Calificación
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star,
                color: AppColors.ratingColor,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.professional.rating.toStringAsFixed(1)} (${widget.professional.totalReviews} reseñas)',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textOnPrimaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Estado de disponibilidad
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: widget.professional.isAvailable
                  ? AppColors.availableColor
                  : AppColors.unavailableColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.professional.isAvailable ? 'Disponible' : 'Ocupado',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.description,
                    'Descripción',
                    widget.professional.bio.isNotEmpty
                        ? widget.professional.bio
                        : 'Sin descripción disponible',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.location_on,
                    'Ubicación',
                    widget.professional.location.isNotEmpty
                        ? widget.professional.location
                        : 'Ubicación no especificada',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.phone,
                    'Teléfono',
                    widget.professional.phone,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.email,
                    'Email',
                    widget.professional.email,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Servicios y Precios',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children:
                    widget.professional.servicePrices.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getProfessionFromService(entry.key),
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimaryColor,
                          ),
                        ),
                        Text(
                          '\$${entry.value.toStringAsFixed(0)}/hora',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reseñas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingReviews)
            const Center(child: CircularProgressIndicator())
          else if (_reviews.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.rate_review,
                      size: 48,
                      color: AppColors.textSecondaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay reseñas aún',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: _reviews.take(5).map((review) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primaryColor,
                              child: Text(
                                review.clientName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.textOnPrimaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review.clientName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimaryColor,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 16,
                                        color: AppColors.ratingColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        review.rating.toString(),
                                        style: const TextStyle(
                                          color: AppColors.textSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatDate(review.reviewDate),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                        if (review.comment.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            review.comment,
                            style: const TextStyle(
                              color: AppColors.textPrimaryColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primaryColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryColor,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: widget.professional.isAvailable
            ? () {
                // Aquí se podría implementar la funcionalidad de contacto
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcionalidad de contacto en desarrollo'),
                  ),
                );
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: AppColors.textOnPrimaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          widget.professional.isAvailable
              ? 'Contactar Profesional'
              : 'No Disponible',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
