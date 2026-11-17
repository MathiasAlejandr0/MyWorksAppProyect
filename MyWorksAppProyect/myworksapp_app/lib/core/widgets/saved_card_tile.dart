import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/service_providers.dart';
import '../theme/app_colors.dart';
import '../utils/app_error.dart';

/// Muestra la tarjeta guardada del cliente y deja cambiarla por otra.
/// Si todavía no hay tarjeta, no pinta nada.
class SavedCardTile extends ConsumerStatefulWidget {
  const SavedCardTile({
    super.key,
    required this.onCardRemoved,
    this.enabled = true,
  });

  /// Se llama cuando el cliente quitó su tarjeta: la pantalla abre la inscripción de otra.
  final Future<void> Function() onCardRemoved;
  final bool enabled;

  @override
  ConsumerState<SavedCardTile> createState() => _SavedCardTileState();
}

class _SavedCardTileState extends ConsumerState<SavedCardTile> {
  String? _label;
  bool _removing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final card = await ref.read(paymentServiceProvider).savedCard();
      if (!mounted) return;
      setState(() {
        _label = card.enrolled
            ? '${card.cardType.isEmpty ? 'Tarjeta' : card.cardType} •••• ${card.last4}'
            : null;
      });
    } catch (_) {
      // Sin saber si hay tarjeta guardada, el cobro decide al confirmar.
    }
  }

  Future<void> _change() async {
    setState(() => _removing = true);
    try {
      await ref.read(paymentServiceProvider).removeSavedCard();
      if (!mounted) return;
      setState(() => _label = null);
      await widget.onCardRemoved();
      if (mounted) await _load();
    } catch (e) {
      if (!mounted) return;
      final message = e is AppError ? e.message : 'No se pudo quitar la tarjeta';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _removing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _label;
    if (label == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.credit_card, size: 18, color: AppColors.brandNavy),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Se cobrará a tu tarjeta guardada: $label',
              key: const Key('saved-card-label'),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: widget.enabled && !_removing ? _change : null,
            child: Text(_removing ? 'Quitando…' : 'Cambiar tarjeta'),
          ),
        ],
      ),
    );
  }
}
