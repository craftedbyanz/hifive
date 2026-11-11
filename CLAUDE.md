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
flutter test test/domain/model_test.dart --plain-name "<test name>"  # single test
scripts/install_iphone.sh                                     # Release build with sync, installed over the app on an iPhone by USB, or by Wi-Fi when paired
(cd worker && npm test)                                       # sync Worker tests (TypeScript, D1 on Miniflare)
(cd worker && npx wrangler dev)                               # run the Worker locally; apply migrations first with `npx wrangler d1 migrations apply hifive --local`
```

Devices: iOS Simulator `87E929A8-9364-4443-AC07-69345651B181` (393 × 852); Android emulator `Flutter_API_36`. `flutter_tts` Swift Package Manager notices during iOS builds are expected.

Firebase project `hifive-3371b` (Spark plan). `lib/firebase_options.dart`, `ios/Runner/GoogleService-Info.plist` and `android/app/google-services.json` come from `flutterfire configure --project=hifive-3371b --platforms=ios,android`; re-run it after adding an app or provider, and register new Android signing keys with `firebase apps:android:sha:create`. The `xcodeproj` Ruby gem it needs is installed with `gem install --user-install`.

Physical iPhone: builds sign with team `WQ4W9V3W7A`. Install in place with `scripts/install_iphone.sh`, never `flutter install`, which uninstalls first and erases the app's data.

`tool/pixel_snapshot_test.dart` renders every screen to PNG; its header has the command.

## Verification after changes

After every Dart change, run `scripts/check.sh` and fix any failures before reporting. Add or update a test in `test/` for behavior changes, in the folder that mirrors the code under test (`test/features/<area>/`, `test/state/`, …); `test/app/` holds tests that cross several screens.

- **Refactors that should not change the UI:** prove it with `tool/pixel_snapshot_test.dart`. Capture before the first edit, capture again after, and compare with `diff -rq`.
- **Keyboard, focus, gesture or animation changes:** widget tests are not enough. Also run the app on the Simulator or iPhone.
- **Native config or dependency changes:** build both iOS and Android.
- **Reporting:** state what ran and on which device. Don't describe anything that wasn't run as verified.

## Architecture

- **State:** one `AppState` `ChangeNotifier` (`lib/state/app_state.dart`, barrel `lib/state/state.dart`), exposed by `AppScope`. Use `AppScope.of` to subscribe and `AppScope.read` in callbacks. Features change state only through named `AppState` methods, which call `commit()` to notify and queue the save.
- **Persistence:** offline-first records in SQLite (`SqliteRecordStore`, file `hifive.db`), one row per setting, session, deck, card, review, game and so on, each stamped with an HLC so devices can sync (`docs/backend-plan.md`). `AppState` methods queue only the records they change (`_put`, `_setting`, `_device`) and `commit()` writes them in one transaction; `restore()` in `lib/state/app_records.dart` rebuilds state from records, and derived values (card schedules, game totals, first use) are never stored. A new setting goes in `stringSettings`/`boolSettings` and its setter; a new kind of data needs a record kind and a merge rule in the plan. The old `hifive.local.v1` blob is imported once by `importLegacy()` and left untouched. Models use hand-written `fromJson`/`toJson` with explicit casts.
- **Enum order:** `StudyMode` and `GradeKind` are stored by index, so only append new values. `Language` is stored by its `code`.
- **Courses:** `AppState.language` is the study language (default English). Every `LessonRepository`, `GradingRepository`, `ConversationRepository` and `DeckGenerator` call takes it, `courses()` says which languages have content (only English today; the others show "Sắp ra mắt" and can't be confirmed), and `generator()` serves the AI chooser's presets and sample prompts. Speak words with `AppState.speak`, which passes the language's `speechLocale` to `FeedbackService.speak`.
- **Load failures:** any failure leaves the defaults whole and sets `storageError`, which makes `commit()` stop saving, so unreadable data isn't overwritten. Ids for anything the learner creates come from `AppState.newId()` (UUID v7).
- **Replaceable services:** injected through the `AppState` constructor, along with `now`. `AppState` requires every repository and the seed decks; `createAppState` in `lib/app/app_state_factory.dart` is the composition root that fills in the mocks and English content, and `HifiveApp` lives in `lib/app/hifive_app.dart` (barrel `lib/app/app.dart`). Only `lib/app` and `main.dart` may import `lib/data`; `scripts/check.sh` enforces it for `core`, `domain`, `state`, `widgets` and `features`. Each of `RecordStore`, `AppRepository` (the old blob, read once), `AuthService` (Firebase in `lib/data/remote/`, `MemoryAuthService` in tests), `FeedbackService`, `SystemActions`, `LessonRepository`, `GradingRepository`, `ConversationRepository`, `DeckGenerator` and `InsightRepository` is an interface: repositories live in `lib/domain/repositories/` (barrel `repositories.dart`), with mocks in `lib/data/mock/` and storage in `lib/data/local/` (barrel `lib/data/data.dart`); `FeedbackService` and `SystemActions` are in `lib/core/services/`. Features depend on the interfaces, never on `lib/data`; app copy that is the same for every course, such as the help articles (`features/information/help_content.dart`), lives in its feature. These are the seams for the future backend and AI. Grading is deterministic comparison, and generation selects curated samples.
- **Async catalog:** every repository call returns a `Future`, and each screen that awaits one shows loading, an error with "Thử lại", and an empty state (`lib/widgets/async_view.dart`). Mocks take a `latency`; `fresh()` in tests sets the catalog and chat to zero, and `test/helpers.dart` has failing repositories for error states. Synchronous `MockLessonRepository.topicsNow`/`lessonsNow`/`practiceNow` exist for sample data and tests only.
- **Mock content:** `lib/data/content/en/lessons.dart` gives every topic its own sentences. Conversation lines alternate partner (`Question.partner`) and learner; partner lines are excluded from scores.
- **Sample data:** `main.dart` passes `includeExamples: true` to `createAppState` to seed three sample results. Tests don't.

## Conventions

- Follow `docs/design-system.md` for type, color, spacing, shape, components and motion. Reuse its tokens and widgets; a new pattern goes into that file.
- **Accounts are required.** `AuthGate` (`lib/features/welcome/`) shows `WelcomeScreen` (auto-playing demos above Apple, Google and email sign-in; email opens `EmailSignInForm` in a sheet) until the learner signs in. A signed-in account without the synced `onboarded` setting first waits for its first sync (`AppState.awaitingAccount`), then goes through `OnboardingScreen` (a welcome with the four ways to practise, demos to try for flashcards, writing, grammar and conversation, then name, level, goals and `PreparingView`), which calls `completeOnboarding`; then Home. Signing out closes every page and returns to sign-in. Tests that pump `HifiveApp` pass `fresh(auth: signedIn())`; `fresh()` marks the account onboarded unless given `onboarded: false`.
- Each `lib/features/<area>/` has one file per screen plus a barrel named after the area. Add new files to the barrel. When a screen file grows past about 500 lines, move its private widgets into `part` files next to it (`part of '<screen>.dart';`), named for what they hold; part files stay out of the barrel. Inside an area, import sibling files; across areas, import the barrel. `HomeScreen` is the root.
- Reuse the shared widgets behind the `lib/widgets/common.dart` barrel: `go(context, page)` and `toast` (`navigation.dart`), `confirm` and `sheet` (`sheets.dart`), `AppPage` and `Header` (`page.dart`), `ActionButton` (`buttons.dart`), `Surface` and `Glass` (`surfaces.dart`). Put a new shared widget in the file for its kind and export it from the barrel.
- Text styles use `D.text(...)` from `lib/core/design/tokens.dart`, and `D.system(...)` (SF Pro with its tracking) for lesson content (import the `lib/core/design/design.dart` barrel). `HomeDesign` (`lib/features/home/home_design.dart`) holds values for Home only. Per-mode color, icon, card look and answer color come from the `StudyModeLook` extension (`lib/widgets/mode_look.dart`), because `lib/core` must not import `lib/domain`.
- Features contain no color literals: use `D` for shared colors and `Palette` for screen-specific ones. `Colors.white`, `black` and `transparent` are fine.
- Widgets used by more than one feature go in `lib/widgets`. Features must not import each other in a cycle; `tool/feature_cycles.dart`, run by `scripts/check.sh`, enforces it. Home is the root and may import any area; a screen two areas both open belongs to the area that owns its data (session results live in `learning`).
- UI strings are inline Vietnamese; there are no ARB files. Illustrations are widgets and vector geometry.
- Give interaction targets a `ValueKey('kebab-case')` or tooltip, which is how tests find them.
- Tests use `fresh()` and `mount()` from `test/helpers.dart`, which give `MemoryRecordStore`, `SilentFeedback`, a pinned clock and the 393 × 852 viewport. Widget test files need `setUpAll(loadAppFonts)`; without it, the test font causes false overflow errors.
- Pass `animateAmbient: false` when a test must settle, because the Home orb loops.
- The local Plus screen must not start a purchase or trial.

## Working rules

- **Read what a command writes before running it.**
- **Prove a bug fix:** the new test must fail on the old code.
- **Tests must assert behavior,** not only that a screen renders.
- **Confirm outputs exist before deleting their source, and never chain the delete.** zsh doesn't word-split `$var`, so loop over files with `while read`.
- **Check state instead of assuming it:** remotes, git identity, connected devices and whether a tool is running.
- **Make one commit per concern, and never push unless asked.**

## Worker

`worker/` is the sync API on Cloudflare Workers, deployed with `(cd worker && npx wrangler deploy)` to `https://hifive-api.hifive-worker.workers.dev` (personal Cloudflare account, D1 `hifive` in APAC). The app syncs only when built with `--dart-define=HIFIVE_API=<that address>`, which `scripts/install_iphone.sh` passes; plain `flutter run` stays offline-only. Apply a new migration remotely with `(cd worker && npm run migrate:remote)` before deploying code that needs it. (TypeScript, D1); see `docs/backend-plan.md`. `src/auth.ts` verifies Firebase ID tokens (401 for a bad token, 503 when Google's keys can't be fetched), `src/sync.ts` validates and applies `POST /v1/sync` in one D1 batch, and `migrations/` holds the D1 schema; a new table or column is a new numbered migration, never an edit to an applied one. Tests use `@cloudflare/vitest-plugin`, which isolates storage per file only, so `test/setup.ts` empties the tables before each test.

## Backend plan

`docs/backend-plan.md` holds the offline-first and sync design (records, HLC, merge rules per kind) and its steps. Follow its local data model when changing what the app stores.

## Git commits

Every commit message follows @docs/git-commit-rules.md: Conventional Commits (`type(scope): description`), an imperative title under 50 characters (72 at most) with no final period, a blank line, then a plain-text bullet body wrapped at 72 that adds only what the title doesn't say. Never add a `Co-Authored-By` or other AI attribution trailer.
