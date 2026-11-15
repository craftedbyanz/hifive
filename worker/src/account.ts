import { leave } from "./circles";

/**
 * Deletes everything the server keeps about [uid] (App Store guideline
 * 5.1.1(v)): synced records, devices, the decks they shared with what others
 * did to them (adds, reports, class assignments), their own adds, reports and
 * blocks, blocks of them, and their place in study groups and classes. A
 * circle they own passes to the next member, or goes when they were the last,
 * as when leaving. Counters others see (a deck's adds) are kept. The Firebase
 * account itself is deleted by the app, which holds the credentials.
 */
export async function deleteAccount(db: D1Database, uid: string): Promise<void> {
  const circles = await db
    .prepare("SELECT circle_id FROM circle_members WHERE uid = ?1")
    .bind(uid)
    .all<{ circle_id: string }>();
  for (const c of circles.results) await leave(db, uid, c.circle_id);

  const owned = "(SELECT code FROM shares WHERE uid = ?1)";
  await db.batch([
    db.prepare(`DELETE FROM share_adds WHERE code IN ${owned}`).bind(uid),
    db.prepare(`DELETE FROM share_reports WHERE code IN ${owned}`).bind(uid),
    db.prepare(`DELETE FROM assignments WHERE share_code IN ${owned}`).bind(uid),
    db.prepare("DELETE FROM shares WHERE uid = ?1").bind(uid),
    db.prepare("DELETE FROM share_adds WHERE uid = ?1").bind(uid),
    db.prepare("DELETE FROM share_reports WHERE uid = ?1").bind(uid),
    db.prepare("DELETE FROM blocks WHERE uid = ?1 OR blocked_uid = ?1").bind(uid),
    db.prepare("DELETE FROM records WHERE uid = ?1").bind(uid),
    db.prepare("DELETE FROM devices WHERE uid = ?1").bind(uid),
    db.prepare("DELETE FROM users WHERE uid = ?1").bind(uid),
  ]);
}
