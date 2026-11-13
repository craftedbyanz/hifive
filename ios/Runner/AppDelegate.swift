import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ScreenLock") {
      watchScreenLock(FlutterMethodChannel(name: "hifive/screen", binaryMessenger: registrar.messenger()))
    }
  }

  /// Tells Flutter when the phone locks and unlocks, so a focus session keeps
  /// going while it lies locked on the desk. Protected data becomes
  /// unavailable only on a passcode-locked phone.
  private func watchScreenLock(_ channel: FlutterMethodChannel) {
    let center = NotificationCenter.default
    let alerts = UNUserNotificationCenter.current()
    let warningId = "focus-warning"
    center.addObserver(forName: UIApplication.protectedDataWillBecomeUnavailableNotification, object: nil, queue: .main) { _ in
      // The phone was put down, not switched away from: no warning.
      alerts.removePendingNotificationRequests(withIdentifiers: [warningId])
      channel.invokeMethod("locked", arguments: true)
    }
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "prepareWarning":
        alerts.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        result(nil)
      case "warn":
        let args = call.arguments as? [String: String] ?? [:]
        let content = UNMutableNotificationContent()
        content.title = args["title"] ?? ""
        content.body = args["body"] ?? ""
        content.sound = .default
        // Late enough for a lock to cancel it first (protected data goes
        // about 10 s after locking), early enough to come back within 30 s.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 12, repeats: false)
        alerts.add(UNNotificationRequest(identifier: warningId, content: content, trigger: trigger))
        result(nil)
      case "scheduleReminder":
        // One reminder at a time, rescheduled whenever the forecast changes.
        let args = call.arguments as? [String: Any] ?? [:]
        let content = UNMutableNotificationContent()
        content.title = args["title"] as? String ?? ""
        content.body = args["body"] as? String ?? ""
        content.sound = .default
        let at = Date(timeIntervalSince1970: (args["at"] as? Double ?? 0) / 1000)
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: at)
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        alerts.removePendingNotificationRequests(withIdentifiers: ["review-reminder"])
        alerts.add(UNNotificationRequest(identifier: "review-reminder", content: content, trigger: trigger))
        result(nil)
      case "cancelReminder":
        alerts.removePendingNotificationRequests(withIdentifiers: ["review-reminder"])
        result(nil)
      case "clearWarning":
        alerts.removePendingNotificationRequests(withIdentifiers: [warningId])
        alerts.removeDeliveredNotifications(withIdentifiers: [warningId])
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    center.addObserver(forName: UIApplication.protectedDataDidBecomeAvailableNotification, object: nil, queue: .main) { _ in
      channel.invokeMethod("locked", arguments: false)
    }
  }
}
