import ActivityKit
import FamilyControls
import Flutter
import ManagedSettings
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

  /// The card id of a tapped word note, until Flutter takes it
  /// (`takeWordTap`), for the same reason.
  private var tappedWord: String?
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
    if response.notification.request.identifier.hasPrefix("word-note"),
       let word = response.notification.request.content.userInfo["word"] as? String {
      tappedWord = word
      screenChannel?.invokeMethod("wordTapped", arguments: word)
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
      case "takeWordTap":
        result(self?.tappedWord)
        self?.tappedWord = nil
      case "scheduleWordNotes":
        // A word and its meaning on the lock screen through the day. Silent,
        // grouped in one stack, and replacing any scheduled before.
        let list = call.arguments as? [[String: Any]] ?? []
        alerts.getPendingNotificationRequests { pending in
          let old = pending.map(\.identifier).filter { $0.hasPrefix("word-note") }
          alerts.removePendingNotificationRequests(withIdentifiers: old)
          for (i, item) in list.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = item["title"] as? String ?? ""
            content.body = item["body"] as? String ?? ""
            content.threadIdentifier = "word-notes"
            content.userInfo = ["word": item["word"] as? String ?? ""]
            let at = Date(timeIntervalSince1970: (item["at"] as? Double ?? 0) / 1000)
            let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: at)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            alerts.add(UNNotificationRequest(identifier: "word-note-\(i)", content: content, trigger: trigger))
          }
          DispatchQueue.main.async { result(nil) }
        }
      case "cancelWordNotes":
        alerts.getPendingNotificationRequests { pending in
          let old = pending.map(\.identifier).filter { $0.hasPrefix("word-note") }
          alerts.removePendingNotificationRequests(withIdentifiers: old)
          DispatchQueue.main.async { result(nil) }
        }
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

/// Blocks every other app and website while a focus session runs, with the
/// Screen Time API, as focus apps do: no switch and no list to pick. The
/// first session asks for Screen Time access. Needs iOS 16 and the Family
/// Controls entitlement; without either a session runs unblocked.
///
/// Flutter draws its frames on the main thread, so the store's work (it
/// talks to a system daemon) runs on a queue of its own.
final class FocusShield {
  static let shared = FocusShield()
  private let queue = DispatchQueue(label: "hifive.shield", qos: .userInitiated)
  /// The `ManagedSettingsStore`, made once (iOS 16 only).
  private var storeBox: AnyObject?

  func attach(_ channel: FlutterMethodChannel) {
    // A session never outlives the app, so no shield may either.
    if #available(iOS 16, *) {
      let store = self.store
      queue.async { store.clearAllSettings() }
    }
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return result(nil) }
      guard #available(iOS 16, *) else { return result(call.method == "start" ? "unavailable" : nil) }
      switch call.method {
      case "start":
        Task { @MainActor in
          let center = AuthorizationCenter.shared
          if center.authorizationStatus != .approved {
            if center.authorizationStatus == .denied { return result("denied") }
            do {
              try await center.requestAuthorization(for: .individual)
            } catch {
              return result(center.authorizationStatus == .denied ? "declined" : "unavailable")
            }
            guard center.authorizationStatus == .approved else { return result("declined") }
          }
          let store = self.store
          self.queue.async {
            // Every category covers every app; the phone keeps its
            // essentials (Phone, Settings, emergency) open by itself.
            store.shield.applicationCategories = .all()
            store.shield.webDomainCategories = .all()
            DispatchQueue.main.async { result("on") }
          }
        }
      case "stop":
        let store = self.store
        queue.async {
          store.clearAllSettings()
          DispatchQueue.main.async { result(nil) }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  @available(iOS 16, *)
  private var store: ManagedSettingsStore {
    if let made = storeBox as? ManagedSettingsStore { return made }
    let made = ManagedSettingsStore(named: .init("hifive.focus"))
    storeBox = made
    return made
  }
}

/// Shows a running focus session on the lock screen and in the Dynamic
/// Island (the FocusActivity extension draws it). The timer and progress run
/// by themselves; the app redraws the plant's picture into the shared App
/// Group whenever it grows a step, and is told when the learner taps ✕.
final class FocusLive {
  static let shared = FocusLive()
  /// Pictures and their version number are only touched on this queue.
  private let queue = DispatchQueue(label: "hifive.live", qos: .userInitiated)
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
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return result(false) }
        let start = Date(timeIntervalSince1970: (args["start"] as? Double ?? 0) / 1000)
        let end = (args["end"] as? Double).map { Date(timeIntervalSince1970: $0 / 1000) }
        let attributes = FocusAttributes(tag: args["tag"] as? String ?? "", color: args["color"] as? String ?? "")
        // Files and the system's Live Activity service are slow to answer;
        // Flutter draws on the main thread, so they wait on a queue instead.
        self.queue.async {
          self.clearPlants()
          let state = FocusAttributes.ContentState(start: start, end: end, plant: self.version)
          var shown = true
          do {
            if #available(iOS 16.2, *) {
              _ = try Activity.request(attributes: attributes, content: .init(state: state, staleDate: end), pushType: nil)
            } else {
              _ = try Activity.request(attributes: attributes, contentState: state, pushType: nil)
            }
          } catch {
            shown = false
          }
          DispatchQueue.main.async { result(shown) }
        }
      case "plant":
        guard let bytes = args["png"] as? FlutterStandardTypedData else { return result(nil) }
        self.queue.async {
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
            DispatchQueue.main.async { result(nil) }
          }
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
