import 'dart:core';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:doctro_patient/Paypal/PaypalServices.dart';
import 'package:doctro_patient/const/Palette.dart';
import 'package:flutter/material.dart';
import 'package:doctro_patient/Chat/loading_view.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaypalPayment extends StatefulWidget {
  final Function? onFinish;
  final String? total;

  const PaypalPayment({Key? key, this.onFinish, this.total}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return PaypalPaymentState();
  }
}

class PaypalPaymentState extends State<PaypalPayment> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? checkoutUrl;
  String? paymentId;
  PaypalServices services = PaypalServices();

  String returnURL = 'https://return.example.com';
  String cancelURL = 'https://cancel.example.com';
  String? totalAmount = '';

  void getToken() async {
    Future.delayed(
      const Duration(seconds: 1),
      () async {
        try {
          final res = await services.createPaypalPayment(total: totalAmount ?? '', returnUrl: returnURL, cancelUrl: cancelURL);
          setState(() {
            checkoutUrl = res["approvalUrl"];
            paymentId = res["paymentId"];
            late final PlatformWebViewControllerCreationParams params;
            if (WebViewPlatform.instance is WebKitWebViewPlatform) {
              params = WebKitWebViewControllerCreationParams(
                allowsInlineMediaPlayback: true,
                mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
              );
            } else {
              params = const PlatformWebViewControllerCreationParams();
            }
            final WebViewController controller = WebViewController.fromPlatformCreationParams(params);
            controller
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..loadRequest(Uri.parse(checkoutUrl!))
              ..setNavigationDelegate(
                NavigationDelegate(
                  onProgress: (int) {
                    print(int);
                  },
                  onPageFinished: (String url) {},
                  onNavigationRequest: (NavigationRequest request) {
                    if (request.url.contains(returnURL)) {
                      final uri = Uri.parse(request.url);
                      final payerID = uri.queryParameters['PayerID'];
                      if (payerID != null) {
                        services.executePayment(paymentId!, payerID).then((id) {
                          widget.onFinish!(id);
                        }).catchError((e) {
                          print('exception:  $e');
                        });
                      }
                      Navigator.of(context).pop();
                      return NavigationDecision.prevent;
                    }
                    if (request.url.contains(cancelURL)) {
                      Navigator.of(context).pop();
                      return NavigationDecision.prevent;
                    }
                    return NavigationDecision.navigate;
                  },
                ),
              );
            _controller = controller;
          });
        } catch (e) {
          print('exception:  $e');
          Navigator.pop(context);
        }
      },
    );
  }

  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    totalAmount = widget.total;
    getToken();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: checkoutUrl != null
          ? WebViewWidget(
              controller: _controller!,
            )
          : const Center(
              child: SpinKitPulse(color: Palette.blue),
            ),
    );
  }
}
