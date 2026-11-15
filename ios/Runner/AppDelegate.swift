import ActivityKit
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
    // Lets review reminders show as banners even while hifive is open.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .list, .sound])
  }

  /// Set when the learner taps a review reminder, until Flutter takes it
  /// (`takeReviewTap`), so a tap that launches the app still opens the
  /// review once Home is up.
  private var reviewTapped = false
  private var screenChannel: FlutterMethodChannel?

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if response.notification.request.identifier.hasPrefix("review-reminder") {
      reviewTapped = true
      screenChannel?.invokeMethod("reviewTapped", arguments: nil)
    }
    completionHandler()
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ScreenLock") {
      watchScreenLock(FlutterMethodChannel(name: "hifive/screen", binaryMessenger: registrar.messenger()))
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FocusShield") {
      FocusShield.shared.attach(FlutterMethodChannel(name: "hifive/shield", binaryMessenger: registrar.messenger()))
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FocusLive") {
      FocusLive.shared.attach(FlutterMethodChannel(name: "hifive/live", binaryMessenger: registrar.messenger()))
    }
  }

  /// Tells Flutter when the phone locks and unlocks, so a focus session keeps
  /// going while it lies locked on the desk. Protected data becomes
  /// unavailable only on a passcode-locked phone.
  private func watchScreenLock(_ channel: FlutterMethodChannel) {
    screenChannel = channel
    let center = NotificationCenter.default
    let alerts = UNUserNotificationCenter.current()
    let warningId = "focus-warning"
    center.addObserver(forName: UIApplication.protectedDataWillBecomeUnavailableNotification, object: nil, queue: .main) { _ in
      // The phone was put down, not switched away from: no warning.
      alerts.removePendingNotificationRequests(withIdentifiers: [warningId])
      channel.invokeMethod("locked", arguments: true)
    }
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "takeReviewTap":
        result(self?.reviewTapped ?? false)
        self?.reviewTapped = false
      case "prepareWarning":
        // Answers whether notifications are allowed (asking the first time).
        alerts.requestAuthorization(options: [.alert, .sound]) { granted, _ in
          DispatchQueue.main.async { result(granted) }
        }
      case "notificationStatus":
        // Whether hifive may notify, without asking.
        alerts.getNotificationSettings { settings in
          let status: String
          switch settings.authorizationStatus {
          case .notDetermined: status = "unasked"
          case .denied: status = "denied"
          default: status = "allowed"
          }
          DispatchQueue.main.async { result(status) }
        }
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
      case "scheduleReminders":
        // The coming days' reminders, each with its own count; replaces any
        // scheduled before, so one still comes on days the app stays closed.
        let list = call.arguments as? [[String: Any]] ?? []
        alerts.getPendingNotificationRequests { pending in
          let old = pending.map(\.identifier).filter { $0.hasPrefix("review-reminder") }
          alerts.removePendingNotificationRequests(withIdentifiers: old)
          for (i, item) in list.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = item["title"] as? String ?? ""
            content.body = item["body"] as? String ?? ""
            content.sound = .default
            let at = Date(timeIntervalSince1970: (item["at"] as? Double ?? 0) / 1000)
            let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: at)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            alerts.add(UNNotificationRequest(identifier: "review-reminder-\(i)", content: content, trigger: trigger))
          }
          DispatchQueue.main.async { result(nil) }
        }
      case "cancelReminder":
        alerts.getPendingNotificationRequests { pending in
          let old = pending.map(\.identifier).filter { $0.hasPrefix("review-reminder") }
          alerts.removePendingNotificationRequests(withIdentifiers: old)
          DispatchQueue.main.async { result(nil) }
        }
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

/// Shows a running focus session on the lock screen and in the Dynamic
/// Island (the FocusActivity extension draws it). The timer and progress run
/// by themselves; the app redraws the plant's picture into the shared App
/// Group whenever it grows a step, and is told when the learner taps ✕.
final class FocusLive {
  static let shared = FocusLive()
  private var version = 0

  func attach(_ channel: FlutterMethodChannel) {
    // A session never outlives the app, so its Live Activity must not either.
    if #available(iOS 16.1, *) { endAll() }
    NotificationCenter.default.addObserver(forName: .hifiveStopFocus, object: nil, queue: .main) { _ in
      channel.invokeMethod("stop", arguments: nil)
    }
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self, #available(iOS 16.1, *) else { return result(nil) }
      let args = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      case "start":
        self.endAll()
        self.clearPlants()
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return result(false) }
        let start = Date(timeIntervalSince1970: (args["start"] as? Double ?? 0) / 1000)
        let end = (args["end"] as? Double).map { Date(timeIntervalSince1970: $0 / 1000) }
        let attributes = FocusAttributes(tag: args["tag"] as? String ?? "", color: args["color"] as? String ?? "")
        let state = FocusAttributes.ContentState(start: start, end: end, plant: self.version)
        do {
          if #available(iOS 16.2, *) {
            _ = try Activity.request(attributes: attributes, content: .init(state: state, staleDate: end), pushType: nil)
          } else {
            _ = try Activity.request(attributes: attributes, contentState: state, pushType: nil)
          }
          result(true)
        } catch {
          result(false)
        }
      case "plant":
        guard let bytes = args["png"] as? FlutterStandardTypedData else { return result(nil) }
        self.savePlant(bytes.data)
        let version = self.version
        Task {
          for activity in Activity<FocusAttributes>.activities {
            if #available(iOS 16.2, *) {
              var state = activity.content.state
              state.plant = version
              await activity.update(.init(state: state, staleDate: state.end))
            } else {
              var state = activity.contentState
              state.plant = version
              await activity.update(using: state)
            }
          }
          result(nil)
        }
      case "end":
        self.endAll()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Removes the last session's pictures, so a new one starts with a leaf.
  private func clearPlants() {
    guard let folder = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: focusAppGroup),
      let files = try? FileManager.default.contentsOfDirectory(atPath: folder.path)
    else { return }
    for name in files where name.hasPrefix("focus-plant-") {
      try? FileManager.default.removeItem(at: folder.appendingPathComponent(name))
    }
    version = 0
  }

  /// Writes the plant's picture as a new version and removes older ones.
  private func savePlant(_ data: Data) {
    guard let folder = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: focusAppGroup)
    else { return }
    let old = version
    version += 1
    try? data.write(to: folder.appendingPathComponent(focusPlantFile(version)), options: .atomic)
    if old > 0 { try? FileManager.default.removeItem(at: folder.appendingPathComponent(focusPlantFile(old))) }
  }

  @available(iOS 16.1, *)
  private func endAll() {
    Task {
      for activity in Activity<FocusAttributes>.activities {
        if #available(iOS 16.2, *) {
          await activity.end(nil, dismissalPolicy: .immediate)
        } else {
          await activity.end(dismissalPolicy: .immediate)
        }
      }
    }
  }
}
