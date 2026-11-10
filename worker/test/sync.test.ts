import { env } from "cloudflare:test";
import { describe, expect, it } from "vitest";

import { createHandler } from "../src/index";
import { limits } from "../src/sync";
import { call, handler, hlc, rec, syncAs, token } from "./helpers";

describe("authentication", () => {
  const body = { deviceId: "dev-a", cursor: 0, records: [] };

  it("accepts a valid Firebase token", async () => {
    expect((await call(body, await token("u1"))).status).toBe(200);
  });

  it.each([
    ["no token", async () => undefined],
    ["another project's token", () => token("u1", { audience: "other-project" })],
    ["an expired token", () => token("u1", { expiresIn: "-1m" })],
    ["a token signed by another key", () => token("u1", { foreignKey: true })],
    ["garbage", async () => "not-a-jwt"],
  ])("rejects %s", async (_, make) => {
    const res = await call(body, await make());
    expect(res.status).toBe(401);
    expect(await res.json()).toEqual({ error: "unauthorized" });
  });
});

describe("when Google's keys can't be fetched", () => {
  it("answers 503 rather than calling the token bad", async () => {
    const broken = createHandler(async () => {
      throw new TypeError("network down");
    });
    const res = await broken.fetch(
      new Request("https://api.test/v1/sync", {
        method: "POST",
        headers: { authorization: `Bearer ${await token("u1")}` },
        body: JSON.stringify({ deviceId: "d", cursor: 0, records: [] }),
      }),
      env,
    );
    expect(res.status).toBe(503);
    expect(await res.json()).toEqual({ error: "auth_unavailable" });
  });
});

describe("routing and validation", () => {
  it("answers 404 off the API and 405 for GET", async () => {
    const auth = await token("u1");
    const res = await handler.fetch(new Request("https://api.test/other"), env);
    expect(res.status).toBe(404);
    expect((await call(undefined, auth, "GET")).status).toBe(405);
  });

  it("rejects a body that isn't JSON", async () => {
    const res = await handler.fetch(
      new Request("https://api.test/v1/sync", {
        method: "POST",
        headers: { authorization: `Bearer ${await token("u1")}` },
        body: "{",
      }),
      env,
    );
    expect(res.status).toBe(400);
  });

  const ok = hlc(1);
  it.each([
    ["a missing device id", { cursor: 0, records: [] }],
    ["a negative cursor", { deviceId: "d", cursor: -1, records: [] }],
    ["device-only records", { deviceId: "d", cursor: 0, records: [rec("device", "sound", { v: false }, ok)] }],
    ["an unknown kind", { deviceId: "d", cursor: 0, records: [rec("secret", "x", {}, ok)] }],
    ["a malformed stamp", { deviceId: "d", cursor: 0, records: [rec("setting", "name", { v: "A" }, "123")] }],
    ["an empty id", { deviceId: "d", cursor: 0, records: [rec("setting", "", { v: "A" }, ok)] }],
    ["array data", { deviceId: "d", cursor: 0, records: [{ kind: "setting", id: "x", data: [1], hlc: ok }] }],
    [
      "oversized data",
      { deviceId: "d", cursor: 0, records: [rec("session", "s", { t: "x".repeat(limits.dataBytes) }, ok)] },
    ],
    [
      "too many records",
      {
        deviceId: "d",
        cursor: 0,
        records: Array.from({ length: limits.records + 1 }, (_, i) => rec("review", `r${i}`, {}, ok)),
      },
    ],
  ])("rejects %s and stores nothing", async (_, body) => {
    const res = await call(body, await token("u1"));
    expect(res.status).toBe(400);
    expect((await res.json()) as { error: string }).toMatchObject({ error: "invalid_request" });
    const { n } = (await env.DB.prepare("SELECT COUNT(*) AS n FROM records").first<{ n: number }>())!;
    expect(n).toBe(0);
  });
});

describe("sync", () => {
  it("returns what another device pushed, then nothing new", async () => {
    const pushed = await syncAs("u1", "iphone", 0, [
      rec("setting", "voice", { v: "Mia" }, hlc(1, "iphone")),
      rec("session", "s1", { title: "Bài 1" }, hlc(2, "iphone")),
    ]);
    expect(pushed.records).toHaveLength(2);

    const ipad = await syncAs("u1", "ipad", 0);
    expect(ipad.records.map((r) => [r.kind, r.id, r.data])).toEqual([
      ["setting", "voice", { v: "Mia" }],
      ["session", "s1", { title: "Bài 1" }],
    ]);
    const again = await syncAs("u1", "ipad", ipad.cursor);
    expect(again).toEqual({ cursor: ipad.cursor, hasMore: false, records: [] });
  });

  it("keeps the later stamp whichever device sends first", async () => {
    await syncAs("u1", "ipad", 0, [rec("setting", "voice", { v: "Zoe" }, hlc(20, "ipad"))]);
    const late = await syncAs("u1", "iphone", 0, [rec("setting", "voice", { v: "Mia" }, hlc(10, "iphone"))]);
    expect(late.records.find((r) => r.id === "voice")?.data).toEqual({ v: "Zoe" });
  });

  it("sends a newer change to devices that already synced", async () => {
    const first = await syncAs("u1", "ipad", 0, [rec("setting", "name", { v: "Lan" }, hlc(1, "ipad"))]);
    await syncAs("u1", "iphone", 0, [rec("setting", "name", { v: "Linh" }, hlc(5, "iphone"))]);
    const next = await syncAs("u1", "ipad", first.cursor);
    expect(next.records).toEqual([rec("setting", "name", { v: "Linh" }, hlc(5, "iphone"))]);
  });

  it("syncs deletions", async () => {
    await syncAs("u1", "iphone", 0, [rec("deck", "d1", { title: "T" }, hlc(1, "iphone"))]);
    await syncAs("u1", "iphone", 0, [rec("deck", "d1", null, hlc(2, "iphone"))]);
    const ipad = await syncAs("u1", "ipad", 0);
    expect(ipad.records).toEqual([rec("deck", "d1", null, hlc(2, "iphone"))]);
  });

  it("a retried request changes nothing", async () => {
    const batch = [
      rec("review", "r1", { wordId: "w", rating: 2 }, hlc(1)),
      rec("review", "r2", { wordId: "w", rating: 3 }, hlc(2)),
    ];
    const first = await syncAs("u1", "iphone", 0, batch);
    const retry = await syncAs("u1", "iphone", first.cursor, batch);
    expect(retry.records).toEqual([]);
    expect(retry.cursor).toBe(first.cursor);
    const { n } = (await env.DB.prepare("SELECT COUNT(*) AS n FROM records").first<{ n: number }>())!;
    expect(n).toBe(2);
  });

  it("pages through more than one response", async () => {
    const make = (from: number, count: number) =>
      Array.from({ length: count }, (_, i) => rec("review", `r${from + i}`, { i: from + i }, hlc(from + i + 1)));
    await syncAs("u1", "iphone", 0, make(0, limits.records));
    await syncAs("u1", "iphone", 0, make(limits.records, 20));
    const page1 = await syncAs("u1", "ipad", 0);
    expect(page1.records).toHaveLength(limits.records);
    expect(page1.hasMore).toBe(true);
    const page2 = await syncAs("u1", "ipad", page1.cursor);
    expect(page2.records.map((r) => r.id)).toEqual(Array.from({ length: 20 }, (_, i) => `r${limits.records + i}`));
    expect(page2.hasMore).toBe(false);
  });

  it("gives every change its own number when devices sync at once", async () => {
    const batch = (device: string) =>
      Array.from({ length: 50 }, (_, i) => rec("review", `${device}-${i}`, { i }, hlc(i + 1, device)));
    await Promise.all([
      syncAs("u1", "iphone", 0, batch("iphone")),
      syncAs("u1", "ipad", 0, batch("ipad")),
    ]);
    const counts = await env.DB.prepare(
      "SELECT COUNT(*) AS n, COUNT(DISTINCT seq) AS distinct_seq, MAX(seq) AS top FROM records WHERE uid = 'u1'",
    ).first<{ n: number; distinct_seq: number; top: number }>();
    expect(counts).toEqual({ n: 100, distinct_seq: 100, top: 100 });
    const all = await syncAs("u1", "laptop", 0);
    expect(all.records).toHaveLength(100);
  });

  it("keeps accounts apart", async () => {
    await syncAs("u1", "iphone", 0, [rec("setting", "name", { v: "Lan" }, hlc(1))]);
    expect((await syncAs("u2", "iphone", 0)).records).toEqual([]);
  });

  it("restarts a device whose cursor is ahead of the account", async () => {
    await syncAs("u1", "iphone", 0, [rec("setting", "name", { v: "Lan" }, hlc(1))]);
    const res = await syncAs("u1", "ipad", 999);
    expect(res.records.map((r) => r.id)).toEqual(["name"]);
  });

  it("records the account and its devices", async () => {
    const res = await call({ deviceId: "iphone", cursor: 0, records: [] }, await token("u1", { email: "lan@example.com" }));
    expect(res.status).toBe(200);
    await syncAs("u1", "ipad", 0);
    const user = await env.DB.prepare("SELECT email FROM users WHERE uid = 'u1'").first<{ email: string }>();
    expect(user?.email).toBe("lan@example.com");
    const { results } = await env.DB.prepare("SELECT device_id FROM devices WHERE uid = 'u1' ORDER BY device_id").all();
    expect(results.map((r) => r.device_id)).toEqual(["ipad", "iphone"]);
  });
});
