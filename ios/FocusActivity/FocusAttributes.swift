// Shared by the app and the FocusActivity widget extension: what a running
// focus session tells the lock screen and the Dynamic Island.
import ActivityKit
import AppIntents
import Foundation

/// The App Group both targets share; the app writes the plant's picture
/// there for the widget to show.
let focusAppGroup = "group.com.anznguyen.hifive"

/// The file name of the plant's picture for a given [version].
func focusPlantFile(_ version: Int) -> String { "focus-plant-\(version).png" }

@available(iOS 16.1, *)
struct FocusAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    /// When the session started and when it ends; no end for the stopwatch.
    var start: Date
    var end: Date?
    /// Bumped whenever the plant's picture is redrawn, so the views reload it.
    var plant: Int
  }

  /// The session's tag ("Học tiếng Anh") and its colour as #RRGGBB.
  var tag: String
  var color: String
}

extension Notification.Name {
  /// Posted when the learner ends the session from the lock screen.
  static let hifiveStopFocus = Notification.Name("hifive.stopFocus")
}

/// The ✕ on the lock screen: ends the session in the app, which cancels it
/// in its first seconds and gives up after that.
@available(iOS 17, *)
struct StopFocusIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Stop focusing"

  func perform() async throws -> some IntentResult {
    await MainActor.run {
      NotificationCenter.default.post(name: .hifiveStopFocus, object: nil)
    }
    return .result()
  }
}
