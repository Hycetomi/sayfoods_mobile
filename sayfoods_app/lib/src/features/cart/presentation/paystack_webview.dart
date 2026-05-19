import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaystackWebView extends StatefulWidget {
  final String authorizationUrl;
  final String reference;

  const PaystackWebView({
    super.key,
    required this.authorizationUrl,
    required this.reference,
  });

  @override
  State<PaystackWebView> createState() => _PaystackWebViewState();
}

class _PaystackWebViewState extends State<PaystackWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _resultSent = false;

  // URL we passed as callback_url to Paystack — it redirects here on success
  // with ?reference=xxx&trxref=xxx appended.
  static const _successHost = 'sayfoods.app';
  static const _successPath = '/checkout/success';

  // Paystack also redirects here if no callback_url is found (fallback)
  static const _closeUrl = 'standard.paystack.co/close';

  @override
  void initState() {
    super.initState();
    debugPrint('[PAYSTACK_WV] 🚀 Loading URL: ${widget.authorizationUrl}');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('[PAYSTACK_WV] onPageStarted: $url');
            _checkUrl(url);
          },
          onPageFinished: (url) {
            debugPrint('[PAYSTACK_WV] onPageFinished: $url');
            if (mounted) setState(() => _isLoading = false);
            _checkUrl(url);
          },
          onNavigationRequest: (request) {
            debugPrint('[PAYSTACK_WV] onNavigationRequest: ${request.url}');
            _checkUrl(request.url);
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) =>
              debugPrint('[PAYSTACK_WV] ❌ WebResourceError: ${error.description}  code: ${error.errorCode}'),
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  void _checkUrl(String url) {
    if (_resultSent) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final isSuccessCallback =
        uri.host == _successHost && uri.path == _successPath;
    final isCloseUrl = url.contains(_closeUrl);

    debugPrint('[PAYSTACK_WV] _checkUrl: host=${uri.host}  path=${uri.path}  isSuccess=$isSuccessCallback  isClose=$isCloseUrl');

    if (isSuccessCallback || isCloseUrl) {
      // Prefer the reference from the query param; fall back to the one we passed in
      final ref = uri.queryParameters['reference'] ??
          uri.queryParameters['trxref'] ??
          widget.reference;
      debugPrint('[PAYSTACK_WV] ✅ Payment complete — reference: $ref');
      _resultSent = true;
      if (mounted) Navigator.of(context).pop({'status': 'success', 'reference': ref});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            debugPrint('[PAYSTACK_WV] User closed WebView manually');
            if (!_resultSent) {
              _resultSent = true;
              Navigator.of(context).pop({'status': 'cancelled', 'reference': ''});
            }
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
