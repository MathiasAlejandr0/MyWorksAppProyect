import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';

const _sectionHeader = Color(0xFF2B3038);

/// Sección del perfil del trabajador: resumen cerrado y edición aparte.
class WorkerProfileSectionCard extends StatelessWidget {
  const WorkerProfileSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.summary,
    required this.editing,
    required this.onEdit,
    this.onCancel,
    this.onSave,
    this.saving = false,
    this.child,
    this.alwaysShowBody = false,
    this.showSaveActions = true,
    this.saveLabel = 'Guardar',
  });

  final IconData icon;
  final String title;
  final List<String> summary;
  final bool editing;
  final VoidCallback onEdit;
  final VoidCallback? onCancel;
  final VoidCallback? onSave;
  final bool saving;
  final Widget? child;
  final bool alwaysShowBody;
  final bool showSaveActions;
  final String saveLabel;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.onCanvasMuted(Theme.of(context).brightness);
    final showBody = child != null && (editing || alwaysShowBody);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: AppDecorations.surfaceCardOf(
        context,
        accent: AppColors.brandOrange,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              color: _sectionHeader,
              border: Border(
                bottom: BorderSide(color: Color(0x73FF5E03)),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.brandOrange,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (!editing)
                    TextButton(
                      onPressed: onEdit,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.brandOrange,
                      ),
                      child: const Text('Editar'),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!editing && summary.isNotEmpty)
                  for (var i = 0; i < summary.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        summary[i],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: i == 0 ? null : muted,
                          fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ),
                if (showBody) ...[
                  if (!editing && summary.isNotEmpty) const SizedBox(height: 10),
                  child!,
                ],
                if (editing && showSaveActions) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: saving ? null : onCancel,
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: saving ? null : onSave,
                          child: Text(saving ? 'Guardando…' : saveLabel),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
