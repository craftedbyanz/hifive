import { env } from "cloudflare:test";
import { describe, expect, it } from "vitest";

import { handler, token } from "./helpers";

const words = [{ word: "ticket", meaning: "vé" }];

async function req(method: string, path: string, body?: unknown, auth?: string) {
  return handler.fetch(
    new Request(`https://api.test${path}`, {
      method,
      headers: {
        "content-type": "application/json",
        ...(auth ? { authorization: `Bearer ${auth}` } : {}),
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    }),
    env,
  );
}

/** Shares [deckId] as [uid]; public unless told otherwise. */
async function share(uid: string, deckId: string, title: string, extra: Record<string, unknown> = {}) {
  const res = await req(
    "POST",
    "/v1/shares",
    { deckId, title, language: "en", words, public: true, author: `${uid} name`, ...extra },
    await token(uid),
  );
  return ((await res.json()) as { code: string }).code;
}

async function list(query = "", auth?: string) {
  const res = await req("GET", `/v1/explore?lang=en${query}`, undefined, auth);
  expect(res.status).toBe(200);
  return (await res.json()) as {
    decks: { code: string; title: string; author: string; adds: number; wordCount: number }[];
    next: number | null;
  };
}

describe("explore", () => {
  it("lists public decks only, in their language, with author and size", async () => {
    await share("u1", "d1", "Travel");
    await share("u1", "d2", "Private", { public: false });
    await share("u2", "d3", "Japanese", { language: "ja" });
    const { decks, next } = await list();
    expect(decks.map((d) => d.title)).toEqual(["Travel"]);
    expect(decks[0]).toMatchObject({ author: "u1 name", wordCount: 1, adds: 0 });
    expect(next).toBeNull();
  });

  it("making a deck private again takes it off the list", async () => {
    await share("u1", "d1", "Travel");
    await share("u1", "d1", "Travel", { public: false });
    expect((await list()).decks).toHaveLength(0);
  });

  it("finds decks by title, and sorts by adds or by date", async () => {
    const a = await share("u1", "d1", "Airport words");
    const b = await share("u2", "d2", "Kitchen words");
    for (const uid of ["u3", "u4"]) {
      expect((await req("POST", `/v1/shares/${b}/adds`, undefined, await token(uid))).status).toBe(200);
    }
    // The same account counts once, and the owner not at all.
    await req("POST", `/v1/shares/${b}/adds`, undefined, await token("u3"));
    await req("POST", `/v1/shares/${b}/adds`, undefined, await token("u2"));
    expect((await list()).decks.map((d) => [d.code, d.adds])).toEqual([
      [b, 2],
      [a, 0],
    ]);
    expect((await list("&q=AIRPORT")).decks.map((d) => d.code)).toEqual([a]);
    expect((await list("&q=100%25")).decks).toHaveLength(0);
  });

  it("pages twenty at a time", async () => {
    for (let i = 0; i < 21; i++) await share("u1", `d${i}`, `Deck ${i}`);
    const first = await list();
    expect(first.decks).toHaveLength(20);
    expect(first.next).toBe(20);
    expect((await list("&offset=20")).decks).toHaveLength(1);
  });

  it("hides a deck from whoever reported it, and from everyone after three reports", async () => {
    const code = await share("u1", "d1", "Bad deck");
    const reportAs = async (uid: string) =>
      req("POST", `/v1/shares/${code}/reports`, { reason: "offensive" }, await token(uid));
    expect((await reportAs("u2")).status).toBe(200);
    expect((await list("", await token("u2"))).decks).toHaveLength(0);
    expect((await list()).decks).toHaveLength(1);
    await reportAs("u3");
    await reportAs("u3");
    expect((await list()).decks).toHaveLength(1);
    await reportAs("u4");
    expect((await list()).decks).toHaveLength(0);
    // A hidden deck still opens by its code for those who have it.
    expect((await req("GET", `/v1/shares/${code}`)).status).toBe(200);
  });

  it("refuses a report without a known reason", async () => {
    const code = await share("u1", "d1", "Deck");
    const res = await req("POST", `/v1/shares/${code}/reports`, { reason: "boring" }, await token("u2"));
    expect(res.status).toBe(400);
    expect((await req("POST", `/v1/shares/${code}/reports`, { reason: "spam" })).status).toBe(401);
  });

  it("blocking a deck's owner hides all their decks for the blocker, until unblocked", async () => {
    const code = await share("u1", "d1", "One");
    await share("u1", "d2", "Two");
    await share("u2", "d3", "Other");
    const me = await token("u3");
    expect((await req("POST", `/v1/shares/${code}/block`, undefined, me)).status).toBe(200);
    expect((await list("", me)).decks.map((d) => d.title)).toEqual(["Other"]);
    expect((await list()).decks).toHaveLength(3);
    const res = await req("DELETE", "/v1/blocks", undefined, me);
    expect(await res.json()).toEqual({ unblocked: 1 });
    expect((await list("", me)).decks).toHaveLength(3);
  });

  it("treats a bad token on the list as no viewer", async () => {
    await share("u1", "d1", "Travel");
    expect((await list("", "garbage")).decks).toHaveLength(1);
  });
});
