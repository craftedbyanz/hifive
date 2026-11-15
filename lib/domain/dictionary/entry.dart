import '../models/models.dart';

/// One meaning of a [DictEntry]: Vietnamese text and its labels (`slang`,
/// `informal`, `figurative`, `us`, `uk`, `literary`, `humorous`, `formal`).
class DictSense {
  final String meaning;
  final List<String> labels;
  const DictSense(this.meaning, [this.labels = const []]);
}

/// A word in one part of speech and etymology, from the dictionary pack
/// (`tool/dictionary/build.py`) or from hifive's own decks.
class DictEntry {
  /// Unique within its source; `pack:<n>` or `deck:<word id>`.
  final String id;

  /// As written, case kept: *Polish* and *polish* are two entries.
  final String word;

  /// `NOUN`, `VERB`, `ADJECTIVE`… as cards store it.
  final String partOfSpeech;

  /// CEFR level (`A1`…`C2`) when a word list has one.
  final String? level;

  /// Frequency rank in spoken English, 1 = most common; null when unranked.
  final int? rank;

  /// IPA, British and American; either may be empty.
  final String uk, us;

  /// Up to four meanings, the most useful first. Empty when [needsMeaning].
  final List<DictSense> senses;

  /// An English definition, for entries no source translates.
  final String definition;

  /// An example sentence and, when Tatoeba has one, its translation.
  final String example, exampleMeaning;

  /// Where the example comes from: `tatoeba:enId:viId:enAuthor:viAuthor`,
  /// `wiktionary`, `hifive`, or empty.
  final String exampleSource;

  /// True when no source gives a Vietnamese meaning, so the learner types
  /// one before the card can be made.
  final bool needsMeaning;

  /// Hand-picked by hifive (catalog and bundled decks); these rank first.
  final bool curated;

  /// How CEFR-J orders this part of speech for the word; 0 is its main use.
  final int posRank;

  const DictEntry({
    required this.id,
    required this.word,
    required this.partOfSpeech,
    this.level,
    this.rank,
    this.uk = '',
    this.us = '',
    this.senses = const [],
    this.definition = '',
    this.example = '',
    this.exampleMeaning = '',
    this.exampleSource = '',
    this.needsMeaning = false,
    this.curated = false,
    this.posRank = 9,
  });

  /// A word learners meet often: on a CEFR list or among the 30,000 most
  /// frequent. Only these are offered as spelling corrections.
  bool get common => level != null || (rank != null && rank! <= 30000);

  /// The IPA for [accent] (`uk` or `us`), falling back to the other.
  String ipa({bool american = false}) =>
      american ? (us.isEmpty ? uk : us) : (uk.isEmpty ? us : uk);

  /// The meanings at [picked] joined for a card, in the order shown.
  String meaningOf(Iterable<int> picked) => [
    for (final i in picked)
      if (i >= 0 && i < senses.length) senses[i].meaning,
  ].join('; ');

  /// The card this entry makes, with the meanings at [picked] (or [meaning]
  /// when the learner typed their own) and [id] from `AppState.newId`.
  FlashWord toCard({
    required String id,
    List<int> picked = const [0],
    String? meaning,
    bool american = false,
  }) => FlashWord(
    id: id,
    word: word,
    meaning: meaning ?? meaningOf(picked),
    phonetic: ipa(american: american),
    example: example,
    partOfSpeech: partOfSpeech,
    definition: definition,
  );

  /// An entry for one of hifive's own cards.
  factory DictEntry.fromCard(FlashWord w, {String? level}) => DictEntry(
    id: 'deck:${w.id}',
    word: w.word,
    partOfSpeech: w.partOfSpeech,
    level: level,
    uk: w.phonetic,
    us: w.phonetic,
    senses: [DictSense(w.meaning)],
    definition: w.definition,
    example: w.example,
    exampleSource: w.example.isEmpty ? '' : 'hifive',
    curated: true,
    posRank: 0,
  );
}

/// What kind of match a [DictHit] is.
enum DictMatch {
  /// The typed word itself.
  exact,

  /// The typed word is an inflection of [DictHit.entry] ([DictHit.form]).
  form,

  /// Another spelling (*colour* for *color*).
  variant,

  /// A phrase found by un-inflecting or dropping an object (*turned it off*).
  phrase,

  /// One word of an expanded contraction (*I'm* = I am).
  contraction,

  /// Starts with what was typed.
  prefix,

  /// A spelling correction ("Có phải…?").
  suggestion,

  /// Found from its Vietnamese meaning.
  meaning,
}

/// One result row.
class DictHit {
  final DictEntry entry;
  final DictMatch match;

  /// For [DictMatch.form]: the typed form and its label (`past`,
  /// `pastParticiple`, `ing`, `plural`, `comparative`, `superlative`,
  /// `thirdPerson`, `form`).
  final String form, formLabel;

  /// For [DictMatch.contraction]: the expansion, as "i am".
  final String expansion;
  const DictHit(
    this.entry,
    this.match, {
    this.form = '',
    this.formLabel = '',
    this.expansion = '',
  });
}

/// Why a lookup gave what it gave.
enum DictOutcome {
  /// Nothing typed, or no letters in it.
  empty,

  /// Longer than a phrase; the learner is asked for a word.
  tooLong,

  /// At least one entry for what was typed (or its lemma, variant, phrase).
  found,

  /// No match; [DictResult.hits] holds prefix matches and corrections.
  suggestions,

  /// Vietnamese typed; [DictResult.hits] are English words with that meaning.
  meaning,

  /// Nothing anywhere: only manual entry is left.
  none,
}

/// A lookup's rows, best first.
class DictResult {
  final String query;
  final DictOutcome outcome;
  final List<DictHit> hits;
  const DictResult(this.query, this.outcome, [this.hits = const []]);
}
