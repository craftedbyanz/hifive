import { env } from "cloudflare:test";
import { beforeEach, describe, expect, it } from "vitest";

import { generateLimits, parseWords } from "../src/generate";
import { createHandler } from "../src/index";
import { keys, token } from "./helpers";

let reply: string | Error = "";
let asked: { content: string }[][] = [];
let clock = new Date("2026-11-18T09:00:00Z");
const api = createHandler(
  keys,
  () => clock,
  () => async (messages) => {
    asked.push(messages);
    if (reply instanceof Error) throw reply;
    return reply;
  },
);

beforeEach(() => {
  reply = "airport\npassport\n3. boarding pass\n- suitcase\nTicket.";
  asked = [];
  clock = new Date("2026-11-18T09:00:00Z");
});

async function generate(uid: string | null, body: unknown, method = "POST") {
  const res = await api.fetch(
    new Request("https://api.test/v1/decks/generate", {
      method,
      headers: {
        "content-type": "application/json",
        ...(uid ? { authorization: `Bearer ${await token(uid)}` } : {}),
      },
      body: method === "POST" ? JSON.stringify(body) : undefined,
    }),
    env,
  );
  return { status: res.status, body: (await res.json()) as any };
}

const travel = { language: "en", topic: "Du lịch", level: "A2", count: 10 };

describe("decks made with AI", () => {
  it("needs a signed-in caller, POST and a valid request", async () => {
    expect((await generate(null, travel)).status).toBe(401);
    expect((await generate("u1", travel, "GET")).status).toBe(405);
    for (const bad of [
      { ...travel, topic: " " },
      { ...travel, topic: "x".repeat(61) },
      { ...travel, level: "D1" },
      { ...travel, count: 4 },
      { ...travel, count: 51 },
      { ...travel, language: "ko" },
      { ...travel, exclude: [1] },
    ]) {
      expect((await generate("u1", bad)).status).toBe(400);
    }
    expect(asked).toHaveLength(0);
  });

  it("returns the model's words, cleaned, without the excluded ones", async () => {
    const res = await generate("u1", { ...travel, exclude: ["Passport"] });
    expect(res.status).toBe(200);
    expect(res.body.words).toEqual(["airport", "boarding pass", "suitcase", "ticket"]);
    expect(res.body.left).toBe(generateLimits.perDay - 1);
    // The learner's topic and level reach the model as the topic.
    expect(asked[0][1].content).toContain("Topic: Du lịch");
    expect(asked[0][1].content).toContain("CEFR A2");
  });

  it("allows five decks a day per account, counted by UTC day", async () => {
    for (let i = 0; i < generateLimits.perDay; i++) {
      expect((await generate("u1", travel)).status).toBe(200);
    }
    const over = await generate("u1", travel);
    expect(over.status).toBe(429);
    expect(over.body.error).toBe("daily_limit");
    expect(asked).toHaveLength(generateLimits.perDay);
    // Another learner has their own five.
    expect((await generate("u2", travel)).status).toBe(200);
    // The next day starts again.
    clock = new Date("2026-11-19T00:00:01Z");
    expect((await generate("u1", travel)).status).toBe(200);
  });

  it("doesn't count a failed or empty answer", async () => {
    reply = new Error("4006: daily free allocation used");
    expect((await generate("u1", travel)).status).toBe(503);
    reply = "Sorry, I can't help with that.";
    const empty = await generate("u1", travel);
    expect(empty.status).toBe(502);
    reply = "airport";
    expect((await generate("u1", travel)).body.left).toBe(generateLimits.perDay - 1);
  });

  it("deleting the account deletes its count", async () => {
    await generate("u1", travel);
    const res = await api.fetch(
      new Request("https://api.test/v1/account", {
        method: "DELETE",
        headers: { authorization: `Bearer ${await token("u1")}` },
      }),
      env,
    );
    expect(res.status).toBe(200);
    const row = await env.DB.prepare("SELECT COUNT(*) AS n FROM ai_usage").first<{ n: number }>();
    expect(row!.n).toBe(0);
  });
});

describe("parseWords", () => {
  it("keeps plain words and short phrases, at most max", () => {
    expect(
      parseWords(
        "Here are some words:\n1. Hotel\n2) check-in - nhận phòng\n* \"map\"\nrent a car (verb)\n日本\nhotel\na b c d",
        [],
        10,
      ),
    ).toEqual(["hotel", "check-in", "map", "rent a car"]);
    expect(parseWords("a\nb\nc", [], 2)).toEqual(["a", "b"]);
    expect(parseWords("hotel, taxi; map", [], 10)).toEqual(["hotel", "taxi", "map"]);
    expect(parseWords("Sorry, I can't help with that.", [], 10)).toEqual([]);
  });
});
