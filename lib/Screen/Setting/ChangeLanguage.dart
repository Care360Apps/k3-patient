import 'package:doctro_patient/const/prefConstatnt.dart';
import 'package:doctro_patient/const/preference.dart';
import 'package:doctro_patient/localization/localization_constant.dart';
import 'package:flutter/material.dart';
import 'package:doctro_patient/Chat/loading_view.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import '../../api/retrofit_Api.dart';
import '../../api/base_model.dart';
import '../../api/network_api.dart';
import '../../api/server_error.dart';
import '../../const/Palette.dart';
import '../../const/app_string.dart';
import '../../main.dart';
import '../../model/update_profile_model.dart';
import '../../model/user_detail_model.dart';

class ChangeLanguage extends StatefulWidget {
  const ChangeLanguage({Key? key}) : super(key: key);

  @override
  _ChangeLanguageState createState() => _ChangeLanguageState();
}

class _ChangeLanguageState extends State<ChangeLanguage> {
  int? value;

  bool loading = false;
  String userName = "";
  String userPhoneCode = "";
  String userPhoneNo = "";
  String? userDateOfBirth = "";
  String userGender = "";

  @override
  void initState() {
    super.initState();
    // Language selection works locally, including in an offline test build.
    // It must not require a valid profile token or edit medical profile data.
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: loading,
      opacity: 0.5,
      progressIndicator: SpinKitFadingCircle(
        color: Palette.blue,
        size: 50.0,
      ),
      child: Scaffold(
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
            getTranslated(context, AppString.changeLanguage_title).toString(),
            style: TextStyle(fontSize: 18, color: Palette.dark_blue, fontWeight: FontWeight.bold),
          ),
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(
              new FocusNode(),
            );
          },
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            margin: EdgeInsets.only(left: 10, right: 10),
            child: ListView.builder(
              itemCount: Language.languageList().length,
              padding: EdgeInsets.only(bottom: 20),
              itemBuilder: (context, index) {
                value = 0;
                value = Language.languageList()[index].languageCode == SharedPreferenceHelper.getString(Preferences.current_language_code) ? index : null;
                if (SharedPreferenceHelper.getString(Preferences.current_language_code) == "N_A") {
                  value = 0;
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 15,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Palette.white,
                          borderRadius: BorderRadius.all(
                            Radius.circular(15),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Palette.black.withOpacity(0.1),
                              blurRadius: 5,
                            )
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: RadioListTile(
                            value: index,
                            controlAffinity: ListTileControlAffinity.trailing,
                            groupValue: value,
                            activeColor: Palette.dark_blue,
                            onChanged: (int? val) async {
                              final selected = Language.languageList()[index].languageCode;
                              final local = await setLocale(selected);
                              if (!mounted) return;
                              // Keep the root state context; this settings route
                              // will be disposed after Navigator.pop.
                              final root = navigatorKey.currentState;
                              if (root == null || !root.mounted) return;
                              final rootContext = root.context;
                              final exiting = ModalRoute.of(context);
                              Navigator.of(context).pop();
                              // Wait for the exiting settings route to finish
                              // before reloading the app's localization tree.
                              await exiting?.completed;
                              if (root.mounted) {
                                MyApp.setLocale(rootContext, local);
                              }
                            },
                            title: Text(Language.languageList()[index].name),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<BaseModel<UpdateProfile>> callApiUpdateProfile() async {
    UpdateProfile response;
    Map<String, dynamic> body = {
      "name": userName,
      "phone_code": userPhoneCode,
      "phone": userPhoneNo,
      "dob": userDateOfBirth,
      "gender": userGender,
      "language": SharedPreferenceHelper.getString(Preferences.current_language_code),
    };
    setState(() {
      loading = true;
    });
    try {
      response = await RestClient(RetroApi().dioData()).updateProfileRequest(body);
      setState(() {
        if (response.success == true) {
          setState(() {
            loading = false;
            Fluttertoast.showToast(
              msg: '${response.msg}',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Palette.blue,
              textColor: Palette.white,
            );
          });
        }
      });
    } catch (error, stacktrace) {
      setState(() {
        loading = false;
      });
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<BaseModel<UserDetail>> callApiUserProfile() async {
    UserDetail response;
    setState(() {
      loading = true;
    });
    try {
      response = await RestClient(RetroApi().dioData()).userDetailRequest();
      setState(() {
        loading = false;
        userName = response.name!;
        userPhoneCode = response.phoneCode!;
        userPhoneNo = response.phone!;
        userDateOfBirth = response.dob;
        userGender = response.gender!.toUpperCase();
      });
    } catch (error, stacktrace) {
      setState(() {
        loading = false;
      });
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }
}

class Language {
  final int id;
  final String name;
  final String flag;
  final String languageCode;

  Language(this.id, this.name, this.flag, this.languageCode);

  static List<Language> languageList() {
    return <Language>[
      Language(1, 'English', 'EN', 'en'),
      Language(2, 'Hausa', 'HA', 'ha'),
      Language(3, 'Igbo', 'IG', 'ig'),
      Language(4, 'Yorùbá', 'YO', 'yo'),
      Language(5, 'Français', 'FR', 'fr'),
    ];
  }
}
