# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Language

Reply to the user in Vietnamese in chat. Write everything recorded in files (docs, code comments, notes, logs) in English. Exception: the app's Vietnamese UI strings stay Vietnamese.

## Project

hifive is a local-only Flutter (iOS + Android) language-learning app. It will support several languages; English is the first course. There is no backend, AI, billing or account system yet.

The code started from a private prototype that re-created another app's UI. Its screens, copy, colors and artwork still follow that app and are being replaced by hifive's own identity. Don't add anything copied from another product.

Brand: write **hifive** in lowercase in the logo, icon label and splash. Write **Hifive** inside sentences, on the App Store and in docs.

Bundle ID and Android applicationId: `com.anznguyen.hifive`. It cannot change after the app is published.

## Commands

Flutter 3.47.9, Dart 3.13.7, Xcode 27.2, Android SDK 36, JDK 21.

```sh
scripts/check.sh                                              # guards, format, analyze, test
flutter test test/model_test.dart --plain-name "<test name>"  # single test
scripts/install_iphone.sh                                     # Release build, installed over the app on a USB iPhone
```

Devices: iOS Simulator `87E929A8-9364-4443-AC07-69345651B181` (393 × 852); Android emulator `Flutter_API_36`. `flutter_tts` Swift Package Manager notices during iOS builds are expected.

Physical iPhone: builds sign with team `WQ4W9V3W7A`. Install in place with `scripts/install_iphone.sh`, never `flutter install`, which uninstalls first and erases the app's data.

`tool/pixel_snapshot_test.dart` renders every screen to PNG; its header has the command.

## Verification after changes

After every Dart change, run `scripts/check.sh` and fix any failures before reporting. Add or update a test in `test/` for behavior changes.

- **Refactors that should not change the UI:** prove it with `tool/pixel_snapshot_test.dart`. Capture before the first edit, capture again after, and compare with `diff -rq`.
- **Keyboard, focus, gesture or animation changes:** widget tests are not enough. Also run the app on the Simulator or iPhone.
- **Native config or dependency changes:** build both iOS and Android.
- **Reporting:** state what ran and on which device. Don't describe anything that wasn't run as verified.

## Architecture

- **State:** one `AppState` `ChangeNotifier` (`lib/core/app_state.dart`), exposed by `AppScope`. Use `AppScope.of` to subscribe and `AppScope.read` in callbacks. Features change state only through named `AppState` methods, which call `commit()` to notify and queue the save.
- **Persistence:** one JSON blob under `hifive.local.v1`. A new field goes in both `toJson()` and `_apply()`, with a default for older data. Models use hand-written `fromJson`/`toJson` with explicit casts.
- **Enum order:** `StudyMode` and `GradeKind` are stored by index, so only append new values.
- **Load failures:** any failure leaves the defaults whole and sets `storageError`, which makes `commit()` stop saving, so unreadable data isn't overwritten.
- **Replaceable services:** injected through the `AppState` constructor, along with `now`. Each of `AppRepository`, `FeedbackService`, `SystemActions`, `LessonRepository`, `GradingRepository`, `ConversationRepository`, `DeckGenerator` and `InsightRepository` has its own file in `lib/core`, re-exported by `state.dart` or `catalog.dart`. These are the seams for the future backend and AI. Grading is deterministic comparison, and generation selects curated samples.
- **Async catalog:** every repository call returns a `Future`, and each screen that awaits one shows loading, an error with "Thử lại", and an empty state (`lib/widgets/async_view.dart`). Mocks take a `latency`; `fresh()` in tests sets the catalog and chat to zero, and `test/helpers.dart` has failing repositories for error states. Synchronous `MockLessonRepository.topicsNow`/`lessonsNow`/`practiceNow` exist for sample data and tests only.
- **Mock content:** `lib/core/mock_content.dart` gives every topic its own sentences. Conversation lines alternate partner (`Question.partner`) and learner; partner lines are excluded from scores.
- **Sample data:** `main.dart` passes `includeExamples: true` to seed three sample results. Tests don't.

## Conventions

- Follow `docs/design-system.md` for type, color, spacing, shape, components and motion. Reuse its tokens and widgets; a new pattern goes into that file.
- Each `lib/features/<area>/` has one file per screen plus a barrel named after the area. Add new files to the barrel. Inside an area, import sibling files; across areas, import the barrel. `HomeScreen` is the root.
- Reuse `lib/widgets/common.dart`: `go(context, page)` for navigation, `toast`, `confirm`, `AppPage`, `Header`, `ActionButton`, `Surface`.
- Text styles use `D.text(...)` from `lib/core/design.dart`. `HomeDesign` holds values for Home only.
- Features contain no color literals: use `D` for shared colors and `Palette` for screen-specific ones. `Colors.white`, `black` and `transparent` are fine.
- Widgets used by more than one feature go in `lib/widgets`. Features must not import each other in a cycle.
- UI strings are inline Vietnamese; there are no ARB files. Illustrations are widgets and vector geometry.
- Give interaction targets a `ValueKey('kebab-case')` or tooltip, which is how tests find them.
- Tests use `fresh()` and `mount()` from `test/helpers.dart`, which give `MemoryAppRepository`, `SilentFeedback`, a pinned clock and the 393 × 852 viewport. Widget test files need `setUpAll(loadAppFonts)`; without it, the test font causes false overflow errors.
- Pass `animateAmbient: false` when a test must settle, because the Home orb loops.
- The local Plus screen must not start a purchase or trial.

## Working rules

- **Read what a command writes before running it.**
- **Prove a bug fix:** the new test must fail on the old code.
- **Tests must assert behavior,** not only that a screen renders.
- **Confirm outputs exist before deleting their source, and never chain the delete.** zsh doesn't word-split `$var`, so loop over files with `while read`.
- **Check state instead of assuming it:** remotes, git identity, connected devices and whether a tool is running.
- **Make one commit per concern, and never push unless asked.**

## Git commits

Every commit message follows @docs/git-commit-rules.md: Conventional Commits (`type(scope): description`), an imperative title under 50 characters (72 at most) with no final period, a blank line, then a plain-text bullet body wrapped at 72 that adds only what the title doesn't say. Never add a `Co-Authored-By` or other AI attribution trailer.
