import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/service_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_error.dart';
import '../../../../core/widgets/webpay_webview_page.dart';

/// Primera entrada del cliente: guarda la tarjeta una vez.
/// Esa tarjeta se usa en la app y también al iniciar sesión en la web.
class CardEnrollmentPage extends ConsumerStatefulWidget {
  const CardEnrollmentPage({super.key});

  static Future<bool> open(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const CardEnrollmentPage(),
      ),
    );
    return result == true;
  }

  @override
  ConsumerState<CardEnrollmentPage> createState() => _CardEnrollmentPageState();
}

class _CardEnrollmentPageState extends ConsumerState<CardEnrollmentPage> {
  bool _busy = false;
  String? _error;

  Future<void> _enroll() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final handoff = await ref.read(paymentServiceProvider).startCardEnrollment();
      if (!mounted) return;
      if (handoff.isEmpty) {
        Navigator.of(context).pop(true);
        return;
      }
      final ok = await WebpayWebViewPage.open(
        context,
        paymentUrl: handoff,
        title: 'Inscribir tarjeta',
      );
      if (!mounted) return;
      if (!ok) {
        setState(() => _error = 'No se guardó la tarjeta. Puedes intentarlo de nuevo.');
        return;
      }
      Navigator.of(context).pop(true);
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo inscribir la tarjeta');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarjeta para tus pedidos'),
        backgroundColor: AppColors.brandNavy,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Inscribe tu tarjeta una vez',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          const Text(
            'En la app el registro es obligatorio. La primera vez guardamos tu tarjeta en Transbank. Después, cada pedido se cobra solo, también si inicias sesión en la página web.',
          ),
          const SizedBox(height: 8),
          const Text(
            'Sin cuenta, la página web te envía a Webpay para pagar ese pedido.',
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _enroll,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandOrange,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(_busy ? 'Conectando…' : 'Inscribir tarjeta'),
          ),
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
            child: const Text('Ahora no'),
          ),
        ],
      ),
    );
  }
}
