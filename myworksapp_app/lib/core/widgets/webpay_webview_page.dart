import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_colors.dart';

/// WebView in-app para Webpay: el usuario no sale a Chrome/Safari externo.
class WebpayWebViewPage extends StatefulWidget {
  const WebpayWebViewPage({
    super.key,
    required this.paymentUrl,
    this.title = 'Pago Webpay',
  });

  final String paymentUrl;
  final String title;

  /// Abre la URL de handoff y espera retorno (deep link o post-commit).
  static Future<bool> open(BuildContext context, {required String paymentUrl}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => WebpayWebViewPage(paymentUrl: paymentUrl),
      ),
    );
    return result == true;
  }

  @override
  State<WebpayWebViewPage> createState() => _WebpayWebViewPageState();
}

class _WebpayWebViewPageState extends State<WebpayWebViewPage> {
  late final WebViewController _controller;
  var _loading = true;

  bool _isReturnUrl(String url) {
    final lower = url.toLowerCase();
    return lower.startsWith('myworksapp://pago') ||
        lower.contains('pago=ok') ||
        lower.contains('pago=fail') ||
        lower.contains('pago=retorno') ||
        lower.contains('/pago/retorno');
  }

  bool _isApprovedReturn(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('ok=0') || lower.contains('pago=fail')) return false;
    if (lower.contains('ok=1') || lower.contains('pago=ok')) return true;
    // Commit HTML embebido: tratamos llegada al commit como pendiente de mensaje;
    // si la URL es app return sin ok, asumimos éxito solo con ok=1.
    return lower.contains('pago=retorno');
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            final url = request.url;
            if (_isReturnUrl(url)) {
              final ok = _isApprovedReturn(url);
              if (mounted) Navigator.of(context).pop(ok);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onUrlChange: (change) {
            final url = change.url;
            if (url == null) return;
            if (_isReturnUrl(url)) {
              final ok = _isApprovedReturn(url);
              if (mounted) Navigator.of(context).pop(ok);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.brandNavy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Cancelar',
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const LinearProgressIndicator(
              minHeight: 3,
              color: AppColors.brandOrange,
            ),
        ],
      ),
    );
  }
}
