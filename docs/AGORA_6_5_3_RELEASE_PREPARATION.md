# Patient native calling SDK upgrade

Patient now pins agora_rtc_engine 6.5.3. Its resolved Iris bridge is 2.2.7. Only those two Dart dependency versions changed. Plus already uses Agora 6.5.3 with Iris 2.2.4.

The previous Agora native SDK 4.2.6 contained multiple ARM64 libraries with 4 KiB PT_LOAD alignment. This blocks 16 KiB Android readiness. The replacement native SDK is Agora 4.5.2 with Iris RTC 4.5.2-build.1 and its declared first-party AOSL dependency. Official Maven artifacts were checksum-verified before inspection. Static alignment checks do not replace a final signed AAB/Play-generated APK check and a 16 KiB device run.

Patient's 105 offline Flutter tests pass with the upgraded dependency graph. The analyzer has no errors and retains 299 warning/informational diagnostics. Calling acceptance with real staging tokens, two devices, permissions and reconnect remains required.

## iOS lockfile preparation on Mac

The committed ios/Podfile.lock still represents the earlier native SDK. It has not been regenerated on Windows. Before the existing release builder's strict `pod install --deployment`, run on the developer's Mac:

    bash tools/prepare-patient-ios-agora.sh

This runs locked Flutter resolution and a targeted CocoaPods update for the two Flutter plugins and their Agora iOS SDK dependencies. Review and retain the resulting Podfile.lock; do not manually invent CocoaPods checksums. Then validate with Xcode26+/iOS26 SDK, the correct private Firebase/Maps configuration, push entitlements and an iPhone. No iOS compile/signing result is claimed by the Windows preparation.

Vendor references: [Agora 16 KiB guidance](https://agoraio.zendesk.com/hc/en-us/articles/47794428446996-Resolving-Google-Play-16-KB-Memory-Page-Size-Warning-for-Flutter-Android-Apps), [Android page-size validation](https://developer.android.com/guide/practices/page-sizes).
