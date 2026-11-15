# Garden and focus mode plan

Goal: a garden that grows from two sources, studying vocabulary and general focus sessions (study, writing, work), so hifive is opened every day. The look approved on 15 November 2026 is described in "Garden art" in `docs/design-system.md` (step 8); `docs/mockups/garden.html` is the earlier mockup, kept for its layout and mechanics only. Product context is in `docs/product-notes.md` (Vietnamese). Each step lands as its own commits and is reviewed before the next one starts.

Status values: todo, in progress, done.

## Decisions (13 November 2026)

- Layout and mechanics follow the focus-tree genre: one tree on a floating isometric tile and one big timer on the focus screen; the garden is an isometric grid with Day/Week/Month/Year tabs. Trees, colors and copy are hifive's own. Everything outside these screens keeps the current design system.
- Focus screens use the indigo palette from the logo; the garden screen keeps the app's light background and stat cards.
- 30 species from Vietnam and other countries (each with an `Origin`), shown in six sections by how they unlock (start, memory, diligence, focus, season, legend), drawn in code like the streak flame and menu icons; no image assets. Forms: sprout, young, grown, in bloom, withered. (Until 15 November 2026: 28 species in four groups.)
- Species unlock through learning milestones, not coins. The milestones in the mockup are proposals.
- Leaving the app for more than 30 seconds withers the session's tree. Locking the screen does not. Using hifive during a session does not count as leaving.
- The first 10 seconds of a session can be cancelled without a withered tree.
- After a finished session, the break offers a review of due words; doing it makes the tree bloom.
- Trees are derived on the device from session and review records and synced; days are local days.
- Blocking other apps during a session is built for iOS (step 9); Apple granted the Family Controls distribution entitlement on 15 November 2026. Later, not now: relaxation and ambient sound, coins and a store, challenges. Never: ads or paywall screens inside the flow.

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

### 8. New art, 30 species and the misty focus screen - done

Done on 15 November 2026, after reviewing directions on local pages: the plants are redrawn in a soft illustrated manner (see "Garden art" in `docs/design-system.md`), replacing both earlier manners. Two species were appended, `olive` (Greece) and `mugunghwa` (Korea), for 30; each species has an `Origin` (Vietnamese and foreign plants side by side; the galaxy tree has none). The Dalat pine (`pine`) and the snowy Norway spruce (`snowpine`) are now told apart. The collection is grouped by how species unlock (`SpeciesGroup`: start, memory, diligence, focus, season, legend); baobab and banyan moved to legends. The focus screen drops the progress ring and the floating tile for a misty indigo sky, a sunbeam, rising motes and a pool of sunlit grass where the plant grows from two seed leaves to a tree. Tests: `test/domain/garden_test.dart`, `test/widgets/garden_art_test.dart`, `test/features/garden/`.

### 9. Blocking distracting apps - built, approved by Apple

Done on 15 November 2026, iOS only: the timer sheet has "Chặn ứng dụng gây xao nhãng" (`ShieldRow`), shown on iOS 16 and later. Turning it on asks for Screen Time access (`AuthorizationCenter`, `.individual`) and opens Apple's app picker (`FamilyActivityPicker`) when nothing is chosen; the row then shows how many apps, categories and sites are chosen and opens the picker again. While a session runs, the chosen ones are shielded (`ManagedSettingsStore` named `hifive.focus`); every way a session ends lifts the shield, and so does every app launch, since a session never outlives the app. The switch and the choice stay on the phone (UserDefaults), because Apple's app tokens only mean something there. Dart: `FocusShield` (`lib/core/services/focus_shield.dart`, channel `hifive/shield`); iOS: `FocusShield` in `ios/Runner/AppDelegate.swift`. Tests: `test/features/garden/focus_shield_test.dart`.

Signing: Apple granted Family Controls (Distribution) for `com.anznguyen.hifive.release` on 15 November 2026, and the App Store profile "HiFive AppStore Distribution" now carries `com.apple.developer.family-controls`. The key is in both `ios/Runner/Runner.entitlements` (Release) and `ios/Runner/RunnerDev.entitlements` (Debug and Profile). If the entitlement is ever missing at run time, the switch answers "Bản cài này chưa được Apple cho phép chặn ứng dụng."

Not done: Android (it would need an accessibility service and usage access, which Play reviews strictly), a custom shield screen (a ShieldConfiguration extension), and lifting the shield at the planned end even if the app was killed (a DeviceActivityMonitor extension; for now the next launch lifts it).

### 10. The session on the lock screen and in the Dynamic Island - built, signed for release

Done on 15 November 2026, iOS 16.1 and later: a running session shows as a Live Activity. The lock screen has the plant on its sunlit patch in a light circle, the time left counting down (up for the stopwatch), the tag with its colour, a progress bar and, on iOS 17, a ✕ that ends the session (cancelled in the first ten seconds, given up after that, or planted for a stopwatch past its minimum). The Dynamic Island shows a leaf and the time left, and the plant, time, tag and progress when expanded. The timer and bar run by themselves; the app sends a new picture of the plant whenever it grows a tenth of the way, so while the app is suspended the picture waits until it next runs.

- Widget extension target `FocusActivity` (`ios/FocusActivity/`: `FocusActivityWidget.swift`, `FocusAttributes.swift`, shared with Runner for the attributes and `StopFocusIntent`), embedded in Runner before Flutter's Thin Binary phase. Bundle id `com.anznguyen.hifive.release.FocusActivity`; version and build come from Flutter through `FocusActivity.xcconfig`.
- App Group `group.com.anznguyen.hifive` in both targets: the app writes `focus-plant-<n>.png` there and bumps `plant` in the activity's state.
- Runner: `NSSupportsLiveActivities` in Info.plist; `FocusLive` in `AppDelegate.swift` (channel `hifive/live`); every launch ends leftover activities.
- Dart: `FocusLive` (`lib/core/services/focus_live.dart`) and `plantPicture` (`lib/widgets/garden/garden_art.dart`). Tests: `test/features/garden/focus_live_test.dart`.

Signing (done on 15 November 2026 by the account holder): the App Group `group.com.anznguyen.hifive` is on `com.anznguyen.hifive.release` and on the App ID `com.anznguyen.hifive.release.FocusActivity`. Release signs Runner with the App Store profile "HiFive AppStore Distribution" (it carries the App Group) and the extension with "Hi Five Distribution Profile". When a profile is regenerated, download it and copy it into `~/Library/Developer/Xcode/UserData/Provisioning Profiles/<UUID>.mobileprovision`, removing the old copy of the same name, or Xcode may pick the stale one. Debug and Profile builds sign automatically.

### 11. Second garden rules: sun and water, no farming short sessions - done

Done on 15 November 2026, for sessions and waterings from 16 November 2026 (`gardenRulesSince`); earlier ones keep the first rules, so nothing already planted shrinks and no species locks again. All of it is derived from the existing focus and review records; nothing new is stored.

- A focus session grows a plant by its length (`sizeFor`): under 25 minutes a young plant that doesn't count as a tree, 25 a small tree, 45 a large one, 90 an ancient tree (`PlantSize`). The garden counts mature trees. The focus screen previews the size for the chosen length, and the timer sheet says when it is under 25 or from 90 minutes.
- Milestones count mature sessions only: "20 phiên từ 25 phút" (willow), blooms (lavender) and the comeback (cactus: mature sessions within a week of a withered tree).
- A tree blooms only after a mature session whose break reviewed at least `bloomWords` (5) words, or all of them if fewer were due.
- A withered tree followed within 48 hours by a mature session comes back as a sprout (`revived`).
- Sun and water: focus minutes are sun, counted reviews are water. A study tree takes at most 5 drops a day and grows once it has 10 on 3 different days, the rhythm of spaced review; more water that day starts the next tree. A study tree watered on a day with 25 minutes of focus blooms. A growing study tree left 3 days without water droops (paler, leaning) until watered.
- A rating waters the garden only if it took at least 1.5 s (when timed) and, for a new word, only up to the day's `newPerDay`.
- A tree that bloomed and has stood 30 days in the garden turns ancient: larger, in a warm halo, with drifting motes.
- Weather over the garden (current period only): rain within an hour of watering, clouds while 10 or more words wait, sun otherwise, with a line saying why.
- Weekly quests: 3 mature sessions, 5 days of review and 1 bloom. Each week with all three done earns the next of six decorations (stone lantern, bench, pond, birdhouse, red lantern, flower bed), set along the garden's edges.
- Seeds: every word remembered three weeks or more is a seed; the "known words" unlocks read as seeds.

Not done: unlocking species by deck topic (decks carry no topic yet), and the shared group tree, which needs live presence in circles through the Worker.
