# Vocabulary core plan

Goal: one vocabulary core that every feature uses, so that each word a learner meets anywhere in hifive is tracked until they can use it. It is built on findings from memory research instead of intervals copied from a reference app. Each step lands as its own commits and is reviewed before the next one starts.

Status values: todo, in progress, done.

## Decisions

- **Two sources of words** (12 November 2026): hifive supplies a catalog of words by level, and learners also create, edit and delete their own decks and cards. Both feed the same core.
- The scheduler is FSRS, written in this repo.
- The review log stays the source of truth for schedules, so a new scheduler recomputes every card without a data migration.

## Where we are

- A card has a status (`new`, `learning`, `review`), a due date and an interval. `FlashWord.nextIntervals` (`lib/domain/models/deck.dart`) uses fixed steps (1 min, 6 min, 1 day, 4 days) and fixed multipliers (1.2, 2.5, 3) for every card.
- Each rating is an append-only `review` record, and a card's schedule is that log replayed in time order (`lib/domain/sync/reviews.dart`).
- The only exercise is flip-and-self-rate, and only Flashcard writes reviews. A session is one deck's due cards; there is no daily limit, no cross-deck queue and no reminder.
- Built-in decks are a few samples in `lib/data/content/en/decks.dart`; learner decks and cards are `deck` and `word` records.
- Known faults: no per-card difficulty, a lapse resets the interval to zero, late reviews earn nothing, and "Khó" on a new card marks it as known.

## What knowing a word means

After Nation's model of word knowledge. Each cell is a separate skill; today the app trains one (recognising the meaning).

| | Recognise | Produce |
|---|---|---|
| Form | hear it, read it | pronounce it, spell it |
| Meaning | see the word, know the meaning | have the idea, recall the word |
| Use | understand it in a sentence | use it with the right grammar and collocations |

A word moves through five stages: met, first learned, consolidated, deepened (recognition to production) and used.

## Principles

| Finding | What it means here |
|---|---|
| Spacing effect | Review each word just before it would be forgotten; the gap grows with each success. |
| Retrieval practice | Every review asks before it shows. |
| Desirable difficulty | Exercises move from recognising to producing as a word matures. |
| Successive relearning | A forgotten word returns in the same session until recalled. |
| Pretesting | A new word is guessed from its example before the meaning is shown. |
| Graded hints | First letter, then length, then the example; a hinted answer counts as "Khó". |
| Interleaving, no confusable sets | Mix decks in a session; do not introduce near-synonyms or one closed set (colours, weekdays) together. |
| Sound and context | Every word has audio and at least one example sentence. |
| Objective feedback | Typed answers are graded by the app, not self-rated. |
| Small daily load | A fixed number of new words per day and sessions in legs of about 20. |
| Self-reference | Words the learner saved themselves come first, with the sentence they were found in. |

## The core

Five parts in `lib/domain/vocab/`, with no UI. Features call them through `AppState`.

| Part | Job | Today |
|---|---|---|
| Word store | Each word's data: meaning, phonetic, part of speech, examples, collocations, word family, level | meaning, phonetic, one example |
| Memory profile | Per learner and word: stability, difficulty, lapses and which skills were practised; derived from the log | status and due date |
| Scheduler | When to review (FSRS) | fixed multipliers |
| Exercise picker | How to review, from the word's stage and weakest skill | flip only |
| Review log | Every graded meeting with a word, from any feature | Flashcard only |

### Two sources, one core

| | Catalog (hifive) | Personal (learner) |
|---|---|---|
| Content | Words by CEFR level and topic, written and reviewed by us | Decks and cards the learner makes, and words saved from the dictionary |
| Storage | Shipped as content with fixed ids (bundled first, from R2 after backend plan step 4); never stored as records | `deck` and `word` records, synced |
| Learner can | Start a deck, add single words to a personal deck, hide a word, add a personal note | Create, edit, delete |
| Schedule | `review` records by word id, the same for both | |

Rules:

1. A catalog word is not copied into the learner's data. Only its reviews, a hidden flag and the learner's note are records, so a content fix reaches every learner.
2. Editing a catalog word's own text is not offered. The learner adds a note, or copies the word into a personal deck and edits the copy.
3. The same spelling in the catalog and in a personal deck shares one memory profile, so a word is never studied twice. The personal card's text is what is shown.
4. A catalog deck becomes active when the learner starts it; only active decks feed new words into the daily queue.

### How features use it

| Feature | Role |
|---|---|
| Flashcard | The main review surface: the core supplies the words and the exercise for each. |
| FlowLetter | Spelling practice on due and hard words; a finished word writes a review. |
| Dictionary | Intake: saves a word with the sentence it was found in. |
| Writing, grammar (when unlocked) | The "used" stage: exercises include words being learned, and a correct use is logged. |
| Conversation (when unlocked) | The partner uses, and prompts for, words being learned. |
| Insight | Reads the memory profile. |
| Streak, reminders | Driven by today's due count. |

## Architecture

Decided direction, 13 November 2026: the core runs on the device; the server keeps the log, serves the catalog and does the heavy or shared work later. This follows the offline-first design in `docs/backend-plan.md`.

### Where each job runs

| Job | Runs on | Why |
|---|---|---|
| Track: record every meeting with a word | Device, written as `review` records | Works offline; one append-only log syncs with the existing merge rule (union) |
| Compute: FSRS stability, difficulty, recall now | Device, by replaying the log | Deterministic, instant after each answer, no cost; a few thousand reviews replay in milliseconds |
| Assess: level per word, retention, hard words, weak skills | Device, derived from the profile | Same data, no round trip |
| Remind: words about to be forgotten | Device, local notifications | The device knows the forecast; no push server needed |
| Suggest new words | Device, from the profile, settings and the catalog it has cached | Needs today's load, which only the device knows offline |
| Sync the log between devices | Worker + D1 (exists) | Already built; no change for new review fields |
| Catalog of words by level and topic | Worker static assets + a version manifest (R2 later) | Content changes without an app release; fixed word ids |
| Fit FSRS parameters to one learner | Device first (background isolate), Worker later | Needs about 1,000 reviews; the result is a synced setting |
| Content insight across learners (which words are hard) | Worker, anonymous aggregates, later | Only the server sees many learners |
| AI: examples, mnemonics, grading a learner's sentence | Worker + AI Gateway (backend plan step 5) | Needs a model and per-user quotas |

So steps 1 to 6 below need no backend change. The Worker only checks a record's kind and size, so new optional fields on `review` pass through.

### The review event

Every graded meeting with a word, from any feature, is one `review` record (append-only, id is a UUID v7):

| Field | Today | Added |
|---|---|---|
| `wordId`, `at`, `rating` (0 Học lại, 1 Khó, 2 Tốt, 3 Dễ; -1 reset; -2 snapshot) | yes | |
| `tree` (garden credit) | yes | |
| `word` | | normalized text with the course language, `en:resilient`, so one spelling shares one profile across decks and the catalog |
| `mode` | | `flip`, `choice`, `typing`, `listening`, `cloze`, `spelling`, `sentence` |
| `skill` | | `meaning` (see word, know meaning), `recall` (have meaning, produce word), `form` (spelling or sound), `use` |
| `source` | | `flashcard`, `today`, `focusBreak`, `flowLetter`, `dictionary`, `writing`, `conversation` |
| `ms` | | time to answer |
| `hint` | | hints used before answering |

Old clients ignore the new fields; old records lack them and replay as `flip` / `meaning` / `flashcard`. Ratings from app-graded exercises map as: wrong 0, right after a hint or slowly 1, right 2; the learner may raise a right answer to 3.

### The memory profile

Derived per word key, never stored or synced: stability, difficulty, last review, lapses, recall probability now, level, and per-skill counts. Levels: Mới (no review), Đang học (in learning steps), Đang nhớ (stability under 21 days), Thuộc (21 days or more), Thành thạo (Thuộc and a correct `recall` or `use` in the last 60 days). A local, unsynced cache of the profile may be added if replay ever shows up in startup time; it is rebuilt from the log whenever the log changes.

### Growth of the log

About 100 reviews a day is about 36,000 records a year per learner: small for D1 and SQLite. A new device pulls the log in pages of 500. If that grows slow, a device can write a `snapshot` event per word and the server can drop the older events of that word (a later compaction step, not needed now).

### Screens

| Screen | Purpose |
|---|---|
| Ôn hôm nay (main Home action) | One session: due words lowest recall first, then today's new words, exercises picked per word |
| Deck list | Due and new counts per deck; catalog decks beside the learner's own |
| Word page | Level, next review, recall now, history of meetings, the learner's note |
| Insight trí nhớ | Words per level over time, measured retention, hard words, weak skills, 7-day forecast |
| Lesson settings | New words per day, target retention, exercise types on or off, reminder time |

## Steps

### 1. FSRS scheduler and memory profile - done

13 November 2026. `lib/domain/vocab/`: `fsrs.dart` (FSRS-5 with its published defaults), `scheduler.dart` (`preview` gives the four outcomes and the button labels; learning steps 1 and 6 minutes; a lapse lowers stability instead of zeroing it; same-day reviews use the short-term formula), `memory.dart` (levels Mới, Đang học, Đang nhớ, Thuộc, Thành thạo; recall now; hard words). `FlashWord` carries the derived profile (stability, difficulty, lapses, reviews, first and last review, last recall). `review` events gained `word`, `mode`, `skill`, `source`, `ms` and `hints`; replay groups cards by `wordKey`, so one word in several decks is one memory, and `AppState.rate` updates every copy. Old records replay with the defaults; no record format break and no Worker change. Tests: `test/domain/vocab_test.dart`.

### 2. Daily queue and reminders - done

`today.dart`: due words lowest recall first, new words from saved words, then the learner's decks, then hifive's, up to `newPerDay` (default 10, a synced setting) less those met today, halved at three times that many due and stopped at six times; legs of 20 with one new word after every two reviews. Home shows "Ôn hôm nay" with the counts above the garden banner. The daily reminder (Profile, Thông báo) is a local notification at the chosen time, rescheduled by `ReminderSync` after every change and on leaving the app, sent only when words will be due, with the count and an estimate of minutes; the iOS delegate schedules it over the `hifive/screen` channel. Not done: confusable words are not yet kept apart (no data for them yet).

### 3. Exercise picker - done

`exercise.dart` and `TodayScreen` (`lib/features/flashcards/today_screen.dart`): new words are met (guess, reveal, self-rate with interval labels), learning words are a choice of four meanings, remembering words are typed from the meaning, known words alternate a cloze in their example and listening. Typed answers forgive case and punctuation, and one letter in words of four or more ("Gần đúng", rated Khó); hints show the first letter, then the length, and cap the rating at Khó; a wrong answer is Học lại and returns as a choice at the end of the leg; a right one can be raised to Dễ ("Quá dễ"). Lesson settings set new words a day and turn typing or listening off.

### 4. Memory insight and the word page - done

`insight.dart` and `MemoryScreen` (from Insight): words per level, retention (known cards answered from memory in 30 days, shown after 10 reviews), a seven-day forecast, accuracy per skill from graded exercises, and hard words. `WordScreen` (from a deck's word rows and the hard words): level, recall now, next review, how long the memory lasts, times forgotten, and every meeting with its skill and rating.

### 5. Catalog - done, deployed

Deployed on 13 November 2026 (Worker version `7343bf0e`). R2 is not enabled on the Cloudflare account, so the catalog ships with the Worker as static assets (`worker/catalog/`, binding `CATALOG`, `run_worker_first`, so only the Worker's routes serve it): `GET /v1/catalog/manifest` (cached an hour) and `GET /v1/catalog/<lang>/<version>.json` (immutable), without sign-in. The starter pack `en/1.json` has three A1 decks of twelve words (family, food, a day). To publish a new pack, add `catalog/en/<n>.json`, point `catalog/manifest.json` at it and `npm run deploy`; never edit a published version. Moving to R2 later needs only `serveCatalog` to read a bucket. The app checks the manifest about once a day once one exists (`AppState.refreshCatalog`), caches the pack in the store's meta and shows its decks as hifive's own, after the learner's in the new-word order. Catalog word ids are fixed, so reviews survive new versions.

Version 2 (`worker/catalog/en/2.json`) adds `listening`: YouTube playlists hifive recommends (id, title, channel, level, description, playlist id, cover video). `ListeningScreen` lists them from the cached pack; `ListenScreen` plays the playlist in YouTube's own embedded player (`youtube_player_iframe`, which adds a web view) and saves words heard into Saved words, so they come first among today's new words. Subtitles and shadowing need timed transcripts and come later.

### 6. Later - todo

- Starting and hiding catalog decks, notes on catalog words (new record kinds), browsing the catalog by level and topic.
- Keeping confusable words apart on the same day.
- FlowLetter and dictionary saves writing reviews through the core.
- Fitting FSRS parameters to a learner's log; target retention as a setting.
- AI: example sentences, mnemonics, grading a learner's own sentence (backend plan step 5).

## Open decisions

1. New words per day by default: 10 is proposed.
2. Whether typing exercises are on by default or opt-in.
3. Which level the first catalog covers and who writes it (hand-written, or AI-drafted and reviewed).
