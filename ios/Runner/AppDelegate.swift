import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Affiche les notifications locales même quand l'app est au premier plan.
    UNUserNotificationCenter.current().delegate = self
    // Vérification périodique des alertes météo (voir alert_watcher.dart).
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "com.example.meteo.alertWatch",
      frequency: NSNumber(value: 30 * 60)
    )
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
