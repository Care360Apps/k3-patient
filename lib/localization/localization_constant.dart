import 'package:doctro_patient/const/prefConstatnt.dart';
import 'package:doctro_patient/const/preference.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'language_localization.dart';

String? getTranslated(BuildContext context, String key) {
  // The localization delegate can be unavailable while a route first mounts.
  // A readable fallback is preferable to a red Flutter error widget.
  return LanguageLocalization.of(context)?.getTranslateValue(key) ?? key;
}

const String ENGLISH = "en";
const String HAUSA = "ha";
const String IGBO = "ig";
const String YORUBA = "yo";
const String FRENCH = "fr";
const String SPANISH = "es";
const String ARABIC = "ar";

Future<Locale> setLocale(String languageCode) async {
  SharedPreferenceHelper.setString(Preferences.current_language_code, languageCode);
  return _locale(languageCode);
}

Locale _locale(String languageCode) {
  Locale _temp;
  switch (languageCode) {
    case ENGLISH:
      _temp = Locale(languageCode, 'US');
      break;
    case HAUSA:
      _temp = Locale(languageCode, 'NG');
      break;
    case IGBO:
      _temp = Locale(languageCode, 'NG');
      break;
    case YORUBA:
      _temp = Locale(languageCode, 'NG');
      break;
    case FRENCH:
      _temp = Locale(languageCode, 'FR');
      break;
    case SPANISH:
      _temp = Locale(languageCode, 'ES');
      break;
    case ARABIC:
      _temp = Locale(languageCode, 'AE');
      break;
    default:
      _temp = Locale(ENGLISH, 'US');
  }
  return _temp;
}

Future<Locale> getLocale() async {
  String? languageCode = SharedPreferenceHelper.getString(Preferences.current_language_code);
  return _locale(languageCode ?? ENGLISH);
}
