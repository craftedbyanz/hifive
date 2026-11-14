import { env } from "cloudflare:test";
import { describe, expect, it } from "vitest";

import { handler, token } from "./helpers";

const deck = {
  deckId: "d1",
  title: "Travel words",
  description: "For my trip",
  icon: 2,
  language: "en",
  words: [
    { word: "ticket", meaning: "vé", phonetic: "/ˈtɪk.ɪt/", example: "", partOfSpeech: "NOUN", definition: "" },
    { word: "<b>gate</b>", meaning: "cổng" },
  ],
};

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

async function share(uid: string, body: unknown = deck) {
  const res = await req("POST", "/v1/shares", body, await token(uid));
  return { status: res.status, body: (await res.json()) as { code?: string; error?: string } };
}

describe("shares", () => {
  it("publishes a deck under a code anyone can read, signed in or not", async () => {
    const { status, body } = await share("u1");
    expect(status).toBe(200);
    expect(body.code).toMatch(/^[A-HJ-NP-Z2-9]{6}$/);

    const res = await req("GET", `/v1/shares/${body.code!.toLowerCase()}`);
    expect(res.status).toBe(200);
    const got = (await res.json()) as { code: string; title: string; words: { word: string; phonetic: string }[] };
    expect(got.code).toBe(body.code);
    expect(got.title).toBe("Travel words");
    expect(got.words.map((w) => w.word)).toEqual(["ticket", "<b>gate</b>"]);
    expect(got.words[1].phonetic).toBe("");
  });

  it("keeps the code when the same deck is shared again, with the new words", async () => {
    const first = await share("u1");
    const again = await share("u1", { ...deck, title: "Trip", words: [deck.words[0]] });
    expect(again.body.code).toBe(first.body.code);
    const got = (await (await req("GET", `/v1/shares/${first.body.code}`)).json()) as {
      title: string;
      words: unknown[];
    };
    expect(got.title).toBe("Trip");
    expect(got.words).toHaveLength(1);
    // Another account sharing a deck with the same id gets its own code.
    expect((await share("u2")).body.code).not.toBe(first.body.code);
  });

  it("needs a signed-in account to share or stop sharing", async () => {
    expect((await req("POST", "/v1/shares", deck)).status).toBe(401);
    const { body } = await share("u1");
    expect((await req("DELETE", `/v1/shares/${body.code}`)).status).toBe(401);
  });

  it("lets only the owner stop sharing", async () => {
    const { body } = await share("u1");
    const other = await req("DELETE", `/v1/shares/${body.code}`, undefined, await token("u2"));
    expect(other.status).toBe(404);
    const own = await req("DELETE", `/v1/shares/${body.code}`, undefined, await token("u1"));
    expect(own.status).toBe(200);
    expect((await req("GET", `/v1/shares/${body.code}`)).status).toBe(404);
  });

  it.each([
    ["no title", { ...deck, title: " " }, "title"],
    ["no words", { ...deck, words: [] }, "words"],
    ["a word without meaning", { ...deck, words: [{ word: "a" }] }, "words[0]"],
    ["a long title", { ...deck, title: "x".repeat(81) }, "title"],
    ["a bad icon", { ...deck, icon: -1 }, "icon"],
  ])("refuses a deck with %s", async (_, body, detail) => {
    const res = await share("u1", body);
    expect(res.status).toBe(400);
    expect(res.body).toMatchObject({ error: "invalid_request", detail });
  });

  it("answers 404 for a code that was never shared or is malformed", async () => {
    expect((await req("GET", "/v1/shares/ABCDEF")).status).toBe(404);
    expect((await req("GET", "/v1/shares/AB0")).status).toBe(404);
  });

  it("shows a page for the link with the deck and its code, escaped", async () => {
    const { body } = await share("u1");
    const res = await req("GET", `/s/${body.code}`);
    expect(res.status).toBe(200);
    expect(res.headers.get("content-type")).toContain("text/html");
    const html = await res.text();
    expect(html).toContain("Travel words");
    expect(html).toContain(body.code);
    expect(html).toContain("&#60;b&#62;gate&#60;/b&#62;");
    expect(html).not.toContain("<b>gate</b>");
    const missing = await req("GET", "/s/ABCDEF");
    expect(missing.status).toBe(404);
    expect(await missing.text()).toContain("Không tìm thấy bộ thẻ");
  });
});
