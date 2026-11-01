import 'package:flutter/material.dart';
import '../../brand/care360_entry.dart';
import '../../const/prefConstatnt.dart';
import '../../const/preference.dart';
import '../Authentication/SignIn.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) => Care360Welcome(
    professional: false,
    onComplete: () async {
      await SharedPreferenceHelper.setBoolean(Preferences.onboarding_seen, true);
      if (!context.mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SignIn()));
    },
  );
}
