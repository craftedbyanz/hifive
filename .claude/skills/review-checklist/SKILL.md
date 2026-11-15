---
name: review-checklist
description: hifive's review checklist - check a change before committing it, or audit the app's core flows (vocabulary, today's review, decks, memory, history, reminders and notifications) for bugs. Use when the user asks to review, audit, check or "rà soát" a change, a feature or the app's flows.
---

# Review checklist

Report findings ranked by severity, each with `file:line`, what goes wrong and a concrete scenario. Prove a suspected bug with a small test (a temporary probe test is fine; delete it after) before calling it confirmed. Say what ran and on which device; nothing unrun counts as verified.

## A. A change, before it is committed

**Checks**
- [ ] `scripts/check.sh` passes: guards, format, analyze, feature cycles, Flutter tests and Worker tests.
- [ ] A bug fix has a test that fails on the old code. Prove it by stashing only the `lib/` change and running the test.
- [ ] Tests assert behaviour, not only that a screen renders.

**Layers and state**
- [ ] Only `lib/app` and `main.dart` import `lib/data`; `lib/core` imports no outer layer.
- [ ] Features change state only through named `AppState` methods that `commit()`.
- [ ] New stored data has a record kind and a merge rule (`docs/backend-plan.md`). Derived values (schedules, memory, garden, totals) are never stored.
- [ ] `StudyMode` and `GradeKind` values are only appended.
- [ ] Ids come from `AppState.newId()`.

**UI**
- [ ] No color literals in features; use `D` or `Palette`.
- [ ] Strings are in all four ARB files, then `flutter gen-l10n`.
- [ ] Tap targets have a `ValueKey` or tooltip.
- [ ] Shared widgets are reused from `lib/widgets/common.dart`.

**Extra runs for some changes**
- [ ] Refactors that shouldn't change the UI: `tool/pixel_snapshot_test.dart` captured before and after, compared with `diff -rq`.
- [ ] Keyboard, focus, gesture, animation or navigation changes: run on the Simulator or iPhone too.
- [ ] Native or dependency changes: build iOS (`flutter build ios --simulator --debug`), and Android unless the user has set Android aside.
- [ ] Worker changes: a new numbered migration, never an edit to an applied one.

**Docs**
- [ ] `CLAUDE.md` and `docs/*-plan.md` still describe what the code does.

## B. Audit the core flows

Walk each flow in the code end to end (entry point, `AppState` method, domain logic, what is shown after), then probe the doubtful parts with tests under a movable clock (`createAppState(now: () => clock)`).

- **Vocabulary memory** (`lib/domain/vocab/`, `AppState.rate`, `uniqueWords`, `replayReviews`): one word in several decks is one memory. Every path that adds a card (`saveWord`, `addWords`, `addDeck`, imports) must carry the existing memory, or the word shows as new until the next launch. The state after an action must match the state after a reload.
- **Due times** (`scheduler.dart` `dueAfter`): intervals of a day or more come due at 04:00 of their study day. Today's plan, the deck's "Ôn tập (N)", the Memory forecast and the reminder count must all agree for a word learned in the evening.
- **Daily limits** (`planToday`, `newWordsLeft`, `deckReview`): no entry point offers more new words than `newPerDay` allows; only an explicit "Ôn tập tất cả" does.
- **Sessions** (`ReviewScreen` for Home, reminders and decks; `TodayScreen` for Trí nhớ's Luyện tập): Học lại and Khó while learning come back before the end. Progress counts a word only when it is answered. Each entry logs the right `source`, `mode` and `skill`; mastery needs `recall` or `use`.
- **Reminders and notifications** (`ReminderSync`, `ScreenLock`, `ios/Runner/AppDelegate.swift`): the switch syncs but permission is per phone. Check an unasked phone, permission denied in Settings, the 30-day schedule, a day already studied, `newPerDay` 0, and a tap that launches the app. Android has no native side yet.
- **History, streak and study days** (`history_screen.dart`, `clearHistory`, `studyDays`, `streak`): clearing and sync, sample results excluded, day boundaries.
- **Load failures and offline** (`storageError`, `AsyncView`): defaults stay whole, nothing is overwritten, and screens show loading, error with "Thử lại", and empty states.
