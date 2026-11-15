# Dictionary plan

Goal: a learner types a word, sees its meaning, pronunciation and an example, and adds it to a deck in one tap, instead of typing the word and its meaning by hand (`AddWordSheet` today). The same dictionary later replaces the hard-coded glosses that lessons and listening use (`dictionaryMeaning` in `lib/features/learning/dictionary.dart`).

Status: **P0 and P1 built on 15 November 2026** with the proposed answers to the decisions below: both Wiktionary editions, ipa-dict, CEFR-J, FrequencyWords and Tatoeba, the pack under CC BY-SA; one card per word with up to three meanings; Vietnamese explanations for every interface for now; no machine translation; offensive senses removed; the core pack downloaded after launch. Not built yet: the Worker full-pack lookup (step 9), lessons and listening using the dictionary (P2), the reviewed core list and "Báo nghĩa sai" (P3), and "Bộ mới…" in the deck picker.

What exists:

- `tool/dictionary/build.py`: `fetch` downloads the sources to `build/dictionary/sources`; `build <version>` writes `worker/catalog/dictionary/en-vi/<version>.sqlite.gz`, adds it to `worker/catalog/manifest.json` under `dictionaries` with its size and SHA-256, and writes `build/dictionary/report.md`. Pack 2 (pack 1 was withdrawn before release): 50,219 entries, 5.6 MB gzip.
- The Worker serves it from its static assets at `/v1/catalog/dictionary/en-vi/<version>.sqlite.gz`, cached for good.
- The app checks the manifest about once a day (`AppState.refreshDictionary`), verifies size and SHA-256, inflates it to `dictionary-en-vi.db` and opens it read-only. A failed download or check keeps the installed pack.
- `DictionaryScreen` (from "Thêm từ" in a deck and from the deck list's search button) and `DictionaryEntryScreen`; credits under Profile → "Nguồn dữ liệu từ điển".

To publish a new pack: `python3 -I tool/dictionary/build.py build <next version>`, run `scripts/check.sh`, commit, then deploy the Worker. Earlier versions stay in `worker/catalog` until no installed app needs them; apps only fetch the newest.

## How other apps do it

Research from 15 November 2026. Most app details come from store pages, help centres and third-party write-ups, not from using the apps.

| Pattern | Apps | Lesson for hifive |
|---|---|---|
| Look up in a dictionary, then "add to list" | Vocabulary.com, Cambridge +Plus (personal lists retired 30 Sep 2026), TFlat, MochiVocab, Memrise word lists | One tap from result to deck. Memrise learners complain they cannot add words its dictionary lacks, so manual entry must stay |
| Suggestions while creating a card | Quizlet (term and definition suggestions, Auto-define, editable) | Let the learner pick a sense and edit it before saving |
| Capture in context | LingQ, Readlang, eJOY, Kindle Vocabulary Builder | Keep the sentence the word came from. Kindle saves every lookup and lists bloat, so save only on an explicit tap |
| Generate from a list or topic | Lingvist Custom Decks | Already covered by `DeckGenerator` ("Thêm thẻ") |
| Triage known / to learn | WordUp | A later step; learners dislike losing the choice |

## Sources

Every row was downloaded and measured on 15 November 2026, unless the row says otherwise. Coverage is measured against the CEFR-J Wordlist (A1–B2, 7,799 headwords).

| Source | Role | What it adds | Measured | Licence |
|---|---|---|---|---|
| **Vietnamese Wiktionary** via kaikki.org (`vi-extract.jsonl.gz`, 33 MB) | Main Vietnamese meanings | Hồ Ngọc Đức's FVDP English–Vietnamese dictionary (109,000 entries), imported with the author's permission | 119,098 English words; Vietnamese meaning for 96–97% of A1–B2; IPA on 11% of entries; examples on 9% | CC BY-SA 4.0 / GFDL |
| **English Wiktionary** via kaikki.org (English words, 534 MB gz) | Sense order, IPA, examples, phrasal verbs, inflections, Vietnamese translations of common senses | Senses ordered by commonness; one entry per etymology (*lead* "chì" /led/ vs "dẫn" /liːd/); `form_of` (*went* → *go*); `alt_of` (*colour* → *color*); phrasal verbs | 1.36 M words; Vietnamese translations for 16,755 words, concentrated where they matter (A1 90%, A2 76%, B1 60%, B2 45%); IPA ~95% of A1–B2 | CC BY-SA 4.0 / GFDL |
| **ipa-dict** (`en_US`, `en_UK`) | IPA fallback | 126 k US and 65 k UK pronunciations | ~98% of A1–B2 | MIT |
| **CEFR-J Wordlist 1.5** + **Octanove C1/C2** | Level tags, ranking, part of speech per level | 7,799 A1–B2 and 2,137 C1–C2 headwords | — | CEFR-J: free for commercial use with citation (Tono Laboratory, TUFS). Octanove: CC BY-SA 4.0 |
| **FrequencyWords** (OpenSubtitles 2018, `en_50k`) | Ranking suggestions and reverse search | Spoken-language frequency | — | CC BY-SA 4.0 |
| **Tatoeba** EN–VI pairs | Example sentences with a Vietnamese translation | 23,277 pairs, 149 Vietnamese contributors | Short pair containing the exact word: A1 93%, A2 76%, B1 53%, B2 31% | CC BY 2.0 FR (credit each sentence's author) |
| **hifive curated** (catalog + bundled decks + a reviewed core list) | Highest priority for the words it covers | Hand-picked meaning, example and level | 36 catalog words today | Ours |

Checked and not used:

- **dictionaryapi.dev**: no stated licence, unclear rate limits, listed as dead in places.
- **Open Multilingual Wordnet**: has no Vietnamese wordnet.
- **Wikidata lexemes**: CC0, but few English senses carry Vietnamese glosses.
- **Oxford 3000 and English Vocabulary Profile**: proprietary.
- **FVDP raw files** (GPL): the same data is already in Vietnamese Wiktionary under CC BY-SA.
- **On-device machine translation** (ML Kit: Vietnamese supported, ~30 MB model; Apple Translation: iOS 18+, while the app targets iOS 15.0): kept as an optional last fallback, pending a decision. It is ML, and single-word output is weak.

## Build pipeline

A build tool run by a developer (not in the app) turns the sources into a versioned pack, `dictionary/en-vi/<version>`, plus a quality report. A prototype written for this research (Python, 15 November 2026) runs the whole merge in about 1 minute.

### Entries

- One entry per (word as written, part of speech, etymology), with an id built from those three, so ids survive a new pack version. Case is kept: *Polish* and *polish*, *May* and *may*, *US* and *us* are different entries.
- Inflections and variants are links, not entries:
  - `form`: form → lemma, form label, part of speech.
  - `alt`: variant → canonical.

  FVDP glosses such as "quá khứ của go" become links and are dropped as meanings.
- Words with no Vietnamese meaning in any source are kept with up to 2 English definitions and `needsMeaning: true`, but only when common (CEFR-J, frequency rank ≤ 50,000, or a ≤ 4-word phrase whose head word is common). They are dropped when the same word already has a Vietnamese entry.

### Field priority (first source that has the field wins)

| Field | Order |
|---|---|
| Vietnamese meanings (≤ 4) | hifive curated → en.wikt senses whose Vietnamese agrees with one of FVDP's first glosses → other en.wikt senses with Vietnamese → remaining FVDP glosses. Each FVDP gloss is placed under the etymology whose Vietnamese it matches, else the first |
| IPA (UK and US, per entry) | curated → en.wikt sounds tagged RP/UK or GA/US (untagged only if neither) → ipa-dict → FVDP → none (TTS still speaks) |
| Part of speech | en.wikt → FVDP |
| Example | curated → Tatoeba (EN + VI, with author credit) → en.wikt (EN, must contain the word) → FVDP → none |
| Level | CEFR-J → Octanove → none |
| English definition | en.wikt (shown for `needsMeaning` entries and, later, for B2+ learners) |

### Filters

- Drop senses tagged obsolete, archaic, rare, dated, historical, nonstandard or misspelling, and FVDP glosses marked "(từ cổ)" / "(nghĩa cổ)".
- Offensive content is filtered **per sense and per translation**, never per word:
  - Drop en.wikt senses tagged vulgar, offensive, derogatory or slur (14,273 such senses), FVDP glosses marked "(thô tục)", and any Vietnamese translation on a profanity blocklist. Some en.wikt translations of neutral senses are vulgar, which is why translations are checked too.
  - *cock* keeps "con gà trống"; *damn* keeps "nguyền rủa".
- FVDP labels in parentheses ("(từ lóng)", "(thông tục)", "(nghĩa bóng)", "(từ Mỹ, nghĩa Mỹ)") become sense labels and leave the gloss text.
- Drop repeated meanings, glosses that are only an English cross-reference ("Sealskin", "Blond"), and single-letter capitalised FVDP entries.
- Proper names are kept only when en.wikt gives a Vietnamese name (*London* → Luân Đôn, *Hanoi* → Hà Nội) or CEFR-J lists them.
- Apostrophes and dashes are normalised at build time (*o’clock* → *o'clock*).

### Pack

- SQLite tables:
  - `entry(id, word, norm, pos, etym, uk, us, level, rank, data json)`.
  - `form`, `alt`.
  - A contentless FTS5 table over Vietnamese meanings, with `remove_diacritics 2`, for reverse search.
- The app's `package:sqlite3` 3.9 bundles SQLite with FTS5 on iOS and Android, so FTS5 does not depend on the OS build.
- Two tiers, measured on the prototype:
  - **Core:** CEFR-J, rank ≤ 30,000, or a Vietnamese translation from en.wikt. 44 k entries, 6.9 MB gzip before compaction; target ≤ 5 MB once JSON keys are shortened and English definitions are kept only where needed.
  - **Full:** 144 k entries, 17.4 MB gzip.
- Delivery works like the catalog: R2 holds the pack; the Worker serves `/v1/dictionary/en-vi/latest` and the pack. The app downloads core into its own file (`dictionary-en-vi.db`) and checks for a new version about daily.
  - The pack is reference data: not records, not synced, and an unreadable pack never sets `storageError`.
  - Swap in a new version only after its checksum matches.
- The quality report lists:
  - Coverage per level.
  - Source of each first meaning.
  - Every `needsMeaning` entry in CEFR-J.
  - A fixed 300-word sample for human review.

## Lookup flow

All candidates are gathered, then shown as **one grouped list**. The learner never sees numbered steps.

1. **Normalise:**
   - Trim; collapse spaces, hyphens and underscores; ’ → '.
   - Drop a leading "to " and a single trailing full stop (*a.m.* keeps its dots).
   - Keep the typed case for ranking.
   - Ignore input while the IME is still composing (Telex/VNI).
   - Search fields have autocorrect and auto-capitalisation off.
2. **Reject:**
   - Empty input, or no letters (*123*, *!!!*): show nothing.
   - More than 6 words or 60 characters: "Hãy nhập một từ hoặc cụm từ", and later offer to split a pasted sentence.
3. **Vietnamese input:** if the text has Vietnamese diacritics, search meanings only. Without diacritics (*con meo*), Vietnamese is tried only after English finds nothing, because *ban* is English too.
4. **English candidates, all collected:**
   - Exact entries for the normalised text.
   - Lemma of an inflection, restricted to the same part of speech. *saw* shows "cái cưa" and "quá khứ của see (verb)", not the noun *see* "toà giám mục".
   - Spelling variant (*colour* → *color*); spaced or joined forms (*e-mail*, *email*, *ice cream*).
   - Contractions from a fixed table (*I'm* = I am, *don't* = do not) show the expansion and the parts.
   - Phrases, in this order:
     - Inflected head (*looked after* → *look after*).
     - Object pronoun removed (*turn it off* → *turn off*).
     - Possessive → *one's* (*make up my mind* → *make up one's mind*).
     - Trailing particle dropped (*run out of* → *run out*).
5. **Rank:**
   - Entries with a Vietnamese meaning before `needsMeaning` entries.
   - Then exact case.
   - Then CEFR-J's part of speech for that word.
   - Then direct matches before links.
   - Then common before rare.
   - Abbreviations and names come last unless the input is capitalised.
   - A word that is also an inflection shows both: *left* "trái" and "quá khứ của leave".
6. **Prefix suggestions** (3+ letters), ranked by frequency, then level.
7. **"Có phải…?"** when there is no exact match:
   - Damerau–Levenshtein distance ≤ 1 for words of up to 5 letters, ≤ 2 for longer ones.
   - Only against common words (level or rank ≤ 30,000), one suggestion per word.
   - *recieve* → receive, *acommodate* → accommodate. Rare words are excluded so they don't win, as *covin* did for *COVID* in the first prototype.
8. **Vietnamese reverse search:**
   - Match meanings with diacritics folded.
   - Rank common words first, then words whose first meaning matches, then exact meaning matches.
   - *xin lỗi* → sorry, apologize; *đẹp* → beautiful.
9. **Not in core:** with network, ask the Worker's full pack; cache what comes back. Without network: "Chưa có trong từ điển ngoại tuyến".
10. **Machine translation** (only if approved): labelled "Dịch máy — nên kiểm tra lại".
11. **Manual entry:** always offered at the bottom ("Tự nhập '<từ>'"), with the word prefilled and IPA and example attached when any source had them.

Typing quickly must not show stale results: each query cancels the previous one, with a ~200 ms debounce. Performance must be measured on the iPhone and the Android emulator with the full core pack. If fuzzy matching is slow, the build precomputes a SymSpell-style delete index.

## Adding a word

- **Result row:**
  - Word, IPA (accent follows the TTS voice), part of speech, up to 3 short meanings.
  - 🔊, level chip, [+].
  - Tap the row for all senses, the example and its translation, and the source.
- **[+]:**
  - Adds a `FlashWord` with the chosen meaning (default: the first; tap senses to choose), that entry's IPA, the example, part of speech, and the English definition.
  - The card is a snapshot: a new pack never rewrites it.
  - The sheet stays open, counts what was added, and allows undo.
- **`needsMeaning` entries:** [+] opens the manual form with the word, IPA, English definition and example filled, and the meaning still to type. `FlashWord.meaning` is required, and exercises grade it.
- **States:** "Đã có trong bộ này" when the deck already has the word; "Đang học ở <bộ>" when another deck has it. One word in several decks is one memory (`wordKey`), so adding it doesn't restart learning.
- **Where it goes:** opened from a deck, it adds to that deck. Opened from the global search, it adds to a deck picker that defaults to "Từ đã lưu". Check whether catalog and built-in decks may take learner words before building.
- **Lessons and listening** later open the same entry card, and saving keeps the source sentence as the example.

## Edge cases

Checked against the prototype on 15 November 2026. "✓" means the prototype handled it after the fixes listed. "Rule" means it is specified above but not yet tested.

| Case | Example | Behaviour | Status |
|---|---|---|---|
| Sense order | *bank* | "ngân hàng" first, "bờ" as its own etymology | ✓ |
| Heteronyms | *lead*, *record* | Separate entries with their own IPA; the card takes the chosen entry's IPA | ✓ |
| Inflection that is also a word | *left*, *saw*, *found* | Both shown; the lemma's part of speech must match | ✓ (*found* "thành lập" has no Vietnamese anywhere → `needsMeaning`) |
| Irregular forms | *went*, *children*, *better* | Link to *go*, *child*, *good/well* | ✓ |
| Case changes meaning | *Polish*, *May*, *US* | Exact case ranks first; both cases shown | Partly (*US* → United States was still missing) |
| Spelling variants | *colour*, *e-mail*, *face-to-face*, *ice-cream* | One entry, variant noted | ✓ |
| Contractions | *I'm*, *don't*, *'re* | Expansion plus the parts | Rule (prototype picked the wrong part of speech) |
| Abbreviations | *a.m.*, *DVD*, *WHO* vs *who* | Dots kept; capitalised abbreviations rank last for lowercase input | Partly |
| Phrasal verbs | *take off*, *give up*, *looked after*, *turn it off* | Found, inflected and with an object | ✓ |
| Phrases without Vietnamese | *find out*, *look forward to* | `needsMeaning` (English definition, type the meaning) | ✓ |
| Idioms with *one's* | *make up my mind* | → *make up one's mind* | ✓ |
| Typos | *recieve*, *beautifull*, *acommodate* | "Có phải…?" with common words only | ✓ |
| Vietnamese input | *con mèo*, *xin lỗi*, *đẹp*, *con meo* | Reverse search; without diacritics only after English fails | ✓ |
| Proper names and brands | *London*, *Hà Nội*, *iPhone*, *COVID* | Kept when en.wikt names them in Vietnamese; else manual | ✓ |
| Offensive senses | *cock*, *bitch*, *damn* | Neutral senses stay; vulgar senses and translations removed | ✓ |
| Invalid input | empty, *123*, *!!!*, a pasted sentence | Nothing / "nhập một từ hoặc cụm từ" | ✓ |
| Words missing everywhere | *cybercafe*, *wornout*, *check-in desk* | Manual entry (12 of 7,799 CEFR-J words) | ✓ |
| IME composing, stale results, autocorrect | Telex "dd" → "đ" | Ignore composing text; cancel old queries; autocorrect off | Rule |
| Pack missing, corrupt or partly downloaded | first launch offline | Curated words + Worker; checksum before swap; never `storageError` | Rule |
| Pack updated | new version | Cards keep their snapshot; ids stable by (word, pos, etym) | Rule |
| Shared and public decks | a deck with dictionary meanings | Carry the attribution line (CC BY-SA) | Rule |
| Same word, different meanings | *bank* (money) and *bank* (river) | One memory today (`wordKey` = lowercase text) | **Decision needed** |
| Interface not in Vietnamese | English, Chinese or Korean UI | No Vietnamese meaning should be shown | **Decision needed** |

## Quality

- **Coverage is solved.** Vietnamese meaning for A1 97%, A2 96%, B1 96%, B2 95%. With `needsMeaning` entries, every A1–B2 word but 12 is found. Of 1,044 English words taken from hifive's own lessons, catalog and listening titles, 1,004 were found. The misses were Vietnamese fragments, brand names and contractions.
- **First-meaning quality is not solved.** In a 60-word A1–B2 sample, judged by the developer's assistant (not a native reviewer), the first meaning was right for about 45 (~75%). The 3 shown meanings were usable for about 54 (~90%). Typical faults:
  - A rare sense first: *note* "âm phù", *company* "đại đội", *evening* "lúc xế bóng".
  - FVDP's dated wording.
  - Row order across parts of speech.

  Automatic sense ordering will not reach "chuẩn" for the words learners meet most.
- **Therefore:**
  - A **reviewed core list**: the A1–B1 words (~5,000), reviewed in a small internal tool that shows the candidate meanings and examples. The reviewer picks or edits 1–3 meanings and confirms the IPA and example.
  - The result goes into the curated layer, which wins over every other source.
  - Start with A1–A2 (~2,600) before release.
- A **"Báo nghĩa sai"** action on the entry card feeds that review queue.
- The 300-word sample is re-scored on every pack version, so changes to the merge rules are measured.

## Licensing and attribution

- **Wiktionary (both editions), Octanove and FrequencyWords** are CC BY-SA 4.0.
  - The pack is adapted material, so the pack itself is published under CC BY-SA 4.0, with credit, a link to the licence and a note that it was changed.
  - The app's code stays separate: it only reads the data file.
  - Not legal advice; check before release.
- **CEFR-J:** cite "The CEFR-J Wordlist Version 1.5, compiled by Yukio Tono, Tokyo University of Foreign Studies".
- **Tatoeba:** CC BY 2.0 FR. Store each sentence's id and author and show them in the entry details.
- **ipa-dict:** MIT; keep its notice.
- **Where credit shows:**
  - A "Nguồn dữ liệu từ điển" page under Information.
  - A source line on each entry.
  - The attribution travels with shared and public decks that contain dictionary text.

## Decisions needed

1. **Sources:** the two Wiktionary editions, ipa-dict, CEFR-J, FrequencyWords and Tatoeba, with the pack under CC BY-SA. Proposed: yes.
2. **One card per word or per sense.** Spaced-repetition advice (minimum information principle) favours one card per sense. hifive's memory is keyed by lowercase text, and changing that touches sync and `docs/memory-plan.md`. Proposed: one card per word with up to 3 meanings now; revisit sense-level memory later.
3. **Explanation language** for English, Chinese and Korean interfaces. Proposed: Vietnamese pack first; other interfaces see the English definition and type their own meaning until an en→zh/ko pack exists (en.wikt has those translations).
4. **Machine translation** as the last fallback (ML Kit). Proposed: not in the first version; decide after looking at how often learners reach manual entry.
5. **Pack delivery:**
   - (a) Download core (~5 MB) on first use of search.
   - (b) Download over Wi-Fi after sign-in.
   - (c) Bundle in the app.

   Proposed: (b), with (a) as the fallback.
6. **Offensive words:** remove offensive senses and translations entirely (proposed), or show them with a label.

## Phases

1. **P0 – pack and report:**
   - The build tool in the repo, the core and full packs, and the quality report.
   - A review of the 300-word sample.
   - The reviewed A1–A2 list started.
2. **P1 – search and add:**
   - Pack download and storage.
   - Lookup flow steps 1–8 and 11.
   - The new add-word sheet, from a deck and from a global search.
   - Tests for every edge case above.
3. **P2 – everywhere:**
   - Worker full-pack lookup (step 9).
   - Lessons and listening open the same entry card and keep the source sentence.
   - `dictionaryMeaning` removed.
4. **P3 – more:**
   - Machine translation if approved.
   - The reviewed list completed to B1.
   - "Báo nghĩa sai".
   - Suggestions of related words.
