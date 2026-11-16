import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../api/apis.dart';
import '../api/retrofit_Api.dart';
import '../const/preference.dart';
import '../const/prefConstatnt.dart';
import 'care360_paystack_client.dart';

class Care360PaystackCheckout {
  static bool _opening = false;

  static Future<String?> start(
    BuildContext context, {
    required num amount,
  }) async {
    if (_opening) return null;
    _opening = true;
    try {
      final currency = SharedPreferenceHelper.getString(
        Preferences.currency_code,
      );
      if (currency == null)
        throw const FormatException('Currency unavailable.');
      final session = await Care360PaystackClient(
        RetroApi().dioData(),
        apiBase: Uri.parse(Apis.baseUrl),
      ).initialize(amount: amount, currency: currency.toUpperCase());
      if (!context.mounted) return null;
      return await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => _PaystackPage(session: session)),
      );
    } catch (_) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open Paystack. Check your connection and try again.',
            ),
          ),
        );
      return null;
    } finally {
      _opening = false;
    }
  }
}

class _PaystackPage extends StatefulWidget {
  const _PaystackPage({required this.session});
  final Care360PaystackSession session;
  @override
  State<_PaystackPage> createState() => _PaystackPageState();
}

class _PaystackPageState extends State<_PaystackPage> {
  late final WebViewController _controller;
  bool _finished = false, _allowPop = false, _asking = false;
  int _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (mounted) setState(() => _progress = value);
          },
          onWebResourceError: (error) {
            if (mounted && error.isForMainFrame == true)
              setState(() => _error = 'Checkout could not load.');
          },
          onNavigationRequest: (request) {
            if (request.isMainFrame &&
                widget.session.matchesReturn(request.url)) {
              _finish(widget.session.reference);
              return NavigationDecision.prevent;
            }
            final uri = Uri.tryParse(request.url);
            return uri != null && uri.scheme == 'https' && uri.userInfo.isEmpty
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(widget.session.checkoutUrl);
  }

  void _finish(String? reference) {
    if (!mounted || _finished) return;
    _finished = true;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(reference);
    });
  }

  Future<void> _close() async {
    if (_asking || _finished) return;
    _asking = true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave checkout?'),
        content: const Text(
          'If you already paid, check your booking or order before trying again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    _asking = false;
    if (leave == true) _finish(null);
  }

  @override
  Widget build(BuildContext context) => PopScope<String>(
    canPop: _allowPop,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _close();
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Pay securely with Paystack'),
        leading: IconButton(
          onPressed: _close,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Leave checkout',
        ),
      ),
      body: Column(
        children: [
          if (_progress < 100) LinearProgressIndicator(value: _progress / 100),
          if (_error != null)
            Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    ),
  );
}
