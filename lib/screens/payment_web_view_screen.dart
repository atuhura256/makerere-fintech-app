import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:makerere_fintech_app/app/config/app_constants.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String initialUrl;
  final String redirectUrl;

  const PaymentWebViewScreen({
    super.key,
    required this.initialUrl,
    required this.redirectUrl,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  WebViewController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    final controller = WebViewController();
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);

    controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (String url) {
          if (mounted) setState(() => _isLoading = true);
        },
        onPageFinished: (String url) {
          if (mounted) setState(() => _isLoading = false);
        },
        onNavigationRequest: (NavigationRequest request) {
          if (request.url.startsWith(widget.redirectUrl)) {
            Navigator.pop(context, true);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    );

    controller.loadRequest(Uri.parse(widget.initialUrl));
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Settlement Node'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(
        children: [
          if (_controller != null)
            WebViewWidget(controller: _controller!)
          else
            const SizedBox.shrink(),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(strokeWidth: 3, color: AppConstants.emerald),
            ),
        ],
      ),
    );
  }
}