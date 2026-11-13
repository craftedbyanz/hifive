# Garden and focus mode plan

Goal: a garden that grows from two sources, studying vocabulary and general focus sessions (study, writing, work), so hifive is opened every day. The approved look is `docs/mockups/garden.html` (open it in a browser; append `#still` for a still frame). Product context is in `docs/product-notes.md` (Vietnamese). Each step lands as its own commits and is reviewed before the next one starts.

Status values: todo, in progress, done.

## Decisions (13 November 2026)

- Layout and mechanics follow the focus-tree genre: one tree on a floating isometric tile and one big timer on the focus screen; the garden is an isometric grid with Day/Week/Month/Year tabs. Trees, colors and copy are hifive's own. Everything outside these screens keeps the current design system.
- Focus screens use the indigo palette from the logo; the garden screen keeps the app's light background and stat cards.
- 28 species in four groups (start, study, Vietnamese, legend), drawn in code like the streak flame and menu icons; no image assets. Each has five forms: sprout, sapling, young, grown, in bloom.
- Species unlock through learning milestones, not coins. The milestones in the mockup are proposals.
- Leaving the app for more than 30 seconds withers the session's tree. Locking the screen does not. Using hifive during a session does not count as leaving.
- The first 10 seconds of a session can be cancelled without a withered tree.
- After a finished session, the break offers a review of due words; doing it makes the tree bloom.
- Trees are derived on the device from session and review records and synced; days are local days.
- Later, not now: blocking other apps (needs Apple's Family Controls entitlement), relaxation and ambient sound, coins and a store, challenges. Never: ads or paywall screens inside the flow.

## Open questions

1. Whether a focus session keeps the streak (proposed: no; only studying keeps it).
2. Whether a study tree needs ten valid reviews (used for now) or another number.

## Steps

### 1. Domain and records - done

Done on 13 November 2026, in `lib/domain/garden/` (barrel `garden.dart`):

- `FocusSession` (start, end, planned minutes, tag, title, species, outcome done/withered/cancelled, bloomed), stored as the synced `focus` kind; the Worker accepts it and `docs/backend-plan.md` has its merge rule. `AppState.recordFocus` writes it; calling it again with `copyWith(bloomed: true)` rewrites the same row.
- Study growth: `AppState.rate` writes a `tree` field (the chosen `studySpecies`) on a review whose card was new or due. Replay reports those ratings as `StudyCredit`s; `countedCredits` keeps one per card per local day, and every `reviewsPerTree` (10) counted credits make one study tree, of the species on its first credit.
- `species` lists the 28 species with their group and `Unlock` rule; `GardenStats` measures every rule from credits, focus sessions, known cards (memory of three weeks or more) and the streak. `AppState.setStudySpecies` ignores locked species.
- `plantsBetween` gives the trees of a date range for the garden screen; a focus tree's size grows with its minutes up to 60.
- Tags are a fixed `FocusTag` enum for now (English, writing, work, other); editable tags are later.
- Tests: `test/domain/garden_test.dart`, `test/state/garden_state_test.dart`.

### 2. Tree and land painters - done

Done on 13 November 2026 in `lib/widgets/garden/` (shared, since Home and onboarding may show trees too): `garden_kit.dart` mirrors the mockup's canvas calls so every species ported line by line, `garden_species.dart` holds the 28 drawings, `garden_land.dart` the land tile, the form picker and the grid. `TreeArt` and `GardenScene` are the widgets. `tool/garden_art_sheet_test.dart` renders the sheet; `test/widgets/garden_art_test.dart` checks every species and form draws and that the art holds still without ambient motion.

### 3. Focus flow - done on iOS

Done on 13 November 2026: `FocusScreen` (`lib/features/garden/`, opened from a new last item in the Home menu) with setup (tick ring, 10/15/25/45/60 minutes, tag chip that cycles, species picker with locked species dimmed), running (progress ring, the tree growing from a sprout, "Huỷ (n)" for the first 10 seconds and then "Bỏ cuộc" with a confirm), done (the break offers up to eight due words through `ReviewScreen`; a counted review makes the tree bloom) and withered. Leaving the app for more than 30 seconds withers the tree; the iOS app delegate reports the phone locking over the `hifive/screen` channel (`ScreenLock`), which keeps the session going. Strings in all four languages, including the 28 species names. Tests: `test/features/garden/focus_screen_test.dart`.

Also done: a local notification 12 seconds after the app goes to the background warns that the tree is about to wither; the delegate withdraws it when the phone locks or the learner returns. It asks for permission when the first session starts.

Still to do: Android lock detection (`ACTION_SCREEN_OFF`) and the Android warning; checking on the iPhone that locking is told apart from switching apps (protected data goes away about 10 seconds after locking, inside the 30-second grace, and only on a phone with a passcode; without one, locking counts as leaving).

### 4. Garden screen - done

`GardenScreen` (`lib/features/garden/garden_screen.dart`): Day/Week/Month/Year tabs with previous and next (no going past now), the grid of that period's trees (`GardenScene`, growing past 5 × 5 when needed), counts of living and withered trees, focus time, counted waterings and study days in the period, the study tree growing now (tap to choose its species), "Bắt đầu tập trung", and the 28-species collection with each unlock rule (`unlockText`). Tests: `test/features/garden/garden_screen_test.dart`.

### 5. Entry points - done

- The Home menu's last item, "Vườn", with a small animated oak, opens the garden.
- A garden card on Home under Flow Letter shows the study tree growing and opens the garden.
- The flashcard review summary shows "Cây học +N lượt tưới" when the session watered the study tree.
- `docs/design-system.md` has a "Garden art" section.

### 6. Tags, sharing and the home screen widget - done except the widget

Done on 13 November 2026:

- Tags are `FocusTag`s: four built-in (English, writing, work, other) plus the learner's own, saved in the synced `focusTags` setting (id, name, color index into `Palette.tagColors`); `focusTag` remembers the last one. Sessions store the tag id, so renaming a tag renames its past sessions, and deleting one shows them as "other" with their time kept. `TagSheet` picks, makes, renames and deletes tags from the focus screen's tag chip.
- The garden screen shows the period's finished focus time by tag (`AppState.focusByTag`) as bars with time and share.
- The share button above the garden shares a 3× PNG of the garden and its counts with a line of text, through `SystemActions.shareImage` (share_plus).

Not done: the home screen widget (study tree and words due). A widget is a separate WidgetKit extension that reads the app's data through an App Group, and the personal team `WQ4W9V3W7A` can't use the App Groups capability; it waits for the Apple Developer Program (see Deferred in `docs/backend-plan.md`). Then: add the extension target, an App Group shared by both, write the study-tree species, growth and due count there after each change, and reload the widget's timeline.

### 7. Timer ruler, stopwatch and session title - done

Done on 13 November 2026, after the reference video of the focus setup: the tag ("• Học tiếng Anh ›") and an editable session title sit at the top left; tapping the timer opens a frosted sheet (`showTimerSheet`, `lib/features/garden/timer_sheet.dart`) with a ruler of marks every 5 minutes up to 180, which coasts after a flick, settles on a mark and knocks once per mark crossed (`FeedbackService.tap`). Its left end is the stopwatch: it counts up, is fully grown at an hour, stops at 180 minutes, and stopping before 10 minutes plants nothing (after a confirm). The tag picker is a column of frosted pills over the blurred, darkened screen (`showTagSheet`). The sheet's "Deep focus" (blocking other apps) from the reference is left out, as decided.
