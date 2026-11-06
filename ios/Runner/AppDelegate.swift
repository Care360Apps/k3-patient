import UIKit
import Flutter
import GoogleMaps
import Firebase
import UserNotifications
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // The Maps key comes from the selected (staging or production) build configuration.
    // Never pass an unresolved Xcode build variable as a real API key.
    if let mapsApiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !mapsApiKey.isEmpty,
       !mapsApiKey.hasPrefix("$(") {
      GMSServices.provideAPIKey(mapsApiKey)
    }

    // FlutterFire may also initialize Firebase from Dart. Configure the
    // native default app only once to avoid a duplicate-default-app error.
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    // Set up the notification delegate, but do not show an unsolicited
    // permission dialog at app launch. Permission is requested by an
    // explicit user action inside Settings after sign-in.
    UNUserNotificationCenter.current().delegate = self

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    // Never print device tokens: they identify a device's push subscription.
    Messaging.messaging().apnsToken = deviceToken
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    // Do not log provider error descriptions in a healthcare app.
    #if DEBUG
    NSLog("Care360 push registration unavailable; continue without notifications.")
    #endif
  }
}
