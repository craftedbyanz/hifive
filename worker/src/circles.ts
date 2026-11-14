/**
 * Study groups and classes (Community, steps 3 and 4). Both are circles
 * joined with a six-character code. Progress is read from the learning data
 * members already sync: a study day is a day with a rated review, a
 * finished lesson or a minute of listening, as the app counts it; a word of
 * an assignment is learned once the member has rated it. So there is one
 * record of progress, the app's own.
 */

const alphabet = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
export const circleCodePattern = /^[A-HJ-NP-Z2-9]{6}$/;
const datePattern = /^\d{4}-\d{2}-\d{2}$/;

export const circleLimits = {
  circlesPerAccount: 20,
  membersPerCircle: 60,
  assignmentsPerClass: 50,
} as const;

export type CircleKind = "group" | "class";

export interface CircleSummary {
  id: string;
  kind: CircleKind;
  name: string;
  goal: number;
  code: string;
  owner: boolean;
  members: number;
}

interface CircleRow {
  id: string;
  kind: CircleKind;
  name: string;
  goal: number;
  code: string;
  owner: string;
}

const code = () =>
  Array.from(crypto.getRandomValues(new Uint8Array(6)), (b) => alphabet[b % alphabet.length]).join("");

/** An opaque id for [uid] within [circleId], so uids never leave the server. */
async function memberId(circleId: string, uid: string): Promise<string> {
  const bytes = new Uint8Array(
    await crypto.subtle.digest("SHA-256", new TextEncoder().encode(`${circleId}:${uid}`)),
  );
  return Array.from(bytes.slice(0, 8), (b) => b.toString(16).padStart(2, "0")).join("");
}

/** Checks a name and goal; returns them, or what's wrong. */
export function parseCircle(body: unknown): { kind: CircleKind; name: string; goal: number } | string {
  if (typeof body !== "object" || body === null) return "body";
  const b = body as Record<string, unknown>;
  const kind = b.kind ?? "group";
  if (kind !== "group" && kind !== "class") return "kind";
  const name = typeof b.name === "string" ? b.name.trim() : "";
  if (name.length === 0 || name.length > 60) return "name";
  const goal = b.goal ?? 3;
  if (typeof goal !== "number" || !Number.isInteger(goal) || goal < 1 || goal > 7) return "goal";
  return { kind, name, goal };
}

async function circleCount(db: D1Database, uid: string): Promise<number> {
  return (await db
    .prepare("SELECT COUNT(*) AS n FROM circle_members WHERE uid = ?1")
    .bind(uid)
    .first<{ n: number }>())!.n;
}

/** Makes a circle owned by [uid]; null when they are in too many. */
export async function createCircle(
  db: D1Database,
  uid: string,
  c: { kind: CircleKind; name: string; goal: number },
  now: Date,
): Promise<CircleSummary | null> {
  if ((await circleCount(db, uid)) >= circleLimits.circlesPerAccount) return null;
  const id = crypto.randomUUID();
  const at = now.toISOString();
  for (let attempt = 0; attempt < 5; attempt++) {
    const c6 = code();
    const res = await db
      .prepare(
        `INSERT INTO circles (id, kind, name, goal, code, owner, created_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7) ON CONFLICT (code) DO NOTHING`,
      )
      .bind(id, c.kind, c.name, c.goal, c6, uid, at)
      .run();
    if (res.meta.changes === 1) {
      await db
        .prepare("INSERT INTO circle_members (circle_id, uid, joined_at) VALUES (?1, ?2, ?3)")
        .bind(id, uid, at)
        .run();
      return { id, kind: c.kind, name: c.name, goal: c.goal, code: c6, owner: true, members: 1 };
    }
  }
  throw new Error("no free circle code");
}

/** [uid] joins the circle with [joinCode]: "not_found", "full", "too_many" or the circle. */
export async function joinCircle(
  db: D1Database,
  uid: string,
  joinCode: string,
  now: Date,
): Promise<CircleSummary | "not_found" | "full" | "too_many"> {
  const c = await db.prepare("SELECT * FROM circles WHERE code = ?1").bind(joinCode).first<CircleRow>();
  if (!c) return "not_found";
  const already = await db
    .prepare("SELECT 1 FROM circle_members WHERE circle_id = ?1 AND uid = ?2")
    .bind(c.id, uid)
    .first();
  if (!already) {
    if ((await circleCount(db, uid)) >= circleLimits.circlesPerAccount) return "too_many";
    const { n } = (await db
      .prepare("SELECT COUNT(*) AS n FROM circle_members WHERE circle_id = ?1")
      .bind(c.id)
      .first<{ n: number }>())!;
    if (n >= circleLimits.membersPerCircle) return "full";
    await db
      .prepare("INSERT INTO circle_members (circle_id, uid, joined_at) VALUES (?1, ?2, ?3)")
      .bind(c.id, uid, now.toISOString())
      .run();
  }
  return (await mine(db, uid)).find((x) => x.id === c.id)!;
}

/** The circles [uid] is in, newest joined first. */
export async function mine(db: D1Database, uid: string): Promise<CircleSummary[]> {
  const rows = await db
    .prepare(
      `SELECT c.id, c.kind, c.name, c.goal, c.code, c.owner = ?1 AS owner,
              (SELECT COUNT(*) FROM circle_members x WHERE x.circle_id = c.id) AS members
         FROM circles c JOIN circle_members m ON m.circle_id = c.id
        WHERE m.uid = ?1
        ORDER BY m.joined_at DESC`,
    )
    .bind(uid)
    .all<Omit<CircleSummary, "owner"> & { owner: number }>();
  return rows.results.map((r) => ({ ...r, owner: r.owner === 1 }));
}

async function membership(db: D1Database, uid: string, id: string): Promise<CircleRow | null> {
  return db
    .prepare(
      `SELECT c.* FROM circles c JOIN circle_members m ON m.circle_id = c.id
        WHERE c.id = ?1 AND m.uid = ?2`,
    )
    .bind(id, uid)
    .first<CircleRow>();
}

/** The days in [from]..[to] (local dates) that [uid] studied. */
async function studyDays(db: D1Database, uid: string, from: string, to: string): Promise<string[]> {
  const rows = await db
    .prepare(
      `SELECT DISTINCT d FROM (
          SELECT substr(json_extract(data, '$.at'), 1, 10) AS d FROM records
           WHERE uid = ?1 AND kind = 'review' AND data IS NOT NULL
             AND json_extract(data, '$.rating') >= 0
          UNION
          SELECT substr(json_extract(data, '$.date'), 1, 10) FROM records
           WHERE uid = ?1 AND kind = 'session' AND data IS NOT NULL
          UNION
          SELECT day FROM (
            SELECT substr(id, -10) AS day, SUM(json_extract(data, '$.heard')) AS heard
              FROM records WHERE uid = ?1 AND kind = 'listen' AND data IS NOT NULL
             GROUP BY day)
           WHERE heard >= 60)
        WHERE d BETWEEN ?2 AND ?3 ORDER BY d`,
    )
    .bind(uid, from, to)
    .all<{ d: string }>();
  return rows.results.map((r) => r.d);
}

/** How many of [words] (lower-case) [uid] has rated. */
async function learned(db: D1Database, uid: string, words: string[]): Promise<number> {
  const row = await db
    .prepare(
      `SELECT COUNT(DISTINCT lower(json_extract(data, '$.word'))) AS n FROM records
        WHERE uid = ?1 AND kind = 'review' AND data IS NOT NULL
          AND json_extract(data, '$.rating') >= 0
          AND lower(json_extract(data, '$.word')) IN (SELECT value FROM json_each(?2))`,
    )
    .bind(uid, JSON.stringify(words))
    .first<{ n: number }>();
  return row?.n ?? 0;
}

async function nameOf(db: D1Database, uid: string): Promise<string> {
  const row = await db
    .prepare("SELECT json_extract(data, '$.v') AS v FROM records WHERE uid = ?1 AND kind = 'setting' AND id = 'name'")
    .bind(uid)
    .first<{ v: string | null }>();
  return typeof row?.v === "string" ? row.v.slice(0, 40) : "";
}

function addDays(date: string, n: number): string {
  const d = new Date(`${date}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + n);
  return d.toISOString().slice(0, 10);
}

/**
 * A circle as [uid] sees it: its members with the days they studied in the
 * week from [from] and, for a class, the decks set with each member's
 * progress. A student of a class sees only their own progress and their
 * teacher; a group shows everyone.
 */
export async function detail(
  db: D1Database,
  uid: string,
  id: string,
  from: string,
) {
  if (!datePattern.test(from)) return null;
  const c = await membership(db, uid, id);
  if (!c) return null;
  const to = addDays(from, 6);
  const uids = (
    await db
      .prepare("SELECT uid FROM circle_members WHERE circle_id = ?1 ORDER BY joined_at")
      .bind(id)
      .all<{ uid: string }>()
  ).results.map((r) => r.uid);
  const teacher = c.kind === "class" && c.owner === uid;
  const visible = c.kind === "class" && !teacher ? uids.filter((u) => u === uid || u === c.owner) : uids;
  const people = [];
  for (const u of visible) {
    people.push({
      id: await memberId(id, u),
      name: await nameOf(db, u),
      me: u === uid,
      owner: u === c.owner,
      days: await studyDays(db, u, from, to),
    });
  }
  const rows = (
    await db
      .prepare("SELECT * FROM assignments WHERE circle_id = ?1 ORDER BY due, created_at")
      .bind(id)
      .all<{ id: string; share_code: string; title: string; words: string; due: string }>()
  ).results;
  const assignments = [];
  for (const a of rows) {
    const words = JSON.parse(a.words) as string[];
    const progress: Record<string, number> = {};
    for (const u of teacher ? uids.filter((x) => x !== uid) : [uid]) {
      progress[await memberId(id, u)] = await learned(db, u, words);
    }
    assignments.push({ id: a.id, shareCode: a.share_code, title: a.title, total: words.length, due: a.due, progress });
  }
  return {
    id: c.id,
    kind: c.kind,
    name: c.name,
    goal: c.goal,
    code: c.code,
    owner: c.owner === uid,
    members: uids.length,
    week: Array.from({ length: 7 }, (_, i) => addDays(from, i)),
    people,
    assignments,
  };
}

/** Renames a circle or changes its goal; only its owner may. */
export async function updateCircle(
  db: D1Database,
  uid: string,
  id: string,
  c: { name: string; goal: number },
): Promise<boolean> {
  const res = await db
    .prepare("UPDATE circles SET name = ?1, goal = ?2 WHERE id = ?3 AND owner = ?4")
    .bind(c.name, c.goal, id, uid)
    .run();
  return res.meta.changes === 1;
}

/**
 * [uid] leaves circle [id]. An owner leaving hands it to whoever joined
 * first after them; the last member leaving deletes it.
 */
export async function leave(db: D1Database, uid: string, id: string): Promise<boolean> {
  const c = await membership(db, uid, id);
  if (!c) return false;
  await db.prepare("DELETE FROM circle_members WHERE circle_id = ?1 AND uid = ?2").bind(id, uid).run();
  const next = await db
    .prepare("SELECT uid FROM circle_members WHERE circle_id = ?1 ORDER BY joined_at LIMIT 1")
    .bind(id)
    .first<{ uid: string }>();
  if (!next) {
    await db.batch([
      db.prepare("DELETE FROM assignments WHERE circle_id = ?1").bind(id),
      db.prepare("DELETE FROM circles WHERE id = ?1").bind(id),
    ]);
  } else if (c.owner === uid) {
    await db.prepare("UPDATE circles SET owner = ?1 WHERE id = ?2").bind(next.uid, id).run();
  }
  return true;
}

/** The owner removes the member [member] (an id from [detail]). */
export async function removeMember(db: D1Database, uid: string, id: string, member: string): Promise<boolean> {
  const c = await membership(db, uid, id);
  if (!c || c.owner !== uid) return false;
  const uids = (
    await db.prepare("SELECT uid FROM circle_members WHERE circle_id = ?1").bind(id).all<{ uid: string }>()
  ).results.map((r) => r.uid);
  for (const u of uids) {
    if (u !== uid && (await memberId(id, u)) === member) {
      await db.prepare("DELETE FROM circle_members WHERE circle_id = ?1 AND uid = ?2").bind(id, u).run();
      return true;
    }
  }
  return false;
}

/**
 * The teacher of class [id] sets the shared deck [shareCode], due [due]:
 * "forbidden", "not_found" (no such deck), "too_many", or the new id.
 */
export async function assign(
  db: D1Database,
  uid: string,
  id: string,
  shareCode: string,
  due: string,
  now: Date,
): Promise<string> {
  const c = await membership(db, uid, id);
  if (!c || c.kind !== "class" || c.owner !== uid) return "forbidden";
  if (!datePattern.test(due)) return "bad_due";
  const share = await db.prepare("SELECT data FROM shares WHERE code = ?1").bind(shareCode).first<{ data: string }>();
  if (!share) return "not_found";
  const { n } = (await db
    .prepare("SELECT COUNT(*) AS n FROM assignments WHERE circle_id = ?1")
    .bind(id)
    .first<{ n: number }>())!;
  if (n >= circleLimits.assignmentsPerClass) return "too_many";
  const deck = JSON.parse(share.data) as { title: string; words: { word: string }[] };
  const words = [...new Set(deck.words.map((w) => w.word.trim().toLowerCase()))];
  const aid = crypto.randomUUID();
  await db
    .prepare(
      `INSERT INTO assignments (id, circle_id, share_code, title, words, due, created_at)
       VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)`,
    )
    .bind(aid, id, shareCode, deck.title, JSON.stringify(words), due, now.toISOString())
    .run();
  return aid;
}

/** The teacher removes an assignment. */
export async function unassign(db: D1Database, uid: string, id: string, assignment: string): Promise<boolean> {
  const c = await membership(db, uid, id);
  if (!c || c.owner !== uid) return false;
  const res = await db
    .prepare("DELETE FROM assignments WHERE id = ?1 AND circle_id = ?2")
    .bind(assignment, id)
    .run();
  return res.meta.changes === 1;
}
