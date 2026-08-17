import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/ai_service_recommendation_engine.dart';
import '../../services/app_feedback.dart';
import '../../design_system/app_radius.dart';
import '../../design_system/app_spacing.dart';
import '../../theme/app_colors.dart';
import 'primary_button.dart';
import 'worker_card.dart';

/// Widget Inteligente estilo Apple para la Plataforma Web que evalúa necesidades por palabras clave.
class WebAiAssistantWidget extends StatefulWidget {
  const WebAiAssistantWidget({super.key});

  @override
  State<WebAiAssistantWidget> createState() => _WebAiAssistantWidgetState();
}

class _WebAiAssistantWidgetState extends State<WebAiAssistantWidget> {
  final TextEditingController _queryController = TextEditingController();
  AiRecommendationResult? _result;
  bool _isAnalyzing = false;

  final List<String> _quickPrompts = [
    '🔧 Fuga de agua en lavaplatos',
    '⚡ Enchufe quemado en la cocina',
    '🪛 Armado de clóset 3 puertas',
    '🧹 Limpieza profunda departamento',
    '🚚 Flete con camión para traslado',
  ];

  Future<void> _analyze(String text) async {
    if (text.trim().isEmpty) return;
    AppFeedback.medium();
    setState(() {
      _isAnalyzing = true;
      _queryController.text = text;
    });

    final res = await AiServiceRecommendationEngine.instance.analyzeQuery(text);

    if (!mounted) return;
    setState(() {
      _result = res;
      _isAnalyzing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.brandOrange.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandOrange.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Asistente IA Web
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.brandOrangeVibrant, AppColors.brandOrange],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandOrange.withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Asistente Inteligente MyWorks Web',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.white : AppColors.brandNavy,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.brandNavy,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: const Text(
                            'IA WEB 2.0',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Describe en palabras sencillas lo que necesitas y el motor calculará el presupuesto y profesional ideal sin fotos.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? AppColors.grayLight : AppColors.grayMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Campo de Entrada de Palabras Clave
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queryController,
                  onSubmitted: _analyze,
                  decoration: InputDecoration(
                    hintText: 'Ej: "Tengo una filtración de agua en la llave de la cocina..."',
                    prefixIcon: const Icon(Icons.psychology_rounded, color: AppColors.brandOrange),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDarkElevated : AppColors.grayBackground,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              PrimaryButton(
                label: 'Evaluar con IA',
                isLoading: _isAnalyzing,
                width: 160,
                onPressed: () => _analyze(_queryController.text),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Chips de Solicitudes Rápidas
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickPrompts.map((prompt) {
              return ActionChip(
                label: Text(prompt, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                backgroundColor: isDark ? AppColors.surfaceDarkElevated : AppColors.brandOrangeSoft,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                onPressed: () => _analyze(prompt.substring(3)),
              );
            }).toList(),
          ),

          // Resultado del Análisis Semántico por la IA
          if (_result != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDarkElevated : AppColors.grayBackground.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Diagnóstico IA: ${_result!.categoryName}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.brandOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          _result!.urgencyLevel,
                          style: const TextStyle(color: AppColors.brandOrange, fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Problema Detectado: ${_result!.detectedProblem}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Presupuesto Estimado: ${currencyFormatter.format(_result!.minPriceEstimate)} - ${currencyFormatter.format(_result!.maxPriceEstimate)} CLP',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.emerald),
                  ),
                  const SizedBox(height: 14),

                  // Lista de Profesionales Recomendados
                  const Text('Profesionales Destacados Recomendados:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  if (_result!.recommendedWorkers.isEmpty)
                    const Text('Buscando profesionales disponibles para esta especialidad...')
                  else
                    Column(
                      children: _result!.recommendedWorkers.map((w) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: WorkerCard(
                            name: 'Profesional Verificado',
                            profession: _result!.categoryName,
                            rating: w.rating,
                            avatarUrl: null,
                            onTap: () => context.push('/user/worker-detail/${w.userId}'),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
