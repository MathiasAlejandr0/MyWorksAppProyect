// WebViewPlatform falso para pruebas: registra lo que pide la app y deja
// disparar a mano los eventos de navegación (inicio, fin, cambio de URL,
// pedido de navegación y error).
// ignore_for_file: depend_on_referenced_packages
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

class FakeWebViewPlatform extends WebViewPlatform {
  FakeWebViewController? controller;
  FakeNavigationDelegate? delegate;

  /// Instala el falso y lo devuelve.
  static FakeWebViewPlatform install() {
    final p = FakeWebViewPlatform();
    WebViewPlatform.instance = p;
    return p;
  }

  @override
  PlatformWebViewController createPlatformWebViewController(
          PlatformWebViewControllerCreationParams params) =>
      controller = FakeWebViewController(params);

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
          PlatformNavigationDelegateCreationParams params) =>
      delegate = FakeNavigationDelegate(params);

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
          PlatformWebViewWidgetCreationParams params) =>
      FakeWebViewWidget(params);

  @override
  PlatformWebViewCookieManager createPlatformCookieManager(
          PlatformWebViewCookieManagerCreationParams params) =>
      FakeCookieManager(params);
}

class FakeWebViewController extends PlatformWebViewController {
  FakeWebViewController(super.params) : super.implementation();

  final List<String> loaded = [];
  String? userAgent;

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setUserAgent(String? userAgent) async =>
      this.userAgent = userAgent;

  @override
  Future<void> setPlatformNavigationDelegate(
      PlatformNavigationDelegate handler) async {}

  @override
  Future<void> loadRequest(LoadRequestParams params) async =>
      loaded.add(params.uri.toString());

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async =>
      loaded.add('html:$baseUrl');
}

class FakeNavigationDelegate extends PlatformNavigationDelegate {
  FakeNavigationDelegate(super.params) : super.implementation();

  NavigationRequestCallback? onNavigationRequest;
  PageEventCallback? onPageStarted;
  PageEventCallback? onPageFinished;
  UrlChangeCallback? onUrlChange;
  WebResourceErrorCallback? onWebResourceError;

  @override
  Future<void> setOnNavigationRequest(NavigationRequestCallback c) async =>
      onNavigationRequest = c;

  @override
  Future<void> setOnPageStarted(PageEventCallback c) async => onPageStarted = c;

  @override
  Future<void> setOnPageFinished(PageEventCallback c) async =>
      onPageFinished = c;

  @override
  Future<void> setOnUrlChange(UrlChangeCallback c) async => onUrlChange = c;

  @override
  Future<void> setOnWebResourceError(WebResourceErrorCallback c) async =>
      onWebResourceError = c;

  @override
  Future<void> setOnProgress(ProgressCallback c) async {}

  /// Simula un pedido de navegación y devuelve la decisión de la app.
  Future<NavigationDecision> navigate(String url) async =>
      await onNavigationRequest!(
          NavigationRequest(url: url, isMainFrame: true));

  void error(String? url, {bool? mainFrame}) =>
      onWebResourceError!(WebResourceError(
        errorCode: -1,
        description: 'falla simulada',
        isForMainFrame: mainFrame,
        url: url,
      ));
}

class FakeWebViewWidget extends PlatformWebViewWidget {
  FakeWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) =>
      const SizedBox.expand(key: ValueKey('fake-webview'));
}

class FakeCookieManager extends PlatformWebViewCookieManager {
  FakeCookieManager(super.params) : super.implementation();
}
