import FamilyControls
import Flutter
import ManagedSettings
import SwiftUI
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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FocusShield") {
      FocusShield.shared.attach(FlutterMethodChannel(name: "hifive/shield", binaryMessenger: registrar.messenger()))
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

/// Blocks the apps the learner chose while a focus session runs, with the
/// Screen Time API. The choice and the switch are kept in UserDefaults: app
/// tokens only mean something on this phone. Needs iOS 16 and the Family
/// Controls entitlement; without either, Flutter hides the switch or shows
/// why it can't be turned on.
final class FocusShield {
  static let shared = FocusShield()
  private let defaults = UserDefaults.standard
  private let enabledKey = "focusShield.enabled"
  private let selectionKey = "focusShield.selection"

  func attach(_ channel: FlutterMethodChannel) {
    // A session never outlives the app, so no shield may either.
    if #available(iOS 16, *) { store.clearAllSettings() }
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return result(nil) }
      guard #available(iOS 16, *) else {
        return result(call.method == "status" ? ["available": false, "enabled": false, "picked": 0] : nil)
      }
      let args = call.arguments as? [String: Any] ?? [:]
      let title = args["title"] as? String ?? ""
      let done = args["done"] as? String ?? ""
      switch call.method {
      case "status":
        result(self.status())
      case "enable":
        guard args["on"] as? Bool == true else {
          self.defaults.set(false, forKey: self.enabledKey)
          return result(self.status())
        }
        Task { @MainActor in
          do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
          } catch {
            let denied = AuthorizationCenter.shared.authorizationStatus == .denied
            return result(FlutterError(code: denied ? "denied" : "unavailable", message: "\(error)", details: nil))
          }
          self.defaults.set(true, forKey: self.enabledKey)
          if self.picked() == 0 {
            self.presentPicker(title: title, done: done) { result(self.status()) }
          } else {
            result(self.status())
          }
        }
      case "pick":
        self.presentPicker(title: title, done: done) { result(self.status()) }
      case "start":
        if self.defaults.bool(forKey: self.enabledKey), let s = self.selection() {
          self.store.shield.applications = s.applicationTokens.isEmpty ? nil : s.applicationTokens
          self.store.shield.applicationCategories = s.categoryTokens.isEmpty ? nil : .specific(s.categoryTokens)
          self.store.shield.webDomains = s.webDomainTokens.isEmpty ? nil : s.webDomainTokens
        }
        result(nil)
      case "stop":
        self.store.clearAllSettings()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  @available(iOS 16, *)
  private var store: ManagedSettingsStore { ManagedSettingsStore(named: .init("hifive.focus")) }

  @available(iOS 16, *)
  private func status() -> [String: Any] {
    let approved = AuthorizationCenter.shared.authorizationStatus == .approved
    return ["available": true, "enabled": approved && defaults.bool(forKey: enabledKey), "picked": picked()]
  }

  @available(iOS 16, *)
  private func selection() -> FamilyActivitySelection? {
    guard let data = defaults.data(forKey: selectionKey) else { return nil }
    return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
  }

  @available(iOS 16, *)
  private func picked() -> Int {
    guard let s = selection() else { return 0 }
    return s.applicationTokens.count + s.categoryTokens.count + s.webDomainTokens.count
  }

  /// Shows Apple's app picker as a sheet that only Done closes, saves the
  /// choice and calls [finished].
  @available(iOS 16, *)
  private func presentPicker(title: String, done: String, finished: @escaping () -> Void) {
    guard var top = UIApplication.shared.connectedScenes
      .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController }).first
    else { return finished() }
    while let next = top.presentedViewController { top = next }
    var host: UIViewController?
    let picker = ShieldPicker(selection: selection() ?? FamilyActivitySelection(), title: title, done: done) { chosen in
      if let data = try? JSONEncoder().encode(chosen) { self.defaults.set(data, forKey: self.selectionKey) }
      // Drop the hosting controller here, or it and its view keep each other.
      let shown = host
      host = nil
      shown?.dismiss(animated: true) { finished() }
    }
    let controller = UIHostingController(rootView: picker)
    controller.isModalInPresentation = true
    host = controller
    top.present(controller, animated: true)
  }
}

@available(iOS 16, *)
private struct ShieldPicker: View {
  @State var selection: FamilyActivitySelection
  let title: String
  let done: String
  let finish: (FamilyActivitySelection) -> Void

  var body: some View {
    NavigationView {
      FamilyActivityPicker(selection: $selection)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button(done) { finish(selection) }
          }
        }
    }
  }
}
