import 'package:flutter/material.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/layout_utils.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/repositories/job_repository.dart';
import '../../../../core/database/repositories/rating_repository.dart';
import '../../../../core/database/models/rating_model.dart';
import '../../../../core/database/supabase_db.dart';
import '../../../../core/services/dispute_service.dart';
import '../../../../core/utils/error_handler.dart';
import '../../domain/rating_gate.dart';

class RatingPage extends StatefulWidget {
  final String jobId;

  const RatingPage({super.key, required this.jobId});

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final RatingRepository _ratingRepository = RatingRepository();

  int _selectedRating = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
      final userId = supabase.auth.currentUser?.id;
      final job = await JobRepository().getJobById(widget.jobId);
      final direction = userId != null && userId == job?.workerId
          ? RatingDirection.workerToClient
          : RatingDirection.clientToWorker;
      final existing = await _ratingRepository.getRatingByJobId(
        widget.jobId,
        direction: direction,
      );
      final disputeOpen =
          await DisputeService.instance.hasOpenDispute(widget.jobId);
      if (!mounted) return;
      final block = ratingBlockReason(
        currentUserId: userId,
        jobClientId: job?.userId,
        jobWorkerId: job?.workerId,
        jobStatus: job?.status,
        alreadyRated: existing != null,
        disputeOpen: disputeOpen,
        direction: direction,
      );
      if (block != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(block)));
        setState(() => _isLoading = false);
        return;
      }

      final rating = RatingModel(
        id: const Uuid().v4(),
        jobId: widget.jobId,
        userId: userId,
        ratedUserId: direction == RatingDirection.workerToClient
            ? job?.userId
            : job?.workerId,
        direction: direction,
        score: _selectedRating,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _ratingRepository.createRating(rating);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calificación enviada exitosamente')),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorHandler.getErrorMessage(e))),
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
      appBar: const AppGradientAppBar(
        title: const Text('Calificar'),
      ),
      body: SingleChildScrollView(
        padding: LayoutUtils.scrollPadding(context),
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
                            ? AppColors.warning
                            : AppColors.grayMedium,
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
              const SizedBox(height: AppSpacing.xl),
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
