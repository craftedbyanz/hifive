/** Record kinds the app syncs. `device` records never leave the device. */
export const syncedKinds = new Set([
  "setting",
  "session",
  "historyCleared",
  "deck",
  "word",
  "review",
  "game",
  "legacyStats",
  "firstUse",
]);

export const limits = {
  records: 500,
  idLength: 200,
  dataBytes: 64 * 1024,
  deviceIdLength: 64,
} as const;

/** An HLC stamp: 15 digits of milliseconds, a base-36 counter, the device. */
const hlcPattern = /^\d{15}:[0-9a-z]{4,8}:[A-Za-z0-9-]{1,64}$/;

export interface WireRecord {
  kind: string;
  id: string;
  data: Record<string, unknown> | null;
  hlc: string;
}

export interface SyncRequest {
  deviceId: string;
  cursor: number;
  records: WireRecord[];
}

export interface SyncResponse {
  cursor: number;
  records: WireRecord[];
  hasMore: boolean;
}

/** Checks a request body; returns the reason it is invalid, or the request. */
export function parseSyncRequest(body: unknown): SyncRequest | string {
  if (typeof body !== "object" || body === null) return "body must be an object";
  const { deviceId, cursor, records } = body as Record<string, unknown>;
  if (
    typeof deviceId !== "string" ||
    !/^[A-Za-z0-9-]+$/.test(deviceId) ||
    deviceId.length > limits.deviceIdLength
  ) {
    return "deviceId is invalid";
  }
  if (!Number.isSafeInteger(cursor) || (cursor as number) < 0) {
    return "cursor must be a non-negative integer";
  }
  if (!Array.isArray(records)) return "records must be an array";
  if (records.length > limits.records) {
    return `at most ${limits.records} records per request`;
  }
  const parsed: WireRecord[] = [];
  for (const [i, raw] of records.entries()) {
    if (typeof raw !== "object" || raw === null) return `records[${i}] is not an object`;
    const { kind, id, data, hlc } = raw as Record<string, unknown>;
    if (typeof kind !== "string" || !syncedKinds.has(kind)) {
      return `records[${i}].kind is not synced`;
    }
    if (typeof id !== "string" || id.length === 0 || id.length > limits.idLength) {
      return `records[${i}].id is invalid`;
    }
    if (typeof hlc !== "string" || !hlcPattern.test(hlc)) {
      return `records[${i}].hlc is invalid`;
    }
    if (data !== null && (typeof data !== "object" || Array.isArray(data))) {
      return `records[${i}].data must be an object or null`;
    }
    if (data !== null && JSON.stringify(data).length > limits.dataBytes) {
      return `records[${i}].data is too large`;
    }
    parsed.push({ kind, id, hlc, data: data as WireRecord["data"] });
  }
  return { deviceId, cursor: cursor as number, records: parsed };
}

/**
 * Stores the pushed records and returns what changed after the cursor.
 * Writes run in one D1 batch, which is a transaction, so two devices syncing
 * at once never share a change number.
 */
export async function sync(
  db: D1Database,
  uid: string,
  email: string | null,
  request: SyncRequest,
  now: Date,
): Promise<SyncResponse> {
  const at = now.toISOString();
  const bump = db.prepare(
    `UPDATE users SET seq = seq + 1 WHERE uid = ?1 AND NOT EXISTS (
       SELECT 1 FROM records WHERE uid = ?1 AND kind = ?2 AND id = ?3 AND hlc >= ?4)`,
  );
  const put = db.prepare(
    `INSERT INTO records (uid, kind, id, data, hlc, seq)
     VALUES (?1, ?2, ?3, ?4, ?5, (SELECT seq FROM users WHERE uid = ?1))
     ON CONFLICT (uid, kind, id) DO UPDATE SET
       data = excluded.data, hlc = excluded.hlc, seq = excluded.seq
     WHERE excluded.hlc > records.hlc`,
  );
  const statements: D1PreparedStatement[] = [
    db
      .prepare(
        `INSERT INTO users (uid, email, created_at, last_seen_at) VALUES (?1, ?2, ?3, ?3)
         ON CONFLICT (uid) DO UPDATE SET
           email = COALESCE(excluded.email, users.email),
           last_seen_at = excluded.last_seen_at`,
      )
      .bind(uid, email, at),
  ];
  for (const r of request.records) {
    // The change number only moves for a record that will win the write.
    statements.push(bump.bind(uid, r.kind, r.id, r.hlc));
    statements.push(
      put.bind(uid, r.kind, r.id, r.data === null ? null : JSON.stringify(r.data), r.hlc),
    );
  }
  statements.push(
    db
      .prepare(
        `INSERT INTO devices (uid, device_id, first_seen_at, last_sync_at) VALUES (?1, ?2, ?3, ?3)
         ON CONFLICT (uid, device_id) DO UPDATE SET last_sync_at = excluded.last_sync_at`,
      )
      .bind(uid, request.deviceId, at),
    db.prepare("SELECT seq FROM users WHERE uid = ?1").bind(uid),
  );
  const results = await db.batch<{ seq: number }>(statements);
  const latest = results[results.length - 1].results[0]?.seq ?? 0;

  // A cursor past the account's latest change (say, after a restore) can't
  // be trusted, so the device pulls everything again.
  const cursor = request.cursor > latest ? 0 : request.cursor;
  const { results: rows } = await db
    .prepare(
      `SELECT kind, id, data, hlc, seq FROM records
       WHERE uid = ?1 AND seq > ?2 ORDER BY seq LIMIT ?3`,
    )
    .bind(uid, cursor, limits.records + 1)
    .all<{ kind: string; id: string; data: string | null; hlc: string; seq: number }>();
  const page = rows.slice(0, limits.records);
  return {
    cursor: page.length > 0 ? page[page.length - 1].seq : cursor,
    hasMore: rows.length > limits.records,
    records: page.map((row) => ({
      kind: row.kind,
      id: row.id,
      hlc: row.hlc,
      data: row.data === null ? null : JSON.parse(row.data),
    })),
  };
}
