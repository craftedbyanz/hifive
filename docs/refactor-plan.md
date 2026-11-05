# Structure refactor plan

Goal: a folder structure that can grow to several study languages and a focus mode without touching unrelated code. Each task lands as its own commits and is reviewed before the next one starts. Tasks marked "no UI change" are proven with `tool/pixel_snapshot_test.dart` (before and after captures compared with `diff -rq`).

Status values: todo, in progress, done.

## Target layout

```
lib/
  main.dart
  app/                 HifiveApp, createAppState (composition root)
  core/
    design/            D tokens, Palette
    services/          FeedbackService, SystemActions
  domain/
    models/            plain data classes and enums
    repositories/      repository interfaces only
  data/
    local/             AppRepository implementations
    mock/              Mock* repository implementations
    content/en/        English lesson, deck and help content
  state/               AppState, AppScope
  features/<area>/     one file per screen plus a barrel
  widgets/             widgets shared by several features
test/                  mirrors lib/
```

## Tasks

### 1. Split `lib/core` into layers (no UI change) - done

1. Design (done): `core/design.dart` becomes `core/design/` with `tokens.dart` (D) and `palette.dart` (Palette); `HomeDesign` moves to `features/home/home_design.dart`.
2. Models (done): `core/models.dart` becomes `domain/models/`, one file per concept, with a barrel; answer grading and word diffs move to `domain/grading.dart`.
3. Repositories (done): interfaces go to `domain/repositories/`, mocks to `data/mock/`, storage to `data/local/`, content to `data/content/en/`.
4. State and services (done): `AppState` and `AppScope` go to `state/`; feedback and system actions go to `core/services/`.

### 2. Split `widgets/common.dart` (no UI change) - done

Separate navigation, buttons, sheets and dialogs, surfaces and branding into their own files behind a `common.dart` barrel.

### 3. Remove import cycles between features (no UI change) - done

The cycle was learning -> insights (CompletionScreen) -> history (ResultScreen) -> learning. Both screens show a finished study session, so they moved to `learning`, and the small flag they share moved to `widgets/glyphs.dart` as `MiniFlag`. This keeps navigation typed, so the planned `app/routes.dart` indirection was not needed. `tool/feature_cycles.dart` now fails `scripts/check.sh` on any cycle.

### 4. Composition root (no UI change) - done

`HifiveApp` moved from `main.dart` to `lib/app/hifive_app.dart`. `AppState` now requires every repository and its seed decks, and `createAppState` in `lib/app/app_state_factory.dart` supplies the mocks, seed decks and sample history. `state/state.dart` no longer re-exports `data/local`. `scripts/check.sh` fails when `core`, `domain`, `state` or `widgets` import `lib/data`.

### 5. Add study language and course (behavior change) - done

1. `Language` (saved by code) and `Course` live in `domain/models/course.dart`; `AppState.language` is saved, with English for older data.
2. Every `LessonRepository` call takes the language. `courses()` reports which have content, and `generator()` replaces `suggestions()` so the generator screen no longer reads `data/content/en/lessons.dart`.
3. `FeedbackService.speak` takes a locale; `AppState.speak` passes the course's `speechLocale`.
4. The language screen loads courses through the repository and saves the choice on "Xác nhận"; the profile row shows the study language.

Follow-up (done): `GradingRepository`, `ConversationRepository` and `DeckGenerator` also take the language, and Home's flag shows the study language. Flag painters and `languageFlag` live in `widgets/glyphs.dart`.

### 6. Tidy tests and dependencies - done

Tests moved into folders that mirror `lib/` (`test/app/` holds tests that cross several screens), and the unused `integration_test` dependency is gone.
