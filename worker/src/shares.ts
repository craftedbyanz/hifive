/**
 * Decks shared by link or code (Community, step 1). A signed-in learner
 * publishes a snapshot of one of their decks and gets a six-character code;
 * anyone with the code or its link can read the snapshot and copy the deck
 * into their own. Shares are unlisted: nothing lists them.
 */

/** Letters and digits that can't be mistaken for each other (no 0/O, 1/I/L). */
const alphabet = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
export const codePattern = /^[A-HJ-NP-Z2-9]{6}$/;

export const shareLimits = {
  words: 500,
  sharesPerAccount: 100,
  bodyBytes: 512 * 1024,
  /** Reports from this many accounts hide a public deck. */
  reportsToHide: 3,
  explorePage: 20,
} as const;

export const reportReasons = ["offensive", "spam", "wrong", "copyright", "other"] as const;

export interface SharedWord {
  word: string;
  meaning: string;
  phonetic: string;
  example: string;
  partOfSpeech: string;
  definition: string;
}

export interface SharedDeck {
  title: string;
  description: string;
  icon: number;
  language: string;
  words: SharedWord[];
}

const text = (value: unknown, max: number, required = false): string | null => {
  if (value === undefined || value === null) return required ? null : "";
  if (typeof value !== "string") return null;
  const v = value.trim();
  if (v.length > max || (required && v.length === 0)) return null;
  return v;
};

export interface ShareRequest {
  deckId: string;
  deck: SharedDeck;
  /** Listed in Explore under [author]. */
  isPublic: boolean;
  author: string;
}

/** Checks a share request; returns it, or what's wrong. */
export function parseShare(body: unknown): ShareRequest | string {
  if (typeof body !== "object" || body === null || Array.isArray(body)) return "body";
  const b = body as Record<string, unknown>;
  const deckId = text(b.deckId, 200, true);
  if (deckId === null) return "deckId";
  const title = text(b.title, 80, true);
  if (title === null) return "title";
  const description = text(b.description, 300);
  if (description === null) return "description";
  const language = text(b.language, 8, true);
  if (language === null) return "language";
  const icon = b.icon ?? 0;
  if (typeof icon !== "number" || !Number.isInteger(icon) || icon < 0 || icon > 99) return "icon";
  if (!Array.isArray(b.words) || b.words.length === 0 || b.words.length > shareLimits.words) {
    return "words";
  }
  const words: SharedWord[] = [];
  for (const [i, raw] of b.words.entries()) {
    if (typeof raw !== "object" || raw === null) return `words[${i}]`;
    const w = raw as Record<string, unknown>;
    const word = text(w.word, 120, true);
    const meaning = text(w.meaning, 300, true);
    const phonetic = text(w.phonetic, 80);
    const example = text(w.example, 400);
    const partOfSpeech = text(w.partOfSpeech, 20);
    const definition = text(w.definition, 400);
    if (
      word === null ||
      meaning === null ||
      phonetic === null ||
      example === null ||
      partOfSpeech === null ||
      definition === null
    ) {
      return `words[${i}]`;
    }
    words.push({ word, meaning, phonetic, example, partOfSpeech, definition });
  }
  const isPublic = b.public ?? false;
  if (typeof isPublic !== "boolean") return "public";
  const author = text(b.author, 40);
  if (author === null) return "author";
  return { deckId, deck: { title, description, icon, language, words }, isPublic, author };
}

function newCode(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(6));
  return Array.from(bytes, (b) => alphabet[b % alphabet.length]).join("");
}

/**
 * Publishes a deck for [uid]: the same deck keeps its code and gets the new
 * snapshot, and is listed in Explore while [ShareRequest.isPublic]. Returns
 * the code, or null when the account has too many shares.
 */
export async function publish(
  db: D1Database,
  uid: string,
  share: ShareRequest,
  now: Date,
): Promise<string | null> {
  const { deckId, deck, isPublic, author } = share;
  const at = now.toISOString();
  const data = JSON.stringify(deck);
  const listed = [
    isPublic ? 1 : 0,
    author,
    deck.language,
    deck.title,
    deck.description,
    deck.icon,
    deck.words.length,
  ] as const;
  const existing = await db
    .prepare("SELECT code FROM shares WHERE uid = ?1 AND deck_id = ?2")
    .bind(uid, deckId)
    .first<{ code: string }>();
  if (existing) {
    await db
      .prepare(
        `UPDATE shares SET data = ?1, updated_at = ?2, public = ?3, author = ?4,
           language = ?5, title = ?6, description = ?7, icon = ?8, word_count = ?9,
           published_at = CASE WHEN ?3 = 1 THEN COALESCE(published_at, ?2) ELSE NULL END
         WHERE code = ?10`,
      )
      .bind(data, at, ...listed, existing.code)
      .run();
    return existing.code;
  }
  const { n } = (await db
    .prepare("SELECT COUNT(*) AS n FROM shares WHERE uid = ?1")
    .bind(uid)
    .first<{ n: number }>())!;
  if (n >= shareLimits.sharesPerAccount) return null;
  for (let attempt = 0; attempt < 5; attempt++) {
    const code = newCode();
    const inserted = await db
      .prepare(
        `INSERT INTO shares (code, uid, deck_id, data, created_at, updated_at,
           public, author, language, title, description, icon, word_count, published_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12,
           CASE WHEN ?6 = 1 THEN ?5 ELSE NULL END)
         ON CONFLICT (code) DO NOTHING`,
      )
      .bind(code, uid, deckId, data, at, ...listed)
      .run();
    if (inserted.meta.changes === 1) return code;
  }
  throw new Error("no free share code");
}

/** The deck shared under [code], or null. */
export async function read(db: D1Database, code: string): Promise<SharedDeck | null> {
  const row = await db
    .prepare("SELECT data FROM shares WHERE code = ?1")
    .bind(code)
    .first<{ data: string }>();
  return row ? (JSON.parse(row.data) as SharedDeck) : null;
}

/** Stops sharing [code] if [uid] shared it; true when something was removed. */
export async function unpublish(db: D1Database, uid: string, code: string): Promise<boolean> {
  const res = await db
    .prepare("DELETE FROM shares WHERE code = ?1 AND uid = ?2")
    .bind(code, uid)
    .run();
  return res.meta.changes === 1;
}

export interface PublicDeck {
  code: string;
  title: string;
  description: string;
  icon: number;
  wordCount: number;
  author: string;
  adds: number;
  publishedAt: string;
}

/**
 * A page of public decks in [language], most added or newest first, whose
 * title or description holds [query]. A signed-in [viewer] doesn't see
 * decks they reported or decks of accounts they blocked.
 */
export async function explore(
  db: D1Database,
  options: { language: string; sort: "popular" | "new"; query: string; offset: number; viewer: string | null },
): Promise<{ decks: PublicDeck[]; next: number | null }> {
  const { language, sort, query, offset, viewer } = options;
  const order = sort === "new" ? "published_at DESC" : "adds DESC, published_at DESC";
  const like = `%${query.toLowerCase().replace(/[\\%_]/g, (c) => `\\${c}`)}%`;
  const rows = await db
    .prepare(
      `SELECT code, title, description, icon, word_count AS wordCount, author, adds,
              published_at AS publishedAt
         FROM shares
        WHERE public = 1 AND hidden = 0 AND language = ?1
          AND (?2 = '%%' OR lower(title) LIKE ?2 ESCAPE '\\' OR lower(description) LIKE ?2 ESCAPE '\\')
          AND (?3 IS NULL OR (
                uid NOT IN (SELECT blocked_uid FROM blocks WHERE uid = ?3)
            AND code NOT IN (SELECT code FROM share_reports WHERE uid = ?3)))
        ORDER BY ${order}
        LIMIT ?4 OFFSET ?5`,
    )
    .bind(language, like, viewer, shareLimits.explorePage + 1, offset)
    .all<PublicDeck>();
  const decks = rows.results.slice(0, shareLimits.explorePage);
  return {
    decks,
    next: rows.results.length > shareLimits.explorePage ? offset + decks.length : null,
  };
}

/** Counts [uid] adding the deck [code], once per account; the new count. */
export async function countAdd(db: D1Database, uid: string, code: string): Promise<number | null> {
  const owner = await db.prepare("SELECT uid FROM shares WHERE code = ?1").bind(code).first<{ uid: string }>();
  if (!owner) return null;
  if (owner.uid !== uid) {
    const added = await db
      .prepare("INSERT INTO share_adds (code, uid) VALUES (?1, ?2) ON CONFLICT DO NOTHING")
      .bind(code, uid)
      .run();
    if (added.meta.changes === 1) {
      await db.prepare("UPDATE shares SET adds = adds + 1 WHERE code = ?1").bind(code).run();
    }
  }
  const row = await db.prepare("SELECT adds FROM shares WHERE code = ?1").bind(code).first<{ adds: number }>();
  return row?.adds ?? 0;
}

/**
 * Records [uid]'s report of [code]; reports from enough accounts hide it
 * from Explore until someone looks. False when there is no such deck.
 */
export async function report(
  db: D1Database,
  uid: string,
  code: string,
  reason: string,
  now: Date,
): Promise<boolean> {
  const owner = await db.prepare("SELECT uid FROM shares WHERE code = ?1").bind(code).first<{ uid: string }>();
  if (!owner) return false;
  await db
    .prepare(
      `INSERT INTO share_reports (code, uid, reason, created_at) VALUES (?1, ?2, ?3, ?4)
       ON CONFLICT DO NOTHING`,
    )
    .bind(code, uid, reason, now.toISOString())
    .run();
  await db
    .prepare(
      `UPDATE shares SET hidden = 1 WHERE code = ?1
         AND (SELECT COUNT(*) FROM share_reports WHERE code = ?1) >= ?2`,
    )
    .bind(code, shareLimits.reportsToHide)
    .run();
  return true;
}

/** [uid] blocks whoever shared [code]. False when there is no such deck. */
export async function blockOwner(db: D1Database, uid: string, code: string, now: Date): Promise<boolean> {
  const owner = await db.prepare("SELECT uid FROM shares WHERE code = ?1").bind(code).first<{ uid: string }>();
  if (!owner) return false;
  if (owner.uid !== uid) {
    await db
      .prepare("INSERT INTO blocks (uid, blocked_uid, created_at) VALUES (?1, ?2, ?3) ON CONFLICT DO NOTHING")
      .bind(uid, owner.uid, now.toISOString())
      .run();
  }
  return true;
}

/** [uid] unblocks everyone; how many were unblocked. */
export async function unblockAll(db: D1Database, uid: string): Promise<number> {
  return (await db.prepare("DELETE FROM blocks WHERE uid = ?1").bind(uid).run()).meta.changes;
}

const escape = (s: string) =>
  s.replace(/[&<>"']/g, (c) => `&#${c.charCodeAt(0)};`);

/**
 * The page a shared link opens: the deck's title, size and first words, and
 * the code to enter in the app. In Vietnamese, hifive's first language.
 */
export function sharePage(code: string, deck: SharedDeck | null): string {
  const head = `<!doctype html><html lang="vi"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${deck ? `${escape(deck.title)} · hifive` : "hifive"}</title>
<style>
body{margin:0;font-family:-apple-system,system-ui,sans-serif;background:#f8fbfc;color:#111827}
main{max-width:440px;margin:0 auto;padding:40px 20px}
.brand{font-weight:800;font-size:20px;letter-spacing:-.3px}
.card{background:#fff;border:1px solid #e7e9ed;border-radius:24px;padding:22px;margin-top:20px}
h1{font-size:24px;margin:0 0 4px}
.muted{color:#6b7280;font-size:14px;line-height:1.5}
ul{list-style:none;padding:0;margin:16px 0 0}
li{display:flex;justify-content:space-between;gap:12px;padding:9px 0;border-top:1px solid #f0f1f3;font-size:15px}
li span:last-child{color:#6b7280;text-align:right}
.code{font-size:34px;font-weight:800;letter-spacing:6px;text-align:center;background:#eef0ff;color:#2b2f92;border-radius:18px;padding:14px;margin:12px 0}
</style></head><body><main><div class="brand">hifive</div>`;
  if (!deck) {
    return `${head}<div class="card"><h1>Không tìm thấy bộ thẻ</h1>
<p class="muted">Mã ${escape(code)} không còn được chia sẻ, hoặc liên kết bị gõ sai.</p></div></main></body></html>`;
  }
  const words = deck.words
    .slice(0, 8)
    .map((w) => `<li><span>${escape(w.word)}</span><span>${escape(w.meaning)}</span></li>`)
    .join("");
  const more = deck.words.length > 8 ? `<p class="muted">và ${deck.words.length - 8} từ nữa</p>` : "";
  return `${head}<div class="card">
<p class="muted">Bộ thẻ được chia sẻ · ${deck.words.length} từ</p>
<h1>${escape(deck.title)}</h1>
${deck.description ? `<p class="muted">${escape(deck.description)}</p>` : ""}
<ul>${words}</ul>${more}</div>
<div class="card"><p class="muted">Để học bộ thẻ này, mở hifive, vào Bộ thẻ, chọn "Nhập mã" và nhập:</p>
<div class="code">${escape(code)}</div></div></main></body></html>`;
}
