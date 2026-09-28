import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/webpay_transaction.dart';
import '../../../../core/providers/service_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Confirma `token_ws` y muestra el resultado del escrow.
class PaymentResultScreen extends ConsumerStatefulWidget {
  const PaymentResultScreen({
    super.key,
    required this.token,
  });

  final String token;

  @override
  ConsumerState<PaymentResultScreen> createState() =>
      _PaymentResultScreenState();
}

class _PaymentResultScreenState extends ConsumerState<PaymentResultScreen> {
  late Future<WebpayCommitResult> _result;

  @override
  void initState() {
    super.initState();
    _result = _confirm();
  }

  Future<WebpayCommitResult> _confirm() async {
    final token = widget.token.trim();
    if (token.isEmpty) {
      return const WebpayCommitResult(
        approved: false,
        paymentStatus: 'REJECTED',
        message: 'No llegó token_ws desde Webpay',
      );
    }

    final commit = await ref
        .read(paymentServiceProvider)
        .confirmWebpayPayment(token: token);

    if (commit.approved && mounted) {
      final user = ref.read(authProvider).user;
      final jobId = commit.jobId;
      if (user != null && jobId != null && jobId.isNotEmpty) {
        try {
          await ref.read(jobBookingServiceProvider).confirmEscrowAndAccept(
                jobId: jobId,
                userId: user.id,
              );
        } on AppError {
          // La Edge Function ya dejó el trabajo en aceptado.
        }
      }
    }
    return commit;
  }

  void _goToHistory() {
    context.go(AppConstants.routeJobHistory);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebpayCommitResult>(
      future: _result,
      builder: (context, snapshot) {
        final approved = snapshot.data?.approved == true;
        return PopScope(
          canPop: !approved,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop || !approved) return;
            _goToHistory();
          },
          child: Scaffold(
            appBar: const AppGradientAppBar(
              title: Text('Resultado del pago'),
            ),
            body: _buildBody(snapshot),
          ),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<WebpayCommitResult> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Confirmando pago con Webpay…'),
          ],
        ),
      );
    }

    if (snapshot.hasError) {
      final error = snapshot.error;
      final message =
          error is AppError ? error.message : 'No se pudo confirmar el pago';
      return _ResultBody(
        approved: false,
        title: 'Rechazado',
        message: message,
        onHistory: _goToHistory,
      );
    }

    final result = snapshot.data!;
    if (result.approved) {
      return _ResultBody(
        approved: true,
        title: 'Pago retenido en garantía',
        message:
            'El cobro fue aprobado y los fondos quedan en escrow hasta que el especialista ejecute el servicio.',
        onHistory: _goToHistory,
      );
    }

    return _ResultBody(
      approved: false,
      title: 'Rechazado',
      message: result.message ??
          'Transbank no autorizó el pago. Puedes intentarlo de nuevo desde el trabajo.',
      onHistory: _goToHistory,
    );
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({
    required this.approved,
    required this.title,
    required this.message,
    required this.onHistory,
  });

  final bool approved;
  final String title;
  final String message;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final color = approved ? AppColors.success : AppColors.error;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Icon(
            approved ? Icons.verified_user_outlined : Icons.cancel_outlined,
            size: 72,
            color: color,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          FilledButton(
            onPressed: onHistory,
            style: FilledButton.styleFrom(
              backgroundColor: approved ? AppColors.success : AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Volver al historial de trabajos'),
          ),
        ],
      ),
    );
  }
}
