import UIKit
import Flutter
import workmanager


@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

        UIApplication.shared.setMinimumBackgroundFetchInterval(TimeInterval(60*1))


        GeneratedPluginRegistrant.register(with: self)
        UNUserNotificationCenter.current().delegate = self

        WorkmanagerPlugin.setPluginRegistrantCallback { registry in
            // Registry in this case is the FlutterEngine that is created in Workmanager's
            // performFetchWithCompletionHandler or BGAppRefreshTask.
            // This will make other plugins available during a background operation.
            GeneratedPluginRegistrant.register(with: registry)
        }

        // When this task is scheduled from dart it will run with minimum 20 minute frequency. The
        // frequency is not guaranteed rather iOS will schedule it as per user's App usage pattern.
        // If frequency is not provided it will default to 15 minutes
        WorkmanagerPlugin.registerPeriodicTask(withIdentifier: "be.tramckrijte.workmanagerExample.iOSBackgroundAppRefresh", frequency: NSNumber(value: 1 * 60))

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
