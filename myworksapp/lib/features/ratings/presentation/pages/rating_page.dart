import 'package:flutter/material.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/repositories/rating_repository.dart';
import '../../../../core/database/repositories/job_repository.dart';
import '../../../../core/database/repositories/worker_repository.dart';
import '../../../../core/database/models/rating_model.dart';
import '../../../../core/database/models/job_model.dart';
import '../../../../core/database/supabase_db.dart';

class RatingPage extends ConsumerStatefulWidget {
  final String jobId;

  const RatingPage({super.key, required this.jobId});

  @override
  ConsumerState<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends ConsumerState<RatingPage> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final RatingRepository _ratingRepository = RatingRepository();
  final JobRepository _jobRepository = JobRepository();
  final WorkerRepository _workerRepository = WorkerRepository();

  int _selectedRating = 0;
  bool _isLoading = false;
  JobModel? _job;

  @override
  void initState() {
    super.initState();
    _loadJob();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadJob() async {
    try {
      final job = await _jobRepository.getJobById(widget.jobId);
      setState(() {
        _job = job;
      });
    } catch (e) {
      // Error al cargar trabajo
    }
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una calificación')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final rating = RatingModel(
        id: const Uuid().v4(),
        jobId: widget.jobId,
        userId: supabase.auth.currentUser?.id,
        score: _selectedRating,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _ratingRepository.createRating(rating);

      // Actualizar calificación promedio del trabajador
      if (_job?.workerId != null) {
        final avgRating = await _ratingRepository.getAverageRatingByWorkerId(_job!.workerId!);
        await _workerRepository.updateRating(_job!.workerId!, avgRating);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calificación enviada exitosamente')),
      );

      context.pop();
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
        title: const Text('Calificar Trabajo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '¿Cómo fue tu experiencia?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 32),
              // Selector de estrellas
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final rating = index + 1;
                    return IconButton(
                      icon: Icon(
                        rating <= _selectedRating
                            ? Icons.star
                            : Icons.star_border,
                        size: 48,
                        color: rating <= _selectedRating
                            ? Colors.amber
                            : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedRating = rating;
                        });
                      },
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Comentario (opcional)',
                  prefixIcon: Icon(Icons.comment),
                  hintText: 'Comparte tu experiencia...',
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitRating,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enviar Calificación'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

