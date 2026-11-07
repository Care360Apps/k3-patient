import 'package:doctro_patient/api/base_model.dart';
import 'package:doctro_patient/const/Palette.dart';
import 'package:doctro_patient/model/detail_setting_model.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:doctro_patient/Chat/loading_view.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import '../../api/retrofit_Api.dart';
import '../../api/network_api.dart';
import '../../api/server_error.dart';
import '../../const/app_string.dart';
import '../../localization/localization_constant.dart';

class PrivacyPolicy extends StatefulWidget {
  @override
  _PrivacyPolicyState createState() => _PrivacyPolicyState();
}

class _PrivacyPolicyState extends State<PrivacyPolicy> {
  bool loading = false;

  String? privacyPolicy = "";

  @override
  void initState() {
    super.initState();
    appAllDetail();
  }

  Future<void> _openPublicPolicy() async {
    // This is the currently published Patient store listing's policy URL.
    // No account token, sensitive information or user identifier is sent.
    final url = Uri.https('medic.care360hms.com', '/privacy-policy');
    bool opened = false;
    try {
      opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      // A visible link is still offered below if the platform launcher fails.
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Open medic.care360hms.com/privacy-policy in your browser.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: Palette.dark_blue,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        backgroundColor: Palette.white,
        title: Text(
          getTranslated(context, AppString.privacyPolicy_title).toString(),
          style: TextStyle(fontSize: 18, color: Palette.dark_blue, fontWeight: FontWeight.bold),
        ),
      ),
      body: ModalProgressHUD(
        inAsyncCall: loading,
        opacity: 0.5,
        progressIndicator: SpinKitFadingCircle(
          color: Palette.blue,
          size: 50.0,
        ),
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: privacyPolicy != null && privacyPolicy!.trim().isNotEmpty
                ? Html(
                    data: privacyPolicy!,
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'The privacy policy could not be loaded. Please try again.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: loading ? null : appAllDetail,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                        TextButton.icon(
                          onPressed: _openPublicPolicy,
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Read public privacy policy'),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<BaseModel<DetailSetting>> appAllDetail() async {
    DetailSetting response;

    setState(() {
      loading = true;
    });
    try {
      response = await RestClient(RetroApi2().dioData2()).settingRequest();
      if (mounted) {
        setState(() {
          loading = false;
          privacyPolicy = response.success == true
              ? response.data?.privacyPolicy
              : null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          loading = false;
          privacyPolicy = null;
        });
      }
      // Never print a healthcare API exception or response body to logs.
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }
}
