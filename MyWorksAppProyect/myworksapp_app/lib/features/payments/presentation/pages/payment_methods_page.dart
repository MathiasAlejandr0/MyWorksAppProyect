import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/service_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_error.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import 'card_enrollment_page.dart';

/// Tarjeta guardada del cliente: verla, reemplazarla o quitarla.
class PaymentMethodsPage extends ConsumerStatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  ConsumerState<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends ConsumerState<PaymentMethodsPage> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String? _cardLabel;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final card = await ref.read(paymentServiceProvider).savedCard();
      if (!mounted) return;
      setState(() {
        _cardLabel = card.enrolled ? savedCardLabel(card.cardType, card.last4) : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is AppError ? e.message : 'No se pudo leer tu tarjeta';
      });
    }
  }

  Future<void> _addAnother() async {
    if (_cardLabel != null) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Agregar otra tarjeta'),
          content: const Text(
            'Solo se guarda una tarjeta para tus pedidos. La nueva reemplaza a la actual. Si sales sin terminarla, te quedas sin tarjeta hasta que inscribas otra.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reemplazar'),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) return;
      setState(() => _busy = true);
      try {
        await ref.read(paymentServiceProvider).removeSavedCard();
      } catch (e) {
        if (!mounted) return;
        setState(() => _busy = false);
        _showError(e is AppError ? e.message : 'No se pudo quitar la tarjeta actual');
        return;
      }
    }
    if (!mounted) return;
    setState(() => _busy = false);
    await CardEnrollmentPage.open(context);
    if (mounted) await _load();
  }

  Future<void> _remove() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar tarjeta'),
        content: const Text(
          'Se quita de tus medios de pago. Los pedidos ya cobrados no cambian.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(paymentServiceProvider).removeSavedCard();
      if (!mounted) return;
      setState(() {
        _cardLabel = null;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError(e is AppError ? e.message : 'No se pudo eliminar la tarjeta');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppGradientAppBar(title: Text('Tus tarjetas')),
      body: PaymentMethodsBody(
        loading: _loading,
        busy: _busy,
        error: _error,
        cardLabel: _cardLabel,
        onRetry: _load,
        onAdd: _addAnother,
        onRemove: _cardLabel == null ? null : _remove,
      ),
    );
  }
}

String savedCardLabel(String cardType, String last4) {
  final type = cardType.trim().isEmpty ? 'Tarjeta' : cardType.trim();
  final digits = last4.trim();
  if (digits.isEmpty) return type;
  return '$type •••• $digits';
}

class PaymentMethodsBody extends StatelessWidget {
  const PaymentMethodsBody({
    super.key,
    required this.loading,
    required this.busy,
    required this.cardLabel,
    required this.onAdd,
    this.onRemove,
    this.onRetry,
    this.error,
  });

  final bool loading;
  final bool busy;
  final String? error;
  final String? cardLabel;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.onCanvasMuted(Theme.of(context).brightness);
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(
          'Medios de pago',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'La tarjeta se usa para cobrar tus pedidos. Puedes quitarla o reemplazarla por otra.',
          style: TextStyle(color: muted, height: 1.35),
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          Text(error!, style: const TextStyle(color: AppColors.error)),
          if (onRetry != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: busy ? null : onRetry, child: const Text('Reintentar')),
            ),
        ],
        const SizedBox(height: 16),
        if (cardLabel == null)
          Text(
            'No tienes una tarjeta guardada.',
            style: TextStyle(color: muted),
          )
        else
          _SavedCardPanel(label: cardLabel!),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: busy ? null : onAdd,
          icon: const Icon(Icons.add_card_outlined),
          label: Text(cardLabel == null ? 'Agregar tarjeta' : 'Agregar otra'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.brandOrange,
            side: const BorderSide(color: AppColors.brandOrange),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        if (onRemove != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy ? null : onRemove,
            icon: const Icon(Icons.delete_outline),
            label: Text(busy ? 'Eliminando…' : 'Eliminar tarjeta'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ],
    );
  }
}

class _SavedCardPanel extends StatelessWidget {
  const _SavedCardPanel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandNavy,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.credit_card, color: AppColors.brandOrange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tarjeta guardada',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
