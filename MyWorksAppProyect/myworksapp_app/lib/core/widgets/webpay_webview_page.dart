import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../theme/app_colors.dart';
import '../utils/webpay_webview_return.dart';

/// Chrome móvil, sin la marca `wv`. Transbank deja el botón de continuar
/// muerto cuando reconoce el WebView del sistema.
const _transbankUserAgent =
    'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36';

/// WebView in-app para Webpay: el usuario no sale a Chrome/Safari externo.
class WebpayWebViewPage extends StatefulWidget {
  const WebpayWebViewPage({
    super.key,
    this.paymentUrl,
    this.html,
    this.title = 'Pago Webpay',
    this.watchOutcome,
  });

  final String? paymentUrl;
  final String? html;
  final String title;

  /// null mientras Transbank no termina. true = cobro o tarjeta lista.
  /// false = Transbank rechazó o anuló.
  final Future<bool?> Function()? watchOutcome;

  /// Abre la URL de handoff, o un HTML propio que hace POST a Transbank.
  static Future<bool> open(
    BuildContext context, {
    String? paymentUrl,
    String? html,
    String title = 'Pago Webpay',
    Future<bool?> Function()? watchOutcome,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => WebpayWebViewPage(
          paymentUrl: paymentUrl,
          html: html,
          title: title,
          watchOutcome: watchOutcome,
        ),
      ),
    );
    return result == true;
  }

  @override
  State<WebpayWebViewPage> createState() => _WebpayWebViewPageState();
}

class _WebpayWebViewPageState extends State<WebpayWebViewPage> {
  late final WebViewController _controller;
  Timer? _watch;
  var _loading = true;
  var _closed = false;

  void _finish(bool ok) {
    if (_closed || !mounted) return;
    _closed = true;
    _watch?.cancel();
    Navigator.of(context).pop(ok);
  }

  void _onUrl(String? url) {
    if (url == null || url.isEmpty || !isWebpayReturnUrl(url)) return;
    _finish(isApprovedWebpayReturn(url));
  }

  void _startWatch() {
    final watch = widget.watchOutcome;
    if (watch == null) return;
    _watch = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_closed) return;
      try {
        final outcome = await watch();
        if (outcome == null || _closed) return;
        _finish(outcome);
      } catch (_) {}
    });
  }

  Future<void> _allowTransbankCookies() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final platform = _controller.platform;
    if (platform is! AndroidWebViewController) return;
    final cookies = AndroidWebViewCookieManager(
      const PlatformWebViewCookieManagerCreationParams(),
    );
    await cookies.setAcceptThirdPartyCookies(platform, true);
  }

  Future<void> _loadCheckout() async {
    try {
      await _allowTransbankCookies();
    } catch (_) {}
    if (!mounted || _closed) return;
    final html = widget.html;
    if (html != null && html.isNotEmpty) {
      await _controller.loadHtmlString(
        html,
        baseUrl: 'https://webpay3gint.transbank.cl/',
      );
      return;
    }
    final url = widget.paymentUrl ?? '';
    if (url.isEmpty) return;
    await _controller.loadRequest(Uri.parse(url));
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(_transbankUserAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _loading = false);
            _onUrl(url);
          },
          onNavigationRequest: (request) {
            final url = request.url;
            if (isWebpayReturnUrl(url)) {
              _finish(isApprovedWebpayReturn(url));
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onUrlChange: (change) => _onUrl(change.url),
          onWebResourceError: (error) {
            if (error.isForMainFrame == false) return;
            _onUrl(error.url);
          },
        ),
      );
    _startWatch();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadCheckout();
    });
  }

  @override
  void dispose() {
    _watch?.cancel();
    super.dispose();
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
            onPressed: () => _finish(false),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: Stack(
        children: [
          _checkoutView(),
          if (_loading)
            const LinearProgressIndicator(
              minHeight: 3,
              color: AppColors.brandOrange,
            ),
        ],
      ),
    );
  }

  /// En Android el mapa de textura se come el toque del botón «Continuar»
  /// en varios Redmi. Hybrid composition entrega el toque al WebView.
  Widget _checkoutView() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return WebViewWidget.fromPlatformCreationParams(
        params: AndroidWebViewWidgetCreationParams(
          controller: _controller.platform,
          displayWithHybridComposition: true,
          gestureRecognizers: {
            Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
          },
        ),
      );
    }
    return WebViewWidget(controller: _controller);
  }
}
