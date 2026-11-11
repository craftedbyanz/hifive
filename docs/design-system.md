# Design system

The rules every screen follows, so new work looks like the rest of the app. The values are already in the code; the file and line to reuse is named for each. They were inherited from a prototype measured on a physical iPhone 15 Pro (393 × 852 pt), so "the reference" below means that baseline. hifive's own visual identity will replace these values; when one changes, update this file in the same commit.

## Principles

1. **Reuse before you build.** Look for the token or widget below first. A second copy of a pattern (a spaced-caps label, a glass button, a pill) is a bug.
2. **Decide once, then reuse.** A new value is chosen deliberately and recorded here. A value nobody measured or decided is written as such in a code comment.
3. **Points, not pixels.** Every size is in iOS points at the 393 pt width. Screenshots are 3×.
4. **Default text size is the baseline.** Text scales from 1 (it never shrinks below the default) to 23/17 at the largest standard size. Any fixed height or width that holds text uses `context.grow(value)` so it grows with it.
5. **No color literals in features.** Use `D` for shared colors and `Palette` for screen-specific ones (`lib/core/design/`).

## Logo

Chosen on 11 November 2026: five rounded bars on an ink tile (`AppLogo`, `LogoPainter` in `lib/widgets/branding.dart`). The bars read as a hand raised for a high five and as a voice's sound wave; left to right they take conversation cyan, writing blue, indigo, grammar violet and AI purple (`Palette.logoBars`). Geometry is on a 1024 grid: bars 84 wide with full round ends, 40 apart, standing on y 760; tile corner 230 (superellipse).

- With the wordmark, the tile sits left of lowercase **hifive** in Plus Jakarta Sans 800, −1 tracking, about 0.8× the tile's height.
- App icons and launch images are rendered from `LogoPainter` by `scripts/make_icons.sh`; never edit the PNGs by hand. iOS icons are square and opaque (iOS rounds them); the Android adaptive icon is the bars at 70% on `ic_launcher_background` (ink).
- Launch screens show the 120 pt tile centred on white on both platforms.

## Typography

Two families, each with one job.

| Family | Used for | How |
| --- | --- | --- |
| **Plus Jakarta Sans** (Regular 400, Medium 500, SemiBold 600, Bold 700, ExtraBold 800) | All app chrome: titles, labels, buttons, cards, numbers | `D.text(size, weight:, color:, height:, spacing:)` |
| **SF Pro** (system) | Lesson content and system UI: the prompt and answer, feedback explanations and tips, the paragraph, iOS alerts, TipKit tips, onboarding body lines | `D.system(size, ...)`, which picks `'CupertinoSystemText'` below 20 pt and `'CupertinoSystemDisplay'` at 20 pt and above and sets the tracking below |

SF Pro Text needs its optical tracking set by hand (Flutter does not apply it): 17 pt −0.43, 16 −0.31, 15 −0.23, 14 −0.15, 13 −0.08. An explicit `letterSpacing` replaces SF Display's own tracking, so Display text that sets one must add it back (the grammar answer uses 0.75 at 21 pt).

### Type scale

Use these roles; do not invent a new size for an existing role.

| Role | Style | Example |
| --- | --- | --- |
| Page hero title | 38 / w800, −2 tracking, 1.04 line | "Viết nên / câu chuyện" |
| Onboarding step title | 26 / w800, −0.6, line 32: an ink line, then an accent line in the step's color; body SF Pro 15, secondary, line 21 | "Chào mừng / đến với Hifive" |
| Collection title | 28 / w800, −0.5, line 1.24 | "Di sản và lịch sử." |
| Home greeting | `HomeDesign.greeting` 28 / w700, −0.87 | Home only |
| Card title, large | 27 / w800, −1, line 1.26 | Collection set card |
| Section title | 20 / w700 | History "Đoạn văn", Home "Chế độ học tập" (`HomeDesign.section`) |
| Navigation title | 16–17 / w600–700, centred | "Bài học", "Ôn tập" |
| Body | 13–15 / w400–500, secondary ink | descriptions |
| Tile title | 13 / w800, −0.5, line 1.28, no orphan word (`NoOrphanText`) | Topic tile |
| Button label | 13 / w600 (inline pill), 16 / w700 (full-width) | |
| Spaced caps label | `CapsLabel` — 10 / w700, muted, 2 tracking | "DANH MỤC", "BỘ SƯU TẬP", "MÔ TẢ CHỦ ĐỀ" |
| Small caps label | `CapsLabel(small: true)` — 9 / w800, muted, 1.8 tracking | "GIẢI THÍCH", "MẸO" |
| Caption | 11–12 / w500–600, muted | "14 Sets", "Câu 1, 2, 3" |
| Lesson prompt | SF Pro Bold 24, line 1.44 | Grammar prompt |
| Lesson answer | SF Pro Display 21 / w500, line 1.24, 0.75 tracking | Answer card |
| Paragraph | SF Pro 17 / w500, line 1.53, −0.43 | Writing lesson |

`HomeDesign` (`features/home/home_design.dart`) holds values measured for Home only; reuse them elsewhere only with evidence of the same style.

## Color

### Core (`D`)

| Token | Hex | Use |
| --- | --- | --- |
| `ink` | #111827 | Primary text, dark buttons |
| `secondary` | #6B7280 | Body and descriptions |
| `muted` | #9CA3AF | Labels, captions, inactive icons |
| `line` | #E7E9ED | Hairlines, dividers, inactive dots |
| `background` | #F8FBFC | Page background |
| `blue` | #3B82F6 | Accent, writing mode, links |
| `green` | #10B98A | Correct, success |
| `orange` | #FF7919 | Streak |
| `purple` | #A34EF5 | AI, writing corrections |

### Mode colors

Writing #3B82F6 (blue), grammar #8A5BF6 (violet), conversation #06B6D4 (cyan) via `mode.color` (`StudyModeLook` in `lib/widgets/mode_look.dart`, which also gives `mode.icon` and `mode.inputColor(name)`). Accents inside a mode follow the reference, not the card color: grammar and writing lessons use lime #D0FD3E (`Palette.grammarAccent`) for the title period, start button and tip bullets; writing uses purple for "SỬA LỖI" and its bullets; conversation uses #2965EA (`Palette.chatBlue`).

### Appearances

The Home and Appearance cards take their fill and ink from `mode.cardLook(appearance)`. Never color a mode card by hand.

| Appearance | Card |
| --- | --- |
| Glass (default) | Mode color at 82% opacity, white ink |
| Regular | Paragraph white with ink, Quick Fix #111111 with white ink |
| Mono | #F2F5F6 with #374151 ink and a #D1D4DB hairline |
| Minimal | White with ink |

### Status

Correct `D.green`, almost `D.orange`, wrong `Palette.wrong` (#EF4444), destructive actions `Palette.alertRed` (#D8232E), system links `Palette.alertBlue` (#0A7AFF).

Light only. The reference stays light in iOS Dark Mode, and so does hifive.

## Spacing and layout

- **Screen margins:** 24 pt for content, 16 pt for the navigation row's buttons, 20 pt on game screens, 9 pt for floating sheets.
- **Grids:** two columns, 167 × 160 tiles with 11 pt between columns and 12 pt between rows.
- **Card stacks:** 9–12 pt between cards in a list; sections 30–35 pt apart.
- **Label to content:** a spaced-caps label sits 16–19 pt above the content it names.
- **Bottom controls** clear the home indicator by 14.5 pt (lesson bar) or float over a fade (result, history search).
- **Wider screens** (Android 411 pt): layouts stretch; anything fixed at a measured width uses `OverflowBox(minWidth: w, maxWidth: w)`, never only `maxWidth`.

## Shape

| Element | Radius |
| --- | --- |
| Hero cards (Home, collection) | 32–38 |
| Tiles and panels | 24–26 |
| Floating sheets | 38 |
| Chips | 13 |
| Pills and capsule buttons | height / 2 |
| Bars and small pills | 2–4 |

Corners use `RoundedSuperellipseBorder` (iOS's continuous corner) on cards and panels that the reference draws that way (Home cards, deck rows, glass menu); plain `BorderRadius` elsewhere.

## Stroke widths

| Width | Use |
| --- | --- |
| 0.5–0.6 | Hairline: glass buttons (`Palette.insightBackEdge`), topic tiles, menus, TipKit tip |
| 1 | Standard outline: cards, pills, chips, sheet buttons (`D.line`) |
| 1.2 | Deck word rows |
| 1.5 | Unselected circles and rings (streak week, minimal swatch) |
| 1.7 | Selected category chip, in the category's colour |
| 2.5 | Progress rings |
| 3 | Swap button ring in the lesson |

Icons drawn with `CustomPainter` use 1.3–1.6 pt strokes (orbit, sliders); bold glyphs 2.6.

## Shadows (elevation)

Four levels. Shadows are ink-tinted (`D.ink`), never pure black, except over a dark game background.

| Level | Shadow | Use |
| --- | --- | --- |
| 0 | none | Inline rows, flat stat cards, lesson cards |
| 1 Low | ink 6%, blur 8, y 3 | Round glass buttons, keys of the lesson bar (5%, blur 6, y 2) |
| 2 Card | ink 4–8%, blur 14–18, y 4–6 (`D.shadow` is 6%, blur 24, y 8) | Tiles, cards, chips, search capsule |
| 3 Floating | ink 14%, blur 30, y 10 | Glass menu, popovers, TipKit tip (25% black, blur 8) |

A filled button can glow in its own colour: fill at 18–25%, blur 12–14, y 5–6 (start buttons, AI arrow). Layered shadows (one tight, one wide) are allowed when measured, as on topic tiles.

## Blur (frosted glass)

`BackdropFilter(ImageFilter.blur(sigmaX: σ, sigmaY: σ))` behind a translucent fill. Pick the σ by layer:

| σ | Use |
| --- | --- |
| 6 | Content under the status bar on scrolling pages, masked to fade out downwards |
| 12 | Pinned headers (`HeaderScrollPage`), game panels |
| 14–16 | Glass capsules and the glass menu |
| 20 | System alert (`confirm`) |
| 22 | Full-screen guides (review guide, voice help) |
| 36 | Home menu overlay |

Glass fills: white at 78–85% on light pages (menu 84%, search capsule 78%, header 78%), white at 12–35% on coloured game gradients, with a white rim at 22–40%.

## Opacity

| Value | Use |
| --- | --- |
| 20% black | Every modal barrier (`Palette.sheetBarrier`) |
| 20% | Pressed state (`PressFade`) |
| 18% | Puzzle behind a solved Flow Letter word |
| 45–55% | Placeholder and hint text on coloured cards; dimmed parent row behind a submenu |
| 70–85% | Secondary text on coloured or dark backgrounds |

Disabled controls change colour (grey #8D8C92 next button, `D.line` fill) instead of fading.

## Contrast

Measured WCAG ratios of the tokens:

| Pair | Ratio |
| --- | --- |
| `ink` on `background` | 17.1 |
| `secondary` on `background` | 4.7 |
| `muted` on `background` | 2.4 |
| White on writing blue | 3.7 |
| White on grammar violet | 4.3 |
| White on conversation cyan | 2.4 |
| White on `chatBlue` | 5.1 |
| Ink on lime | 15.0 |
| `alertRed` on white | 5.0 |

Rules that follow:

1. Body text and anything a learner must read uses `ink` or `secondary` (≥ 4.5).
2. `muted` (2.4) is for labels, captions, placeholders and decoration only, as on the reference; never the only carrier of information.
3. White text on a mode colour only at 17 pt bold or larger (cards, titles). On cyan and green, which fall below 3, keep text short and bold, or use ink.
4. Lime always takes ink, never white.
5. A new colour pair is checked here before use.

## Components

Use these instead of building a new one.

| Need | Use | File |
| --- | --- | --- |
| Navigate | `go(context, page)`; cover pages mix in `CoverPage` | `widgets/navigation.dart` |
| Page with title and back | `AppPage` / `Header`, or `HeaderScrollPage` for a pinned blurred header | `widgets/page.dart`, `widgets/blur_header.dart` |
| Round glass back / more button, 44 pt | `HeaderRoundButton` | `widgets/blur_header.dart` |
| Game page buttons | `GameGlassButton` | `features/game/game_glass_button.dart` |
| Primary or outlined button | `ActionButton` (`trailing:` for an arrow after the label; 56 pt tall in onboarding) | `widgets/buttons.dart` |
| Press feedback | `PressFade` (fades to 20% in 350 ms, back in 150 ms) | `widgets/press.dart` |
| Popup or overflow menu | `showGlassMenu` with `GlassMenuItem` (icons, ticks, swatches, red danger rows, submenus via `title` and `behind`) | `widgets/glass_menu.dart` |
| Confirmation | `confirm()`: the iOS 26 alert, `destructive: true` for red actions | `widgets/sheets.dart` |
| Bottom sheet | `sheet()`; floating sheets inset 9 pt with a 38 pt corner when the reference floats them | `widgets/sheets.dart` |
| Section label in spaced capitals | `CapsLabel` | `widgets/labels.dart` |
| Loading, error, empty | `AsyncView`, `LoadingView`, `ErrorView` ("Thử lại"), `EmptyView` | `widgets/async_view.dart` |
| Toast | `toast()` | `widgets/navigation.dart` |
| Completion medal and confetti | `MedalPainter`, `StillConfettiPainter`, `ConfettiPainter` | `widgets/medal.dart`, `widgets/confetti_painter.dart` |
| Size that holds text | `context.grow(value)` | `widgets/text_grow.dart` |

Icons: Cupertino icons first (`CupertinoIcons`), Material rounded icons where none fits. The reference's two-tone illustrations are approximated; say so in a comment.

### Icons

Sizes in use, by role: 14–16 inline with captions and in chips, 18–22 in buttons, rows and the navigation bar (21 for search glyphs), 24–25 standalone, 33–52 for hero glyphs on empty and completion states. Icon color follows the text next to it (`ink`, or `muted` when inactive); an icon never carries the only signal of state.

### Touch targets

Every tappable control is at least 44 × 44 pt, even when it draws smaller (a 20 pt glyph sits inside a 44 pt hit box). Round header and glass buttons are exactly 44 pt. Keep 8 pt or more between neighbouring targets. This is a rule for new controls; existing screens have not been audited against it.

### Text fields

Borderless by default: `isCollapsed`, no fill, `InputBorder.none`, placed inside the capsule or card that frames it (history search sits in a 48 pt glass capsule with a 21 pt search glyph, 18 pt in and 10 pt to the text). Text uses the same size as its hint; the hint is `muted` (or the screen's measured `Palette` hint). Text that the reference sets as sentences uses `TextCapitalization.sentences`. Search fields show a clear button only while they hold text. Forms on store-style screens (redeem code) are the one filled style, using `Palette.storeField`.

### States

| State | Rule |
| --- | --- |
| Pressed | `PressFade` to 20%; never a Material ripple |
| Selected | Category color on a 1.7 pt border, or a tick in menus; not color alone when the reference adds a tick |
| Disabled | Grey fill (`Palette.ctaDisabled`) and no press feedback; not reduced opacity |
| Loading / error / empty | `AsyncView` |
| Correct / almost / wrong | Status colors above, always with a word or icon |

## Motion

| Motion | Value |
| --- | --- |
| Push | `CupertinoPageRoute` |
| Cover (Plus, review) | in 0.5 s, out 0.27 s (`CoverRoute`) |
| Glass menu | grows from its control, 240 ms, ease-out-back |
| Alert | fade and scale from 1.08, 220 ms |
| Press | `PressFade` |
| Card flip (flashcards) | 0.33 s |
| Rating fly-out | 0.62–0.97 s |
| Flow Letter solved word | holds 1.1 s, next color fades in 0.3 s |
| Sign-in demos | each scene plays a 4 s timeline (`phase()` slices it), holds, and the next fades and scales in from 0.96 after 4.8 s; background tint 600 ms; title 220 ms; dots 200 ms |
| Onboarding steps | step change 350 ms `easeOutCubic`; the title writes itself at 45 ms a character with a `feedback.tap()` each, pauses 160 ms, then the line under it at 12 ms a character (a tick every third); the step's content then fades and lifts 8% in 300 ms (`Reveal`); progress bars 300 ms; demos "think" 900 ms |
| Onboarding card stacks | the welcome stack deals its front card up and left every 2.8 s or on a tap, 600 ms `easeInOutCubic`, as the cards behind (20 pt lower, 6% smaller each) move up; a rated word card flies out sideways in 450 ms `easeInCubic` after a 0.33 s flip |
| Preparing wait | dots on three tilted rings in the mode colours, one turn per 6 s; they gather into the logo over the 2.8 s wait |
| Auth gate (welcome to Home and back) | on sign-in a frosted white veil (blur σ 22) with an arched top rises over sign-in in 900 ms `easeInOutCubic` with ten light knocks closing in and a heavy one as it covers, the logo fades in and breathes for 300 ms; then pages fade through white and scale from 0.98, 350 ms `easeOutCubic` in, `easeIn` out |

Ambient motion (Home orb, banner stars) runs even under Reduce Motion, as on the reference. New motion (sign-in demos, onboarding, auth gate) stops under Reduce Motion and shows each demo's finished frame (`welcomeAutoplay()`); tests turn it off with `animateAmbient: false`.

Durations and curves for new motion, taken from what the code already uses:

| Kind | Duration | Curve |
| --- | --- | --- |
| Small state change (tick, color, fade of a label) | 180–220 ms | `Curves.easeOut` |
| Element entering (menu, popover, tip) | 240–300 ms | `easeOutBack` for things that grow from a control, `easeOutCubic` otherwise |
| Panel or sheet | 350–500 ms | `easeOutCubic` in, `easeIn` out |
| Celebration (fly-out, confetti) | 600–1000 ms | `easeOut` / `easeOutQuint` |

Prefer an existing value from the table; add a new one here with the reason for it.

## Haptics and sound

Through `FeedbackService` only, never `HapticFeedback` in a feature, so the Profile switches "Âm thanh" and "Rung" apply everywhere.

| Event | Call | Effect |
| --- | --- | --- |
| Choice or step (check an answer, flip, pick a letter) | `feedback.tap()` | selection click |
| Completed (lesson, chat, Flow Letter word) | `feedback.success()` | medium impact and the system click |
| Something physical moving or landing (sign-in veil) | `feedback.impact()`, `impact(heavy: true)` | light or heavy impact, no sound |
| Writing that appears (onboarding headings) | `feedback.tap()` per letter | selection click |
| Pronounce a word | `feedback.speak(text)` | text to speech |

These mappings are our own choice: the reference's haptics and sounds have not been recorded yet, so keep them labelled unverified.

## Text overflow

- Titles that may run long take `maxLines` (1 for navigation and rows, 2 for card titles, 3 for tiles) with `TextOverflow.ellipsis`.
- Tile titles use `NoOrphanText` so a last word never sits alone.
- Never clip text silently with a fixed height; use `context.grow`.

## Scrolling

Platform physics through `AppScrollBehavior` (`widgets/app_scroll.dart`): iOS bounce, with a velocity tracker that drops the fling when the finger rests before lifting, as the reference does. Screens with a measured feel get their own physics (`HomeScrollPhysics`, `CardPagePhysics`); do not tune physics elsewhere without a recording. Lists inside a page that already scrolls use `NeverScrollableScrollPhysics`. Pinned headers blur what scrolls under them (σ 12), and content under the status bar blurs at σ 6.

## Gradients

Used for fades and art, not for plain surfaces. Bottom controls that float over content sit on a vertical fade of their own page color, transparent at the top edge and opaque from 35% down (`result_screen.dart`). Game and insight backgrounds use their measured `Palette` gradients; do not build a new gradient from mode colors.

## Accessibility

- Text scales with the system size up to 23/17 (Principles 4); `test/app/text_scale_test.dart` guards it.
- Custom tappable widgets get `Semantics` (button, label), which `PressFade` and the header buttons already add.
- Contrast follows the section above.
- Reduce Motion does not stop ambient motion (matches the reference); transitions keep their normal timing.

## Known exceptions

Places that still differ from these rules, kept because they were measured that way: the generator and history headers set their own spaced capitals at 10 / w700–800 with 1.5–2 tracking, and Profile's section headers ("Đang học", "Cài đặt chung") are sentence case. Fold them into `CapsLabel` only after checking against the reference.

## Copy

- UI strings are Vietnamese and inline. Keep the reference's exact wording, including its English words ("Excellent!", "Time", "Correct", "Cancel") where it uses them.
- Buttons are short verbs: "Sửa", "Tiếp theo", "Bắt đầu", "Tạo tùy chỉnh".

## Checklist for a new screen

1. Page and header from `AppPage` or `HeaderScrollPage`; buttons from the table above.
2. Every text style from the type scale; section labels through `CapsLabel`.
3. Colors from `D` or `Palette` only; mode cards from `mode.cardLook`.
4. Fixed sizes that hold text through `context.grow`.
5. Loading, error and empty states through `AsyncView`.
6. Interactive targets get a `ValueKey` or tooltip and a hit box of at least 44 pt.
7. Haptics through `FeedbackService`; motion from the duration table.
8. Add the screen to `test/app/text_scale_test.dart`, which lays it out at the largest text size and at Android's 411 × 914.
9. Run it on the iPhone and check it against these rules.
