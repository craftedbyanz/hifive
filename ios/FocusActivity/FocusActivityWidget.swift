// The FocusActivity widget extension: a running focus session on the lock
// screen and in the Dynamic Island, drawn in hifive's indigo with the plant
// the learner is growing.
import ActivityKit
import SwiftUI
import WidgetKit

@main
struct FocusActivityBundle: WidgetBundle {
  var body: some Widget {
    FocusLiveActivity()
  }
}

private let ink = Color(red: 0.16, green: 0.18, blue: 0.55)
private let mint = Color(red: 0.62, green: 0.93, blue: 0.70)

struct FocusLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: FocusAttributes.self) { context in
      LockScreenView(attributes: context.attributes, state: context.state)
        .activityBackgroundTint(ink.opacity(0.82))
        .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          PlantImage(version: context.state.plant).frame(width: 56, height: 56)
        }
        DynamicIslandExpandedRegion(.trailing) {
          TimerText(state: context.state)
            .font(.system(size: 30, weight: .semibold).monospacedDigit())
            .foregroundColor(mint)
            .frame(maxWidth: 110, alignment: .trailing)
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(alignment: .leading, spacing: 6) {
            TagLabel(attributes: context.attributes)
            SessionProgress(state: context.state)
          }
        }
      } compactLeading: {
        Image(systemName: "leaf.fill").foregroundColor(mint)
      } compactTrailing: {
        TimerText(state: context.state)
          .monospacedDigit()
          .foregroundColor(mint)
          .frame(maxWidth: 52)
      } minimal: {
        Image(systemName: "leaf.fill").foregroundColor(mint)
      }
    }
  }
}

private struct LockScreenView: View {
  let attributes: FocusAttributes
  let state: FocusAttributes.ContentState

  var body: some View {
    HStack(spacing: 14) {
      ZStack {
        Circle().fill(
          LinearGradient(
            colors: [Color(red: 0.93, green: 1, blue: 0.86), Color(red: 0.80, green: 0.93, blue: 0.62)],
            startPoint: .top, endPoint: .bottom))
        PlantImage(version: state.plant).padding(4)
      }
      .frame(width: 76, height: 76)
      VStack(alignment: .leading, spacing: 6) {
        TimerText(state: state)
          .font(.system(size: 34, weight: .semibold).monospacedDigit())
          .foregroundColor(.white)
        TagLabel(attributes: attributes)
        SessionProgress(state: state)
      }
      Spacer(minLength: 0)
      if #available(iOS 17, *) {
        Button(intent: StopFocusIntent()) {
          Image(systemName: "xmark")
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 36, height: 36)
            .background(Circle().fill(Color.white.opacity(0.18)))
        }
        .buttonStyle(.plain)
      }
    }
    .padding(16)
  }
}

/// The time left, counting down by itself; up from the start for the
/// stopwatch.
private struct TimerText: View {
  let state: FocusAttributes.ContentState

  var body: some View {
    if let end = state.end, end > state.start {
      Text(timerInterval: state.start...end, countsDown: true)
    } else {
      Text(state.start, style: .timer)
    }
  }
}

private struct SessionProgress: View {
  let state: FocusAttributes.ContentState

  var body: some View {
    if let end = state.end, end > state.start {
      ProgressView(timerInterval: state.start...end, countsDown: false) {
        EmptyView()
      } currentValueLabel: {
        EmptyView()
      }
      .tint(mint)
    }
  }
}

private struct TagLabel: View {
  let attributes: FocusAttributes

  var body: some View {
    HStack(spacing: 6) {
      Circle().fill(Color(hex: attributes.color) ?? mint).frame(width: 8, height: 8)
      Text(attributes.tag)
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(.white.opacity(0.8))
        .lineLimit(1)
    }
  }
}

/// The plant the app last drew into the shared container, or a leaf until
/// it has.
private struct PlantImage: View {
  let version: Int

  var body: some View {
    if let url = FileManager.default
      .containerURL(forSecurityApplicationGroupIdentifier: focusAppGroup)?
      .appendingPathComponent(focusPlantFile(version)),
      let image = UIImage(contentsOfFile: url.path)
    {
      Image(uiImage: image).resizable().scaledToFit()
    } else {
      Image(systemName: "leaf.fill")
        .resizable()
        .scaledToFit()
        .foregroundColor(mint)
        .padding(14)
    }
  }
}

private extension Color {
  init?(hex: String) {
    var text = hex.trimmingCharacters(in: .whitespaces)
    if text.hasPrefix("#") { text.removeFirst() }
    guard text.count == 6, let value = UInt32(text, radix: 16) else { return nil }
    self.init(
      red: Double((value >> 16) & 0xff) / 255,
      green: Double((value >> 8) & 0xff) / 255,
      blue: Double(value & 0xff) / 255)
  }
}
