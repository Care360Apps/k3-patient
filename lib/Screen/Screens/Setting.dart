import 'package:doctro_patient/FirebaseProviders/auth_provider.dart';
import 'package:doctro_patient/Screen/Authentication/SignIn.dart';
import 'package:doctro_patient/api/retrofit_Api.dart';
import 'package:doctro_patient/api/base_model.dart';
import 'package:doctro_patient/api/network_api.dart';
import 'package:doctro_patient/api/server_error.dart';
import 'package:doctro_patient/model/account_delete_model.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:doctro_patient/Chat/loading_view.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import '../../const/prefConstatnt.dart';
import '../../const/preference.dart';
import '../../const/Palette.dart';
import '../../const/app_string.dart';
import '../../localization/localization_constant.dart';

class Setting extends StatefulWidget {
  @override
  _SettingState createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  bool loading = false;

  Future<void> _requestNotifications() async {
    // The OS prompt is shown only after a patient deliberately taps Settings.
    // Notification delivery must never be a condition of logging in or booking.
    try {
      if (!OneSignal.Notifications.permission) {
        await OneSignal.Notifications.requestPermission(true);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(OneSignal.Notifications.permission
            ? 'Appointment notifications are enabled.'
            : 'Notifications are not enabled. You can change this in your phone settings.'),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Notification settings are unavailable right now.'),
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
          getTranslated(context, AppString.setting_title).toString(),
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
          padding: EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true) ...[
                Text(
                  getTranslated(context, AppString.setting_title).toString(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Palette.dark_blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Palette.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Palette.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        key: const Key('patient-enable-notifications'),
                        onTap: _requestNotifications,
                        leading: Icon(Icons.notifications_active_outlined, color: Palette.blue),
                        title: Text('Enable appointment notifications',
                          style: TextStyle(fontSize: 15, color: Palette.dark_blue,
                            fontWeight: FontWeight.w600)),
                        subtitle: const Text('Optional reminders and updates about your care.'),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Palette.dark_grey),
                      ),
                      Divider(height: 1, thickness: 1, color: Palette.dark_white),
                      ListTile(
                        onTap: () {
                          Navigator.pushNamed(context, 'ChangeLanguage');
                        },
                        leading: Icon(Icons.language_outlined, color: Palette.blue),
                        title: Text(
                          getTranslated(context, AppString.setting_changeLanguage).toString(),
                          style: TextStyle(fontSize: 15, color: Palette.dark_blue, fontWeight: FontWeight.w600),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Palette.dark_grey),
                      ),
                      Divider(height: 1, thickness: 1, color: Palette.dark_white),
                      ListTile(
                        onTap: () {
                          Navigator.pushNamed(context, 'ChangePassword');
                        },
                        leading: Icon(Icons.lock_outline, color: Palette.blue),
                        title: Text(
                          getTranslated(context, AppString.setting_changePassword).toString(),
                          style: TextStyle(fontSize: 15, color: Palette.dark_blue, fontWeight: FontWeight.w600),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Palette.dark_grey),
                      ),
                      Divider(height: 1, thickness: 1, color: Palette.dark_white),
                      ListTile(
                        onTap: () {
                          showDeleteAccountDialog(context);
                        },
                        leading: Icon(Icons.delete_outline, color: Palette.red),
                        title: Text(
                          getTranslated(context, AppString.deleteAccount).toString(),
                          style: TextStyle(fontSize: 15, color: Palette.dark_blue, fontWeight: FontWeight.w600),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Palette.dark_grey),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
              ],
              Text(
                getTranslated(context, AppString.setting_general).toString(),
                style: TextStyle(
                  fontSize: 16,
                  color: Palette.dark_blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Palette.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Palette.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      onTap: () {
                        Navigator.pushNamed(context, 'AboutUs');
                      },
                      leading: Icon(Icons.info_outline, color: Palette.blue),
                      title: Text(
                        getTranslated(context, AppString.setting_about).toString(),
                        style: TextStyle(fontSize: 15, color: Palette.dark_blue, fontWeight: FontWeight.w600),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Palette.dark_grey),
                    ),
                    Divider(height: 1, thickness: 1, color: Palette.dark_white),
                    ListTile(
                      onTap: () {
                        Navigator.pushNamed(context, 'PrivacyPolicy');
                      },
                      leading: Icon(Icons.privacy_tip_outlined, color: Palette.blue),
                      title: Text(
                        getTranslated(context, AppString.setting_privacyPolicy).toString(),
                        style: TextStyle(fontSize: 15, color: Palette.dark_blue, fontWeight: FontWeight.w600),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Palette.dark_grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Palette.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Palette.black.withOpacity(0.12),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Palette.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_off_rounded, size: 40, color: Palette.red),
              ),
              SizedBox(height: 20),
              Text(
                getTranslated(context, AppString.deleteAccountQuestion).toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Palette.dark_blue,
                ),
              ),
              SizedBox(height: 10),
              Text(
                getTranslated(context, AppString.youWillLoseAllTheDataAndWonBeAbleToLogBackIn).toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Palette.grey,
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Palette.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        getTranslated(context, AppString.No).toString(),
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Palette.dark_blue),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        callDeleteAccount();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Palette.red,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        getTranslated(context, AppString.Yes).toString(),
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Palette.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> logoutUser() async {
    // A deleted patient must never navigate to an API-backed Home screen.
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await SharedPreferenceHelper.clearSecure();
    await SharedPreferenceHelper.clearPref();
    try {
      await auth.handleSignOut();
    } catch (_) {
      // Local credentials were cleared even if Firebase is offline.
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => SignIn()),
      (route) => false,
    );
  }

  Future<BaseModel<AccountDeleteModel>> callDeleteAccount() async {
    // Block duplicate irreversible requests.
    if (!mounted || loading) return BaseModel<AccountDeleteModel>();
    setState(() => loading = true);
    try {
      final response = await RestClient(RetroApi().dioData()).deleteAccount();
      if (!mounted) return BaseModel<AccountDeleteModel>()..data = response;
      final message = response.message;
      if (message != null && message.isNotEmpty) {
        Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Palette.blue,
          textColor: Palette.white,
        );
      }
      if (response.success == true) {
        // Only backend-confirmed erasure ends the account.
        await logoutUser();
      }
      return BaseModel<AccountDeleteModel>()..data = response;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Account deletion is unavailable. Please try again or contact support.'),
        ));
      }
      return BaseModel<AccountDeleteModel>()
        ..setException(ServerError.withError(error: error));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

}

class SwitchScreen extends StatefulWidget {
  @override
  SwitchClass createState() => new SwitchClass();
}

class SwitchClass extends State {
  bool isSwitched = true;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      children: <Widget>[
        Column(
          children: [
            Column(
              children: [
                Column(
                  children: [
                    Container(
                      height: size.width * 0.038,
                      margin: EdgeInsets.only(),
                      child: Switch(
                        value: isSwitched,
                        onChanged: (value) {
                          setState(
                            () {
                              isSwitched = value;
                            },
                          );
                        },
                        activeColor: Palette.white,
                        activeTrackColor: Palette.dark_blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
