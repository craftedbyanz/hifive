# CLAUDE.md

Guidance for Claude Code in this repository.

## Language

Reply to the user in Vietnamese in chat. Write everything recorded in files (docs, code comments, notes, logs, skills) in English. Exception: the app's UI strings, which live in the ARB files in each of their languages.

## Project

hifive is an offline-first Flutter (iOS + Android) language-learning app with accounts and a sync Worker; there is no AI or billing yet. It will support several languages; English is the first course.

The code started from a private prototype that re-created another app's UI. Its screens, copy, colors and artwork are being replaced by hifive's own identity. Don't add anything copied from another product.

Brand: write **hifive** in lowercase in the logo, icon label and splash. Write **Hifive** inside sentences, on the App Store and in docs.

IDs, which can't change after publishing: iOS bundle ID `com.anznguyen.hifive.release`, Android applicationId `com.anznguyen.hifive`. iOS signs with team `7GH7MJS7R2`.

## Commands

Flutter 3.47.9, Dart 3.13.7, Xcode 27.2, Android SDK 36, JDK 21.

```sh
scripts/check.sh                                              # guards, format, analyze, Flutter and Worker tests
flutter test test/domain/model_test.dart --plain-name "<test name>"  # single test
scripts/install_iphone.sh                                     # Release build with sync, installed over the app on the iPhone
scripts/make_icons.sh                                         # render the app icons and launch images from the logo painter
(cd worker && npx wrangler dev)                               # run the Worker locally; first `npx wrangler d1 migrations apply hifive --local`
```

Devices: iOS Simulator `87E929A8-9364-4443-AC07-69345651B181` (393 × 852); Android emulator `Flutter_API_36`. `flutter_tts` Swift Package Manager notices during iOS builds are expected.

Never use `flutter install` on the iPhone: it uninstalls first and erases the app's data.

Firebase project `hifive-3371b` (Spark plan); the `firebase-config` skill has the setup.

`tool/pixel_snapshot_test.dart` renders every screen to PNG; its header has the command.

## Verification after changes

After every Dart change, run `scripts/check.sh` and fix any failures before reporting. Add or update a test in `test/` for behavior changes, in the folder that mirrors the code under test (`test/features/<area>/`, `test/state/`, …); `test/app/` holds tests that cross several screens.

- **Refactors that should not change the UI:** capture `tool/pixel_snapshot_test.dart` before the first edit and after, and compare with `diff -rq`.
- **Keyboard, focus, gesture, animation or navigation changes:** also run the app on the Simulator or iPhone.
- **Native config or dependency changes:** build iOS, and Android unless the user has set Android aside.
- **Reporting:** state what ran and on which device. Don't describe anything that wasn't run as verified.

## Architecture

- **State:** one `AppState` `ChangeNotifier` (`lib/state/app_state.dart`, barrel `lib/state/state.dart`), exposed by `AppScope`. Use `AppScope.of` to subscribe and `AppScope.read` in callbacks. Features change state only through named `AppState` methods, which call `commit()` to notify and queue the save.
- **Persistence:** offline-first records in SQLite (`SqliteRecordStore`, file `hifive.db`), one row per setting, session, deck, card, review, game and so on, each stamped with an HLC for sync (`docs/backend-plan.md`). `AppState` methods queue only the records they change (`_put`, `_setting`, `_device`) and `commit()` writes them in one transaction. `restore()` in `lib/state/app_records.dart` rebuilds state from records; derived values (card schedules, game totals, first use) are never stored. A new setting goes in `stringSettings`/`boolSettings` with its setter; a new kind of data needs a record kind and a merge rule in the plan. The old `hifive.local.v1` blob is imported once by `importLegacy()`. Models use hand-written `fromJson`/`toJson` with explicit casts.
- **Enum order:** `StudyMode` and `GradeKind` are stored by index, so only append new values. `Language` is stored by its `code`.
- **Courses:** `AppState.language` is the study language (default English). Every repository and `DeckGenerator` call takes it; `courses()` says which languages have content (only English; the others show "Sắp ra mắt"). Speak words with `AppState.speak`.
- **Load failures:** any failure leaves the defaults whole and sets `storageError`, which stops `commit()` from saving, so unreadable data isn't overwritten. Ids for anything the learner creates come from `AppState.newId()` (UUID v7).
- **Replaceable services:** interfaces injected through the `AppState` constructor, along with `now`. Repositories live in `lib/domain/repositories/`, mocks in `lib/data/mock/`, storage in `lib/data/local/`, Firebase auth in `lib/data/remote/`; `FeedbackService`, `SystemActions` and the platform channels are in `lib/core/services/`. `createAppState` (`lib/app/app_state_factory.dart`) is the composition root. Only `lib/app` and `main.dart` may import `lib/data`; `scripts/check.sh` enforces it. Grading is deterministic comparison, and generation selects curated samples.
- **Async catalog:** every repository call returns a `Future`, and each screen that awaits one shows loading, an error with "Thử lại", and an empty state (`lib/widgets/async_view.dart`). Mocks take a `latency`; `fresh()` sets it to zero, and `test/helpers.dart` has failing repositories for error states.
- **Vocabulary core:** `lib/domain/vocab/` holds FSRS, memory levels, today's plan, exercises, memory insight and the catalog parser. A card's memory is derived by replaying `review` events grouped by `wordKey`, never stored, and one word in several decks is one memory. Cards put away for a day or more come due at 04:00 of their day (`dueAfter`). Home's today, reminders and decks open the flashcard session (`ReviewScreen`); Trí nhớ's Luyện tập opens the exercises (`TodayScreen`). The word catalog comes from the Worker (`/v1/catalog`) and is cached. Plan: `docs/memory-plan.md`.
- **Reminders:** `ReminderSync` schedules the daily review reminders 30 days ahead over the `hifive/screen` channel (`ScreenLock`); the iOS delegate also answers notification permission and opens today's review when a reminder is tapped. Android has no native side yet.
- **Garden:** `lib/domain/garden/` derives trees from `focus` records and from reviews of new or due cards; nothing else is stored. Art in `lib/widgets/garden/`, screens in `lib/features/garden/`. Over `hifive/screen` the iOS delegate reports the phone locking and shows the wither warning; `FocusShield` (`hifive/shield`, iOS 16+) blocks chosen apps, with Family Controls only in Debug and Profile until Apple approves it. The Live Activity (`FocusLive`, `ios/FocusActivity/`) is parked until the developer account holder creates its App IDs. Plan: `docs/garden-plan.md`.

## Conventions

- Follow `docs/design-system.md` for type, color, spacing, shape, components and motion. Reuse its tokens and widgets; a new pattern goes into that file.
- **Accounts are required.** `AuthGate` (`lib/features/welcome/`) shows `WelcomeScreen` (demos above Apple, Google and email sign-in; keep email sign-in, App Review's test account uses it) until the learner signs in. An account without the synced `onboarded` setting waits for its first sync (`AppState.awaitingAccount`), then goes through `OnboardingScreen`, which calls `completeOnboarding`; then Home. Signing out returns to sign-in. Tests that pump `HifiveApp` pass `fresh(auth: signedIn())`; `fresh()` marks the account onboarded unless given `onboarded: false`.
- Each `lib/features/<area>/` has one file per screen plus a barrel named after the area; add new files to the barrel. Past about 500 lines, move a screen's private widgets into `part` files next to it, kept out of the barrel. Inside an area, import sibling files; across areas, import the barrel. `HomeScreen` is the root.
- Reuse the shared widgets behind `lib/widgets/common.dart` (`go`, `toast`, `confirm`, `sheet`, `AppPage`, `Header`, `ActionButton`, `Surface`, `Glass`, …). A new shared widget goes in the file for its kind and is exported from the barrel. Widgets used by more than one feature go in `lib/widgets`.
- Text styles use `D.text(...)`, and `D.system(...)` for lesson content (`lib/core/design/design.dart`). `HomeDesign` holds values for Home only. Per-mode looks come from `StudyModeLook` (`lib/widgets/mode_look.dart`), because `lib/core` must not import `lib/domain`.
- Features contain no color literals: use `D` for shared colors and `Palette` for screen-specific ones. `Colors.white`, `black` and `transparent` are fine.
- Features must not import each other in a cycle (`tool/feature_cycles.dart`). Home may import any area; a screen two areas both open belongs to the area that owns its data.
- UI strings live in `lib/l10n/app_<code>.arb`: Vietnamese is the template, with English, Simplified Chinese and Korean beside it. Read them with `context.t.<key>`; add a key to all four files, then `flutter gen-l10n`. Stored or synced values (card styles, difficulty, chat tone, level ids) keep their old words and are named for display by a helper. Lesson content, the dictionary and grading explanations stay in their own language. Tests read Vietnamese.
- Illustrations are widgets and vector geometry.
- Give interaction targets a `ValueKey('kebab-case')` or tooltip, which is how tests find them.
- Tests use `fresh()` and `mount()` from `test/helpers.dart` (memory store, silent feedback, pinned clock, 393 × 852 viewport). Widget test files need `setUpAll(loadAppFonts)`, or the test font causes false overflow errors. Pass `animateAmbient: false` when a test must settle.
- The local Plus screen must not start a purchase or trial.

## Working rules

- **Read what a command writes before running it.**
- **Prove a bug fix:** the new test must fail on the old code.
- **Tests must assert behavior,** not only that a screen renders.
- **Confirm outputs exist before deleting their source, and never chain the delete.** zsh doesn't word-split `$var`, so loop over files with `while read`.
- **Check state instead of assuming it:** remotes, git identity, connected devices and whether a tool is running.
- **Commits:** one commit per concern on `main`, no branches. When a task is done and `scripts/check.sh` passes, commit and push `main` without asking. Never force-push; rebase if `origin/main` moved.
- **Commit messages:** one line only, Conventional Commits (`type(scope): description`), imperative, under 72 characters, no final period, no body. Never add `Co-Authored-By` or any other attribution.

## Worker

`worker/` is the sync API on Cloudflare Workers; `worker/CLAUDE.md` has its rules and the `deploy-worker` skill its deploy. The app syncs only when built with `--dart-define=HIFIVE_API=https://hifive-api.hifive-worker.workers.dev`, which `scripts/install_iphone.sh` and the TestFlight build pass; plain `flutter run` stays offline.

`docs/backend-plan.md` holds the offline-first and sync design (records, HLC, merge rules per kind). Follow its local data model when changing what the app stores.
