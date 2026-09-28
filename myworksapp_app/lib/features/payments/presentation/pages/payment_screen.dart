import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/service_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_error.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import '../../../../core/widgets/webpay_webview_page.dart';

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
  bool _openedExternal = false;

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
      final tx = await ref.read(paymentServiceProvider).initiateWebpayPayment(
            jobId: widget.jobId,
            amount: widget.amount,
          );
      if (!mounted) return;

      if (kIsWeb) {
        final target = tx.redirectUrl;
        if (target == null || target.isEmpty) {
          setState(() {
            _error =
                'En web hace falta WEBPAY_HANDOFF_SECRET en Supabase para abrir Webpay.';
          });
          return;
        }
        final launched = await launchUrl(
          Uri.parse(target),
          mode: LaunchMode.externalApplication,
        );
        if (!mounted) return;
        if (!launched) {
          setState(() => _error = 'No se pudo abrir Webpay');
          return;
        }
        setState(() => _openedExternal = true);
        return;
      }

      final target = tx.redirectUrl;
      if (target == null || target.isEmpty) {
        setState(() => _error = 'No se pudo abrir Webpay');
        return;
      }
      final approved = await WebpayWebViewPage.open(
        context,
        paymentUrl: target,
      );
      if (!mounted) return;
      if (!approved) {
        setState(() => _error = 'Pago cancelado o no autorizado');
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
        title: Text('Pago con Webpay'),
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
                      'El monto queda retenido en garantía hasta que el trabajo se ejecute.',
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
            label: Text(_processing ? 'Conectando…' : 'Pagar con Webpay'),
          ),
          if (_openedExternal) ...[
            const SizedBox(height: 12),
            const Text(
              'Completa el pago en Transbank. El resultado vuelve con el token de esa ventana, no se guarda en la app antes de pagar.',
            ),
          ],
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
