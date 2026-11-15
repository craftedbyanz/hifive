import { env } from "cloudflare:test";
import { describe, expect, it } from "vitest";

import { handler, hlc, rec, syncAs, token } from "./helpers";

async function req(method: string, path: string, uid: string | null, body?: unknown) {
  const res = await handler.fetch(
    new Request(`https://api.test${path}`, {
      method,
      headers: {
        "content-type": "application/json",
        ...(uid ? { authorization: `Bearer ${await token(uid)}` } : {}),
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    }),
    env,
  );
  return { status: res.status, body: (await res.json()) as any };
}

const count = async (sql: string, ...args: unknown[]) =>
  (await env.DB.prepare(sql).bind(...args).first<{ n: number }>())!.n;

describe("account deletion", () => {
  it("needs a signed-in caller and DELETE", async () => {
    expect((await req("DELETE", "/v1/account", null)).status).toBe(401);
    expect((await req("POST", "/v1/account", "u1")).status).toBe(405);
  });

  it("removes the caller's data and leaves everyone else's", async () => {
    await syncAs("u1", "d1", 0, [rec("setting", "name", { v: "Lan" }, hlc(1))]);
    await syncAs("u2", "d2", 0, [rec("setting", "name", { v: "Minh" }, hlc(1))]);
    const deck = { deckId: "d", title: "Travel", description: "", icon: 0, language: "en", words: [{ word: "ticket", meaning: "vé" }] };
    const mine = (await req("POST", "/v1/shares", "u1", { ...deck, public: true, author: "Lan" })).body.code;
    const theirs = (await req("POST", "/v1/shares", "u2", { ...deck, public: true, author: "Minh" })).body.code;
    await req("POST", `/v1/shares/${theirs}/adds`, "u1");
    await req("POST", `/v1/shares/${mine}/adds`, "u2");
    await req("POST", `/v1/shares/${theirs}/block`, "u1");

    // u1 owns a class u2 joined, and is in u2's group.
    const cls = (await req("POST", "/v1/circles", "u1", { kind: "class", name: "Lớp A" })).body.circle;
    await req("POST", "/v1/circles/join", "u2", { code: cls.code });
    const grp = (await req("POST", "/v1/circles", "u2", { name: "Nhóm B" })).body.circle;
    await req("POST", "/v1/circles/join", "u1", { code: grp.code });

    const res = await req("DELETE", "/v1/account", "u1");
    expect(res).toEqual({ status: 200, body: { ok: true } });

    for (const table of ["records", "devices", "users", "shares", "share_adds", "blocks", "circle_members"]) {
      expect(await count(`SELECT count(*) AS n FROM ${table} WHERE uid = ?1`, "u1"), table).toBe(0);
    }
    expect(await count("SELECT count(*) AS n FROM share_adds WHERE code = ?1", mine)).toBe(0);
    // Everyone else keeps theirs; the class passes to its remaining member.
    expect(await count("SELECT count(*) AS n FROM records WHERE uid = ?1", "u2")).toBeGreaterThan(0);
    expect(await count("SELECT count(*) AS n FROM shares WHERE uid = ?1", "u2")).toBe(1);
    const owner = await env.DB.prepare("SELECT owner FROM circles WHERE id = ?1").bind(cls.id).first<{ owner: string }>();
    expect(owner?.owner).toBe("u2");
    expect((await req("GET", `/v1/shares/${mine}`, null)).status).toBe(404);

    // Signing in again starts empty.
    const fresh = await syncAs("u1", "d1", 0);
    expect(fresh.records).toEqual([]);
  });
});
