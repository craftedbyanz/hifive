# Backend plan

Goal: accounts, sync between a learner's devices (for example an iPhone and an iPad) and server-side AI, built on free tiers, while the app stays offline-first. Each step lands as its own commits and is reviewed before the next one starts.

Status values: todo, in progress, done.

## Decisions

- **Offline-first.** The app reads and writes a local SQLite database only. The network is used to sync, to fetch course content and for AI. Without a connection everything except AI keeps working; answers are graded locally by `gradeLocally`.
- **Firebase (Spark plan)** for Authentication (Apple, Google, email), Crashlytics, Analytics, Cloud Messaging and App Check. No Firestore, Cloud Functions or Cloud Storage: Functions and Storage need the Blaze plan, and local SQLite makes Firestore's offline SDK redundant.
- **Cloudflare (Free plan)** for the API: one Worker verifies Firebase ID tokens and App Check tokens, serves `POST /sync` backed by D1, and calls the AI provider through AI Gateway. Course content is versioned JSON on R2. Per-user AI quotas live in a SQLite-backed Durable Object or D1.
- **Free tier failures are hard errors, not bills.** The app already shows "Thử lại" for failed requests; sync simply retries later.
- **Firestore-style per-write billing is avoided:** one sync request carries every changed row.

Free limits checked on 6 November 2026 (Cloudflare from its docs; Firebase from third-party summaries, to confirm on firebase.google.com/pricing): Workers 100,000 requests/day and 10 ms CPU per request; D1 5 million rows read and 100,000 rows written per day, 5 GB; R2 10 GB, free egress; Workers AI 10,000 neurons/day; Firebase Auth about 50,000 monthly active users.

## Local data model

Everything the learner creates is a **record**: `kind`, `id`, a JSON `data` map (null for a deletion), an `hlc` stamp and a `dirty` flag. The server stores the same rows, so sync never needs per-model schema changes.

- **Ids** are UUID v7 (`lib/domain/sync/ids.dart`). Built-in decks keep fixed ids so two devices share them. A saved dictionary word's id comes from its lower-case text, so saving the same word on two devices yields one card.
- **Clock:** a hybrid logical clock (`lib/domain/sync/hlc.dart`) orders writes even when device clocks disagree. Its string form sorts in time order.
- **Merge rule:** for each `(kind, id)` the record with the greater `hlc` wins. The server applies only this rule; everything else is derived on the device.

| Kind | Id | Synced | Merge behaviour |
|---|---|---|---|
| `setting` | setting name | yes | One row per setting, so changes to different settings on two devices both survive. Only settings the learner changed are written, so a new device's defaults never overwrite real values. |
| `session` | session id | yes | Append-only; union. |
| `historyCleared` | `history` | yes | "Xoá lịch sử" stores a time; sessions dated before it are hidden, so a lesson finished offline afterwards on another device stays. |
| `deck` | deck id | yes | Learner-made decks only; built-in decks come from content. Deleting a deck, when it exists, wins over edits. |
| `word` | word id | yes | Cards the learner added, with their deck id. |
| `review` | review id | yes | Append-only review log: a rating, a schedule reset or, for migrated data, a state snapshot. A card's schedule is the log replayed in time order, so reviews of one card on two devices both count. |
| `game` | game id | yes | One row per finished game; played count, XP and best score are derived (count, sum, max). |
| `legacyStats` | device id | yes | Counters from the old JSON blob, added to the derived totals. |
| `firstUse` | device id | yes | When each device was first used; the app shows the earliest. |
| `device` | name | no | Device-only state: sound, haptic and the unfinished game. |

`chatTipSeen` is only ever written as true. Reviews made at the same moment replay in the order of their record stamps.

**Signing out** deletes the account's local records; the next learner starts clean. **Signing in** on a device that has guest records merges them into the account with the rules above.

## Steps

### 1. Local SQLite store - done

1. Sync primitives in `lib/domain/sync/`: HLC, UUID v7, records, the merge rule and review replay, with tests.
2. `RecordStore` interface in `domain/repositories`, a SQLite implementation in `data/local` and a memory one for tests.
3. `AppState` loads from records and writes only the records a change touches; the first launch converts the `hifive.local.v1` blob and keeps it untouched.

Done with `sqlite3` (latest 3.x) and `path_provider`. Verified by tests for both stores, import, reload and two-device merges, and on the iOS Simulator by importing a seeded blob.

### 2. Firebase Authentication - in progress

Done: project `hifive-3371b` on the Spark plan with Email/Password, Google and Apple enabled; iOS and Android apps registered; the debug key's SHA-1 and SHA-256 added; `firebase_core` initialised in `main.dart`. Also done: `AuthService` with Firebase and memory versions; Profile shows the account and opens `SignInScreen` (Apple on iOS, Google, email with sign-up and password reset); signing in records `accountUid` in the store's meta; signing out asks first and keeps every local record until sync exists. Still to verify on a physical iPhone and an Android build: real Apple, Google and email sign-in. Still to build: account deletion (required by the App Store). Before the App Store: fill Apple's OAuth code flow settings (Team ID, Key ID, `.p8` key) so account deletion can revoke Apple tokens. Before Google Play: add the Play App Signing SHA fingerprints.


Apple, Google and email sign-in; guest use until sign-in; local records merge into the account on sign-in and are deleted on sign-out.

### 3. Sync Worker and D1 - todo

`POST /sync` pushes dirty records and pulls rows changed since the device's cursor (a server sequence number). Sync runs on launch, on returning to the foreground, after a lesson and at most every few minutes. Tests simulate two devices editing offline, deletes against edits, skewed clocks and interrupted syncs.

### 4. Course content on R2 - todo

A manifest lists a content version per language; the app checks it about once a day and caches new content in SQLite.

### 5. AI on the Worker - todo

Grading, conversation, deck generation and insights through AI Gateway, with per-user quotas. The AI provider is still to be chosen.
