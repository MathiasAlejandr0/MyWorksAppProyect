import 'package:flutter/material.dart';

import '../../../../core/database/models/service_model.dart';
import '../../../../core/domain/pricing_mode_recommendation.dart';
import '../../../../core/services/pricing_mode_questionnaire_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';

/// Textos del cuestionario adaptados al oficio (categoría del servicio).
class _TradeCopy {
  const _TradeCopy({
    required this.repair,
    required this.hours,
    required this.project,
    required this.diagnosis,
  });

  final String repair;
  final String hours;
  final String project;
  final String diagnosis;

  static const _TradeCopy generic = _TradeCopy(
    repair: 'Ej: grifo, cerradura, enchufe, luminaria',
    hours: 'Ej: limpieza profunda, pintura, armado, jardinería',
    project: 'Ej: construir, ampliar, remodelar integralmente',
    diagnosis: 'El profesional revisa tu pedido y te envía una cotización',
  );

  static _TradeCopy forCategory(String? category) {
    switch (category) {
      case ServiceCategories.construction:
        return const _TradeCopy(
          repair: 'Ej: sellar filtración, resanar muro, fijar cerámica',
          hours: 'Ej: pintura, tabique, enchape, terminaciones',
          project: 'Ej: ampliación, remodelación, radier, obra gruesa',
          diagnosis: 'El maestro evalúa la obra y te envía una propuesta',
        );
      case ServiceCategories.plumbing:
        return const _TradeCopy(
          repair: 'Ej: grifo que gotea, sifón, flotador del WC',
          hours: 'Ej: cambio de cañerías, instalar artefactos',
          project: 'Ej: red de agua nueva, remodelación de baño',
          diagnosis: 'El gásfiter evalúa la falla y te envía una propuesta',
        );
      case ServiceCategories.electrical:
        return const _TradeCopy(
          repair: 'Ej: enchufe, interruptor, luminaria, automático',
          hours: 'Ej: revisar tablero, varios puntos eléctricos',
          project: 'Ej: cableado completo, tablero nuevo, ampliación',
          diagnosis: 'El electricista evalúa el problema y te cotiza',
        );
      case ServiceCategories.gardening:
        return const _TradeCopy(
          repair: 'Ej: cortar una rama, reparar un aspersor',
          hours: 'Ej: poda, corte de césped, limpieza de jardín',
          project: 'Ej: diseño de jardín, riego automático, paisajismo',
          diagnosis: 'El jardinero evalúa el terreno y te envía una propuesta',
        );
      case ServiceCategories.cleaning:
        return const _TradeCopy(
          repair: 'Ej: limpiar un ambiente puntual o vidrios',
          hours: 'Ej: limpieza profunda, post-obra, fin de mudanza',
          project: 'Ej: plan de limpieza periódica para varias áreas',
          diagnosis: 'Evaluamos el espacio y te enviamos una propuesta',
        );
      case ServiceCategories.assembly:
        return const _TradeCopy(
          repair: 'Ej: ajustar bisagra, fijar repisa, nivelar puerta',
          hours: 'Ej: armar clóset, cama, escritorio o estantería',
          project: 'Ej: amoblar varios ambientes o mobiliario a medida',
          diagnosis: 'El profesional revisa el mueble y te cotiza el armado',
        );
      case ServiceCategories.techSupport:
        return const _TradeCopy(
          repair: 'Ej: configurar impresora, quitar virus, instalar app',
          hours: 'Ej: formateo, respaldo, optimización del equipo',
          project: 'Ej: armar una red, varios equipos, oficina completa',
          diagnosis: 'El técnico revisa el equipo y te envía una propuesta',
        );
      case ServiceCategories.moving:
        return const _TradeCopy(
          repair: 'Ej: trasladar un mueble o pocos bultos',
          hours: 'Ej: mudanza de departamento cobrada por horas',
          project: 'Ej: mudanza de casa completa con embalaje',
          diagnosis: 'Evaluamos la mudanza y te enviamos una propuesta',
        );
      default:
        return generic;
    }
  }
}

/// Cuestionario para recomendar modalidad de cobro (sin elegir manualmente).
class PricingModeQuestionnaire extends StatefulWidget {
  const PricingModeQuestionnaire({
    super.key,
    required this.workerPreselected,
    required this.onRecommendation,
    this.category,
    this.initialRecommendation,
  });

  final bool workerPreselected;
  final String? category;
  final ValueChanged<PricingModeRecommendation> onRecommendation;
  final PricingModeRecommendation? initialRecommendation;

  @override
  State<PricingModeQuestionnaire> createState() => _PricingModeQuestionnaireState();
}

class _PricingModeQuestionnaireState extends State<PricingModeQuestionnaire> {
  final _service = PricingModeQuestionnaireService.instance;

  int _step = 0;
  String? _jobType;
  String? _repairType;
  int? _blockHours;
  PricingModeRecommendation? _result;

  @override
  void initState() {
    super.initState();
    _result = widget.initialRecommendation;
    if (_result != null) {
      _step = 2;
      _jobType = _result!.questionnaireAnswers['job_type'] as String?;
      _repairType = _result!.questionnaireAnswers['repair_type'] as String?;
      _blockHours = _result!.blockHours;
    }
  }

  void _pickJobType(String type) {
    setState(() {
      _jobType = type;
      _repairType = null;
      _blockHours = null;
      _result = null;
      if (type == PricingModeQuestionnaireService.jobRepair ||
          type == PricingModeQuestionnaireService.jobByHours) {
        _step = 1;
      } else {
        _finalize();
      }
    });
  }

  void _pickRepair(String type) {
    setState(() => _repairType = type);
    _finalize();
  }

  void _pickHours(int hours) {
    setState(() => _blockHours = hours);
    _finalize();
  }

  void _finalize() {
    final rec = _service.recommend(
      jobType: _jobType!,
      repairType: _repairType,
      blockHours: _blockHours,
      workerPreselected: widget.workerPreselected,
    );
    setState(() {
      _result = rec;
      _step = 2;
    });
    widget.onRecommendation(rec);
  }

  void _restart() {
    setState(() {
      _step = 0;
      _jobType = null;
      _repairType = null;
      _blockHours = null;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '¿Qué trabajo necesitas?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          _intro(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.grayMedium,
              ),
        ),
        const SizedBox(height: 12),
        if (_step == 0) _buildJobTypeStep(context),
        if (_step == 1 && _jobType == PricingModeQuestionnaireService.jobRepair)
          _buildRepairStep(context),
        if (_step == 1 && _jobType == PricingModeQuestionnaireService.jobByHours)
          _buildHoursStep(context),
        if (_step == 2 && _result != null) _buildResult(context, _result!),
      ],
    );
  }

  String _intro() {
    final label = _categoryLabel(widget.category);
    if (label == null) {
      return 'Respondemos unas preguntas para definir la forma de cobro que te conviene.';
    }
    return 'Cuéntanos el tipo de trabajo de $label y definimos la mejor forma de cobro.';
  }

  String? _categoryLabel(String? category) {
    switch (category) {
      case ServiceCategories.construction:
        return 'construcción';
      case ServiceCategories.plumbing:
        return 'plomería';
      case ServiceCategories.electrical:
        return 'electricidad';
      case ServiceCategories.gardening:
        return 'jardinería';
      case ServiceCategories.cleaning:
        return 'limpieza';
      case ServiceCategories.assembly:
        return 'armado de muebles';
      case ServiceCategories.techSupport:
        return 'soporte técnico';
      case ServiceCategories.moving:
        return 'mudanza';
      default:
        return null;
    }
  }

  Widget _buildJobTypeStep(BuildContext context) {
    final copy = _TradeCopy.forCategory(widget.category);
    return Column(
      children: [
        _option(
          context,
          title: 'Reparar o cambiar algo puntual',
          subtitle: copy.repair,
          icon: Icons.build_outlined,
          onTap: () => _pickJobType(PricingModeQuestionnaireService.jobRepair),
        ),
        _option(
          context,
          title: 'Trabajo que toma varias horas',
          subtitle: copy.hours,
          icon: Icons.schedule_outlined,
          onTap: () => _pickJobType(PricingModeQuestionnaireService.jobByHours),
        ),
        _option(
          context,
          title: 'Proyecto grande o por etapas',
          subtitle: copy.project,
          icon: Icons.architecture_outlined,
          onTap: () => _pickJobType(PricingModeQuestionnaireService.jobMajorProject),
        ),
        _option(
          context,
          title: 'No estoy seguro / quiero que lo evalúen',
          subtitle: copy.diagnosis,
          icon: Icons.search_outlined,
          onTap: () => _pickJobType(PricingModeQuestionnaireService.jobDiagnosis),
        ),
      ],
    );
  }

  Widget _buildRepairStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '¿Qué necesitas reparar o instalar?',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        _option(
          context,
          title: 'Grifo, lavatorio o sanitario',
          icon: Icons.water_drop_outlined,
          onTap: () => _pickRepair(PricingModeQuestionnaireService.repairFaucet),
        ),
        _option(
          context,
          title: 'Cerradura o llaves',
          icon: Icons.lock_outline,
          onTap: () => _pickRepair(PricingModeQuestionnaireService.repairLock),
        ),
        _option(
          context,
          title: 'Calefón o termo',
          icon: Icons.hot_tub_outlined,
          onTap: () => _pickRepair(PricingModeQuestionnaireService.repairWaterHeater),
        ),
        _option(
          context,
          title: 'Electricidad puntual',
          subtitle: 'Enchufe, interruptor, luminaria, tablero pequeño',
          icon: Icons.electrical_services_outlined,
          onTap: () => _pickRepair(PricingModeQuestionnaireService.repairElectrical),
        ),
        _option(
          context,
          title: 'Otra reparación acotada',
          icon: Icons.handyman_outlined,
          onTap: () => _pickRepair(PricingModeQuestionnaireService.repairOther),
        ),
        TextButton(
          onPressed: () => setState(() => _step = 0),
          child: const Text('Volver'),
        ),
      ],
    );
  }

  Widget _buildHoursStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '¿Cuántas horas estimas que tomará?',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _hourChip(PricingModeQuestionnaireService.hours2, '2 h'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _hourChip(PricingModeQuestionnaireService.hours4, '4 h'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _hourChip(PricingModeQuestionnaireService.hours8, '8 h'),
            ),
          ],
        ),
        TextButton(
          onPressed: () => setState(() => _step = 0),
          child: const Text('Volver'),
        ),
      ],
    );
  }

  Widget _hourChip(int hours, String label) {
    final selected = _blockHours == hours;
    return OutlinedButton(
      onPressed: () => _pickHours(hours),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? AppColors.brandOrangeSoft : null,
        foregroundColor: selected ? AppColors.brandOrange : AppColors.brandNavy,
        side: BorderSide(
          color: selected ? AppColors.brandOrange : AppColors.grayMedium.withValues(alpha: 0.4),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildResult(BuildContext context, PricingModeRecommendation rec) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.surfaceCard(accent: AppColors.brandTeal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.brandTeal, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Te recomendamos: ${rec.title}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            rec.explanation,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _restart,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Responder de nuevo'),
          ),
        ],
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, color: AppColors.brandNavy),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.grayMedium,
                              ),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.grayMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
