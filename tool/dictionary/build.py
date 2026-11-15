"""Builds hifive's English-Vietnamese dictionary pack (docs/dictionary-plan.md).

    python3 -I tool/dictionary/build.py fetch            # download the sources once (~600 MB)
    python3 -I tool/dictionary/build.py build <version>  # write the pack and update the manifest

Sources go to build/dictionary/sources (not committed). The pack goes to
worker/catalog/dictionary/en-vi/<version>.sqlite.gz, which the Worker serves;
`worker/catalog/manifest.json` gets its version, size and SHA-256, and
build/dictionary/report.md gets coverage numbers and a sample to review.
Standard library only; needs a Python whose sqlite3 has FTS5 (macOS has it).
"""
import bz2
import collections
import csv
import datetime
import gzip
import hashlib
import json
import os
import re
import sqlite3
import sys
import unicodedata
import urllib.request

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
SOURCES = os.path.join(ROOT, 'build', 'dictionary', 'sources')
OUT_DIR = os.path.join(ROOT, 'worker', 'catalog', 'dictionary', 'en-vi')
MANIFEST = os.path.join(ROOT, 'worker', 'catalog', 'manifest.json')
REPORT = os.path.join(ROOT, 'build', 'dictionary', 'report.md')

DOWNLOADS = {
    'vi-extract.jsonl.gz': 'https://kaikki.org/dictionary/downloads/vi/vi-extract.jsonl.gz',
    'en.jsonl.gz': 'https://kaikki.org/dictionary/English/kaikki.org-dictionary-English.jsonl.gz',
    'cefrj.csv': 'https://raw.githubusercontent.com/openlanguageprofiles/olp-en-cefrj/master/cefrj-vocabulary-profile-1.5.csv',
    'octanove_c1c2.csv': 'https://raw.githubusercontent.com/openlanguageprofiles/olp-en-cefrj/master/octanove-vocabulary-profile-c1c2-1.0.csv',
    'en_US.txt': 'https://raw.githubusercontent.com/open-dict-data/ipa-dict/master/data/en_US.txt',
    'en_UK.txt': 'https://raw.githubusercontent.com/open-dict-data/ipa-dict/master/data/en_UK.txt',
    'en_50k.txt': 'https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/en/en_50k.txt',
    'vie_sentences_detailed.tsv.bz2': 'https://downloads.tatoeba.org/exports/per_language/vie/vie_sentences_detailed.tsv.bz2',
    'vie-eng_links.tsv.bz2': 'https://downloads.tatoeba.org/exports/per_language/vie/vie-eng_links.tsv.bz2',
    'eng_sentences_detailed.tsv.bz2': 'https://downloads.tatoeba.org/exports/per_language/eng/eng_sentences_detailed.tsv.bz2',
}

# Senses learners should not meet.
DROP_TAGS = {'obsolete', 'archaic', 'rare', 'dated', 'historical', 'nonstandard', 'misspelling',
             'pronunciation-spelling', 'eye-dialect', 'proscribed'}
OFFENSIVE = {'vulgar', 'offensive', 'derogatory', 'slur', 'ethnic', 'sexual'}
# Vietnamese words that never appear in a meaning (some en.wikt translations of neutral senses use them).
PROFANITY = {'đĩ', 'địt', 'đụ', 'lồn', 'cặc', 'buồi', 'đéo', 'vãi', 'đm', 'đít'}
# Sense labels, stored as codes the app names in each language.
LABEL_TAGS = {'informal': 'informal', 'colloquial': 'informal', 'slang': 'slang', 'formal': 'formal',
              'figuratively': 'figurative', 'US': 'us', 'American': 'us', 'UK': 'uk', 'British': 'uk',
              'literary': 'literary', 'humorous': 'humorous'}
VI_LABELS = {'từ lóng': 'slang', 'thông tục': 'informal', 'nghĩa bóng': 'figurative', 'từ Mỹ, nghĩa Mỹ': 'us',
             'thơ ca': 'literary', 'văn học': 'literary',
             'từ cổ, nghĩa cổ': 'DROP', 'từ cổ': 'DROP', 'nghĩa cổ': 'DROP', 'thô tục': 'DROP', 'tục': 'DROP'}
POS = {'noun': 'NOUN', 'verb': 'VERB', 'adj': 'ADJECTIVE', 'adv': 'ADVERB', 'pron': 'PRONOUN',
       'prep': 'PREPOSITION', 'conj': 'CONJUNCTION', 'intj': 'INTERJECTION', 'det': 'DETERMINER',
       'article': 'DETERMINER', 'num': 'NUMBER', 'phrase': 'PHRASE', 'prep_phrase': 'PHRASE',
       'adv_phrase': 'PHRASE', 'proverb': 'PHRASE', 'name': 'NAME', 'particle': 'PARTICLE',
       'abbrev': 'ABBREVIATION', 'contraction': 'CONTRACTION'}
VI_LETTERS = re.compile('[àáảãạăằắẳẵặâầấẩẫậđèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵ]')
FORM_GLOSS = re.compile(r'(quá khứ|phân từ|số nhiều|ngôi thứ ba|viết tắt|cách viết khác|dạng).{0,30} của ', re.I)


def norm(s):
    s = s.replace('’', "'").replace('‘', "'").strip().lower()
    return re.sub(r'[\s\-_]+', ' ', s).strip()


def fold(s):
    s = s.replace('đ', 'd').replace('Đ', 'D')
    return ''.join(c for c in unicodedata.normalize('NFD', s) if unicodedata.category(c) != 'Mn').lower()


def profane(text):
    # Compared with diacritics: folded, "đĩ" would match "đi" and "cặc" would match "các".
    return bool(set(re.findall(r'\w+', text.lower())) & PROFANITY)


def overlap(a, b):
    ta, tb = set(re.findall(r'\w+', fold(a))), set(re.findall(r'\w+', fold(b)))
    return bool(ta and tb) and len(ta & tb) >= max(1, min(len(ta), len(tb)) // 2)


def src(name):
    return os.path.join(SOURCES, name)


def fetch():
    os.makedirs(SOURCES, exist_ok=True)
    for name, url in DOWNLOADS.items():
        if os.path.exists(src(name)):
            print('have', name)
            continue
        print('downloading', name)
        urllib.request.urlretrieve(url, src(name) + '.part')
        os.replace(src(name) + '.part', src(name))


def form_label(tags, pos):
    if 'past' in tags and 'participle' in tags:
        return 'pastParticiple'
    if 'past' in tags:
        return 'past'
    if 'gerund' in tags or 'present' in tags:
        return 'ing'
    if 'participle' in tags:
        return 'pastParticiple'
    if 'plural' in tags and pos == 'noun':
        return 'plural'
    if 'comparative' in tags:
        return 'comparative'
    if 'superlative' in tags:
        return 'superlative'
    if 'third-person' in tags:
        return 'thirdPerson'
    return 'form'


def pick_ipa(sounds):
    uk = us = None
    for s in sounds:
        ipa, tags = s.get('ipa'), set(s.get('tags') or [])
        if not ipa or not ipa.startswith('/'):
            continue
        if not uk and tags & {'Received-Pronunciation', 'UK', 'British'}:
            uk = ipa
        if not us and tags & {'General-American', 'US', 'American'}:
            us = ipa
    if not (uk or us):
        plain = [s['ipa'] for s in sounds if s.get('ipa', '').startswith('/') and not s.get('tags')]
        if plain:
            uk = us = plain[0]
    return uk, us


def build(version):
    level, cefr_pos = {}, collections.defaultdict(list)
    for name in ['cefrj.csv', 'octanove_c1c2.csv']:
        for r in csv.DictReader(open(src(name), encoding='utf-8')):
            for h in r['headword'].split('/'):
                h = norm(h)
                if h:
                    # A word listed in several parts of speech takes its lowest level.
                    level[h] = min(level.get(h, 'C2'), r['CEFR'])
                    # "be-verb", "have-verb", "modal verb" are verbs here.
                    cefr_pos[h].append((r['CEFR'], 'verb' if 'verb' in r['pos'] else r['pos']))
    rank = {}
    for i, line in enumerate(open(src('en_50k.txt'), encoding='utf-8')):
        rank.setdefault(line.split()[0], i + 1)
    ipadict = {}
    for name, acc in [('en_UK.txt', 'uk'), ('en_US.txt', 'us')]:
        for line in open(src(name), encoding='utf-8'):
            w, _, ipa = line.rstrip('\n').partition('\t')
            ipadict.setdefault(norm(w), {}).setdefault(acc, ipa.split(',')[0].strip())

    # Vietnamese Wiktionary: FVDP's English entries.
    vi = collections.defaultdict(list)
    vi_ipa = {}
    with gzip.open(src('vi-extract.jsonl.gz'), 'rt', encoding='utf-8') as f:
        for line in f:
            e = json.loads(line)
            if e.get('lang_code') != 'en':
                continue
            pos = POS.get(e.get('pos'), 'OTHER')
            word = e['word'].replace('’', "'")
            if len(word) == 1 and word.isupper():
                continue
            for s in e.get('senses', []):
                tags = set(s.get('tags') or [])
                if tags & ({'form-of', 'alt-of', 'no-gloss'} | DROP_TAGS | OFFENSIVE):
                    continue
                g = (s.get('glosses') or [''])[0].strip()
                labels, drop = set(), False
                for m in re.findall(r'\(([^()]{2,30})\)', g):
                    code = VI_LABELS.get(m)
                    if code == 'DROP':
                        drop = True
                    elif code:
                        labels.add(code)
                    if code:
                        g = g.replace('(' + m + ')', '')
                g = re.sub(r'\s+', ' ', g).strip(' .;,')
                if not g or drop or profane(g) or FORM_GLOSS.search(g):
                    continue
                vi[(word, pos)].append((g, sorted(labels)))
            for snd in e.get('sounds', []):
                if snd.get('ipa', '').startswith('/'):
                    vi_ipa.setdefault(word, snd['ipa'])

    # Tatoeba pairs, shortest first per English token.
    def tsv(name, keep=None):
        out = {}
        with bz2.open(src(name), 'rt', encoding='utf-8') as f:
            for line in f:
                x = line.rstrip('\n').split('\t')
                if keep is None or x[0] in keep:
                    out[x[0]] = (x[2], x[3] if len(x) > 3 else '')
        return out
    links = [l.split()[:2] for l in bz2.open(src('vie-eng_links.tsv.bz2'), 'rt')]
    vie_s = tsv('vie_sentences_detailed.tsv.bz2')
    eng_s = tsv('eng_sentences_detailed.tsv.bz2', {b for _, b in links})
    tatoeba = collections.defaultdict(list)
    for a, b in links:
        if a in vie_s and b in eng_s and len(eng_s[b][0].split()) <= 12 and not profane(vie_s[a][0]):
            pair = (eng_s[b][0], vie_s[a][0], f'{b}:{a}:{eng_s[b][1]}:{vie_s[a][1]}')
            for t in set(re.findall(r"[a-z']+", eng_s[b][0].lower())):
                tatoeba[t].append(pair)
    for t in tatoeba:
        tatoeba[t].sort(key=lambda p: len(p[0]))

    # English Wiktionary.
    keep_words = {w for w, _ in vi} | set(level)
    forms = collections.defaultdict(set)
    alts = collections.defaultdict(set)
    en = collections.defaultdict(list)
    with gzip.open(src('en.jsonl.gz'), 'rt', encoding='utf-8') as f:
        for line in f:
            e = json.loads(line)
            w = e.get('word', '').replace('’', "'")
            senses = e.get('senses', [])
            for s in senses:
                tags = set(s.get('tags') or [])
                if tags & DROP_TAGS:
                    continue
                for fo in s.get('form_of') or []:
                    forms[norm(w)].add((fo.get('word', ''), form_label(tags, e.get('pos')), POS.get(e.get('pos'), 'OTHER')))
                for ao in s.get('alt_of') or []:
                    alts[norm(w)].add(ao.get('word', ''))
            has_vi = any(t.get('code') == 'vi' for s in senses for t in s.get('translations', [])) or any(
                t.get('code') == 'vi' for t in e.get('translations', []))
            n_w = norm(w)
            head = n_w.split()[0] if n_w else ''
            # Words kept even without Vietnamese, shown with an English definition: CEFR words and
            # phrasal verbs or idioms built on an A1-B1 word.
            common = n_w in level or (' ' in n_w and len(n_w.split()) <= 4 and e.get('pos') in ('verb', 'phrase', 'prep_phrase')
                                      and level.get(head) in ('A1', 'A2', 'B1'))
            if not (has_vi or w in keep_words or common):
                continue
            pos = POS.get(e.get('pos'), 'OTHER')
            uk, us = pick_ipa(e.get('sounds', []))
            out, loose = [], [t['word'] for t in e.get('translations', []) if t.get('code') == 'vi' and t.get('word')]
            for s in senses:
                tags = set(s.get('tags') or [])
                if tags & (DROP_TAGS | {'form-of', 'alt-of'}) or s.get('form_of') or s.get('alt_of'):
                    continue
                gl = (s.get('glosses') or [''])[-1]
                if not gl:
                    continue
                vis = [t['word'] for t in s.get('translations', [])
                       if t.get('code') == 'vi' and t.get('word') and not profane(t['word'])]
                ex = next((x['text'] for x in s.get('examples', []) if x.get('text') and len(x['text']) < 120
                           and w.lower() in x['text'].lower() and not profane(x['text'])), '')
                out.append({'idx': len(out), 'en': gl[:140], 'vi': vis, 'ex': ex, 'off': bool(tags & OFFENSIVE),
                            'labels': sorted({LABEL_TAGS[t] for t in tags if t in LABEL_TAGS})})
            if out:
                en[(w, pos, int(e.get('etymology_number') or 1))].append(
                    {'uk': uk, 'us': us, 'senses': out, 'loose': [t for t in loose if not profane(t)], 'common': common})

    # Merge into entries.
    entries, first_src = [], collections.Counter()
    english_words = {norm(w) for (w, _, _) in en} | {norm(w) for (w, _) in vi}
    # How many senses en.wikt gives a word in each part of speech: breaks ties between parts of
    # speech CEFR-J lists at the same level (*look* the verb before *look* the noun).
    pos_weight = collections.Counter()
    for (w, pos, _), ps in en.items():
        pos_weight[(norm(w), pos.lower())] += sum(len(p['senses']) for p in ps)
    # Words with a Vietnamese meaning in some part of speech never get an English-only row.
    with_vietnamese = {norm(w) for w, _ in vi} | {norm(w) for (w, _, _), ps in en.items()
                                                    if any(s['vi'] for p in ps for s in p['senses']) or any(p['loose'] for p in ps)}
    for (w, pos) in sorted({(w, p) for w, p, _ in en} | set(vi)):
        ets = [k for k in range(1, 10) if (w, pos, k) in en] or [None]
        built = {}
        for et in ets:
            parts = en.get((w, pos, et), []) if et else []
            senses, en_only, uk, us = [], [], None, None
            for p in parts:
                uk, us = uk or p['uk'], us or p['us']
                for s in p['senses']:
                    if s['off']:
                        continue
                    if s['vi']:
                        senses.append({'vi': ', '.join(dict.fromkeys(s['vi']))[:80], 'en': s['en'], 'ex': s['ex'],
                                       'labels': s['labels'], 'src': 'en', 'idx': s['idx']})
                    elif p['common']:
                        en_only.append({'vi': '', 'en': s['en'], 'ex': s['ex'][:100], 'labels': s['labels'], 'src': 'en'})
            if not senses:
                loose = [t for p in parts for t in p['loose']]
                first = next((x for p in parts for x in p['senses'] if not x['off']), None)
                if loose and first:
                    senses.append({'vi': ', '.join(dict.fromkeys(loose))[:80], 'en': first['en'], 'ex': first['ex'],
                                   'labels': [], 'src': 'en'})
            built[et] = [senses, en_only, uk, us]
        placed = {et: [] for et in ets}
        for g, labels in vi.get((w, pos), []):
            target = next((et for et in ets if any(overlap(g, s['vi']) for s in built[et][0])), ets[0])
            matched = any(overlap(g, s['vi']) for s in built[target][0])
            placed[target].append((matched, {'vi': g[:120], 'en': '', 'ex': '', 'labels': labels, 'src': 'fvdp'}))
        has_vietnamese = any(built[k][0] for k in ets) or any(placed[k] for k in ets)
        for et in ets:
            senses, en_only, uk, us = built[et]
            fv = [x for _, x in placed[et]]
            if senses and fv:
                top = fv[:3]
                agree = [x for x in senses if any(overlap(x['vi'], g['vi']) for g in top)]
                senses = agree + [x for x in senses if x not in agree]
                # FVDP's first gloss leads when FVDP has none of en.wikt's meanings, or when
                # en.wikt translates only rarer senses (*go*: "chạy, vận hành" but not "đi").
                first_translated = min(x.get('idx', 99) for x in senses)
                if first_translated > 1 or not any(overlap(x['vi'], g['vi']) for x in senses for g in fv):
                    senses = [fv[0]] + [x for x in senses if not overlap(x['vi'], fv[0]['vi'])]
                senses += [x for m, x in placed[et] if not m and x not in senses]
            elif not senses:
                senses = fv
            clean, seen = [], set()
            for x in senses:
                key = fold(x['vi']).strip()
                if not key or key in seen:
                    continue
                # FVDP sometimes glosses with another English word ("Sealskin"); Vietnamese
                # without diacritics ("kem") stays.
                if x['src'] == 'fvdp' and not VI_LETTERS.search(x['vi'].lower()) and norm(x['vi']) in english_words:
                    continue
                seen.add(key)
                clean.append(x)
            needs_meaning = False
            if not clean and en_only and not has_vietnamese and norm(w) not in with_vietnamese:
                clean, needs_meaning = en_only[:2], True
            if not clean:
                continue
            n = norm(w)
            common = n in level or (rank.get(n) or 10 ** 6) <= 50000
            core = common or any(s['src'] == 'en' and s['vi'] for s in clean) or needs_meaning
            if not core:
                continue
            if pos == 'NAME' and n not in level and not any(s['src'] == 'en' and s['vi'] for s in clean):
                continue
            if pos == 'OTHER' and not common:
                continue
            ipa_uk = uk or ipadict.get(n, {}).get('uk') or vi_ipa.get(w) or ''
            ipa_us = us or ipadict.get(n, {}).get('us') or vi_ipa.get(w) or ''
            example = next((s['ex'] for s in clean if s['ex']), '')
            ex_vi, ex_src = '', 'wiktionary' if example else ''
            if ' ' not in n and tatoeba.get(n) and not needs_meaning:
                # A sentence whose translation uses this entry's first meaning, so *bank* "bờ"
                # does not get a sentence about money.
                meanings = [m.lower().strip(' .()') for m in re.split(r'[,;]', clean[0]['vi'])]
                meanings = [m for m in meanings if len(m) >= 2]
                pair = next((p for p in tatoeba[n] if any(re.search(r'(^|\W)' + re.escape(m) + r'(\W|$)', p[1].lower())
                                                          for m in meanings)), None)
                if pair:
                    example, ex_vi, ex_src = pair[0], pair[1], 'tatoeba:' + pair[2].replace('\\N', '')
            senses_out = [[s['vi']] + s['labels'] for s in clean[:4]]
            entries.append({
                'word': w, 'norm': n, 'pos': pos,
                'level': level.get(n), 'rank': rank.get(n), 'uk': ipa_uk, 'us': ipa_us,
                'senses': senses_out, 'en': clean[0]['en'] if needs_meaning or not clean[0]['vi'] else '',
                'ex': example, 'ex_vi': ex_vi, 'ex_src': ex_src, 'needs': needs_meaning,
                # The part of speech CEFR-J lists at the lowest level comes first (*go* the verb, A1,
                # before *go* the noun, B1).
                'pos_rank': next((i for i, (_, p) in enumerate(sorted(cefr_pos.get(n) or [],
                                                                       key=lambda lp: (lp[0], -pos_weight[(n, lp[1])])))
                                  if p == pos.lower()), 9),
            })
            first_src['english only' if needs_meaning else clean[0]['src']] += 1

    # Write the pack.
    os.makedirs(OUT_DIR, exist_ok=True)
    tmp = os.path.join(ROOT, 'build', 'dictionary', f'en-vi-{version}.sqlite')
    if os.path.exists(tmp):
        os.remove(tmp)
    db = sqlite3.connect(tmp)
    db.executescript('''
    CREATE TABLE meta(key TEXT PRIMARY KEY, value TEXT NOT NULL);
    CREATE TABLE entry(id INTEGER PRIMARY KEY, word TEXT NOT NULL, norm TEXT NOT NULL,
      pos TEXT NOT NULL, pos_rank INTEGER NOT NULL, level TEXT, rank INTEGER, uk TEXT NOT NULL, us TEXT NOT NULL,
      senses TEXT NOT NULL, en TEXT NOT NULL, ex TEXT NOT NULL, ex_vi TEXT NOT NULL, ex_src TEXT NOT NULL,
      needs INTEGER NOT NULL);
    CREATE INDEX entry_norm ON entry(norm);
    CREATE INDEX entry_level ON entry(level, rank);
    CREATE TABLE form(form TEXT NOT NULL, lemma TEXT NOT NULL, pos TEXT NOT NULL, label TEXT NOT NULL,
      PRIMARY KEY (form, lemma, pos)) WITHOUT ROWID;
    CREATE TABLE alt(variant TEXT NOT NULL, canonical TEXT NOT NULL, PRIMARY KEY (variant, canonical)) WITHOUT ROWID;
    CREATE VIRTUAL TABLE vi_index USING fts5(meaning, content='', contentless_delete=1,
      tokenize = "unicode61 remove_diacritics 2");
    ''')
    for i, e in enumerate(entries, 1):
        db.execute('INSERT INTO entry VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)', (
            i, e['word'], e['norm'], e['pos'], e['pos_rank'], e['level'], e['rank'], e['uk'], e['us'],
            json.dumps(e['senses'], ensure_ascii=False, separators=(',', ':')), e['en'], e['ex'], e['ex_vi'],
            e['ex_src'], int(e['needs'])))
        if not e['needs']:
            db.execute('INSERT INTO vi_index(rowid, meaning) VALUES(?, ?)', (i, ' | '.join(s[0] for s in e['senses'])))
    known = {e['norm'] for e in entries}
    db.executemany('INSERT OR IGNORE INTO form VALUES(?,?,?,?)', sorted(
        (f_, norm(lemma), fpos, lab) for f_, pairs in forms.items() for lemma, lab, fpos in pairs
        if norm(lemma) in known and norm(lemma) != f_ and len(f_) > 1))
    db.executemany('INSERT OR IGNORE INTO alt VALUES(?,?)', sorted(
        (v, norm(c)) for v, cs in alts.items() for c in cs
        if norm(c) in known and norm(c) != v and len(v) >= len(norm(c)) - 3))
    built_at = datetime.date.today().isoformat()
    db.executemany('INSERT INTO meta VALUES(?,?)', [
        ('version', str(version)), ('pair', 'en-vi'), ('built', built_at),
        ('sources', 'Wiktionary (vi, en) CC BY-SA 4.0; FVDP – Hồ Ngọc Đức; ipa-dict MIT; '
                    'CEFR-J Wordlist 1.5 (Tono Laboratory, TUFS); Octanove C1/C2 CC BY-SA 4.0; '
                    'FrequencyWords CC BY-SA 4.0; Tatoeba CC BY 2.0 FR'),
        ('license', 'CC BY-SA 4.0'),
    ])
    db.commit()
    db.execute('VACUUM')
    db.close()
    raw = open(tmp, 'rb').read()
    packed = gzip.compress(raw, 9, mtime=0)
    out = os.path.join(OUT_DIR, f'{version}.sqlite.gz')
    open(out, 'wb').write(packed)
    manifest = json.load(open(MANIFEST, encoding='utf-8'))
    manifest.setdefault('dictionaries', {})['en-vi'] = {
        'version': version, 'path': f'dictionary/en-vi/{version}.sqlite.gz',
        'bytes': len(packed), 'sha256': hashlib.sha256(packed).hexdigest(),
    }
    open(MANIFEST, 'w', encoding='utf-8').write(json.dumps(manifest, indent=2, ensure_ascii=False) + '\n')
    report(entries, level, first_src, len(raw), len(packed))
    print(f'{len(entries)} entries, {len(raw) / 1e6:.1f} MB, {len(packed) / 1e6:.1f} MB gzip -> {out}')


def report(entries, level, first_src, raw, packed):
    by_norm = collections.defaultdict(list)
    for e in entries:
        by_norm[e['norm']].append(e)
    lines = ['# Dictionary pack report', '', f'Entries: {len(entries)}; {raw / 1e6:.1f} MB, {packed / 1e6:.1f} MB gzip.',
             f'First meaning from: {dict(first_src)}', '', '| Level | Words | Vietnamese | English only | Missing |',
             '|---|---|---|---|---|']
    per = collections.defaultdict(lambda: [0, 0, 0, 0])
    for w, l in level.items():
        rows = by_norm.get(w, [])
        c = per[l]
        c[0] += 1
        if any(not r['needs'] for r in rows):
            c[1] += 1
        elif rows:
            c[2] += 1
        else:
            c[3] += 1
    for l in sorted(per):
        lines.append(f'| {l} | ' + ' | '.join(str(x) for x in per[l]) + ' |')
    lines += ['', '## Sample (fixed)', '']
    words = sorted(w for w, l in level.items() if l in ('A1', 'A2', 'B1') and w in by_norm)
    for w in words[::max(1, len(words) // 300)][:300]:
        e = sorted(by_norm[w], key=lambda r: (r['needs'], r['pos_rank']))[0]
        lines.append(f"- **{e['word']}** {e['pos']} {e['uk']} — " + ' · '.join(s[0] for s in e['senses'][:3]))
    os.makedirs(os.path.dirname(REPORT), exist_ok=True)
    open(REPORT, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')


if __name__ == '__main__':
    if len(sys.argv) >= 2 and sys.argv[1] == 'fetch':
        fetch()
    elif len(sys.argv) == 3 and sys.argv[1] == 'build':
        build(int(sys.argv[2]))
    else:
        print(__doc__)
        sys.exit(1)
