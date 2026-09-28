import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/service_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_error.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import 'card_enrollment_page.dart';

/// Resumen de la orden y arranque del pago Webpay Plus.
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({
    super.key,
    required this.jobId,
    required this.amount,
    this.serviceName,
    this.specialistName,
  });

  final String jobId;
  final double amount;
  final String? serviceName;
  final String? specialistName;

  static Future<bool> open(
    BuildContext context, {
    required String jobId,
    required double amount,
    String? serviceName,
    String? specialistName,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          jobId: jobId,
          amount: amount,
          serviceName: serviceName,
          specialistName: specialistName,
        ),
      ),
    );
    return result == true;
  }

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _processing = false;
  String? _error;

  String get _amountLabel => NumberFormat.currency(
        locale: 'es_CL',
        symbol: r'$',
        decimalDigits: 0,
      ).format(widget.amount.round());

  Future<void> _pay() async {
    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      final charge = await ref.read(paymentServiceProvider).chargeSavedCard(
            jobId: widget.jobId,
            amount: widget.amount,
          );
      if (!mounted) return;

      if (charge.charged) {
        Navigator.of(context).pop(true);
        return;
      }

      if (kIsWeb) {
        setState(() {
          _error =
              'Inscribe la tarjeta al entrar a la app. Con esa tarjeta se cobra el pedido.';
        });
        return;
      }

      final enrolled = await CardEnrollmentPage.open(context);
      if (!mounted) return;
      if (!enrolled) {
        setState(() => _error = 'Inscribe la tarjeta para confirmar el pedido.');
        return;
      }

      final again = await ref.read(paymentServiceProvider).chargeSavedCard(
            jobId: widget.jobId,
            amount: widget.amount,
          );
      if (!mounted) return;
      if (!again.charged) {
        setState(() => _error = 'La tarjeta no quedó lista para este cobro.');
        return;
      }
      Navigator.of(context).pop(true);
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo iniciar el pago');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.serviceName?.trim();
    final specialist = widget.specialistName?.trim();

    return Scaffold(
      appBar: const AppGradientAppBar(
        title: Text('Confirmar pedido'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Resumen de la orden',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Servicio',
            value: (service == null || service.isEmpty) ? 'Servicio' : service,
          ),
          _SummaryRow(
            label: 'Especialista',
            value: (specialist == null || specialist.isEmpty)
                ? 'Por asignar'
                : specialist,
          ),
          _SummaryRow(label: 'Monto', value: _amountLabel),
          const SizedBox(height: 16),
          Material(
            color: AppColors.brandOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, size: 18, color: AppColors.brandOrange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Al confirmar se descuenta el monto de tu tarjeta y vuelves al pedido. Si aún no la inscribiste, Transbank la pide una sola vez en la app.',
                      style: TextStyle(fontSize: 13, color: AppColors.brandOrange),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _processing ? null : _pay,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandOrange,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: _processing
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.credit_card),
            label: Text(_processing ? 'Confirmando…' : 'Confirmar pedido'),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
