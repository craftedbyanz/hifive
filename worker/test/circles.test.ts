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

/** Pushes [uid]'s name and a few reviews, as the app's sync would. */
async function learn(uid: string, name: string, reviews: [string, string][]) {
  await syncAs(uid, "d", 0, [
    rec("setting", "name", { v: name }, hlc(1)),
    ...reviews.map(([at, word], i) =>
      rec("review", `${uid}-r${i}`, { wordId: `w${i}`, at, rating: 2, word }, hlc(2 + i)),
    ),
  ]);
}

const week = "2026-11-09";

describe("study groups", () => {
  it("are made, joined by code, and show who studied which day", async () => {
    const made = await req("POST", "/v1/circles", "u1", { name: "Nhóm IELTS", goal: 4 });
    expect(made.status).toBe(200);
    const { id, code } = made.body.circle;
    expect(code).toMatch(/^[A-HJ-NP-Z2-9]{6}$/);

    const joined = await req("POST", "/v1/circles/join", "u2", { code: code.toLowerCase() });
    expect(joined.body.circle).toMatchObject({ id, name: "Nhóm IELTS", owner: false, members: 2 });

    await learn("u1", "Lan", [
      ["2026-11-09T08:00:00.000", "apple"],
      ["2026-11-11T21:00:00.000", "pear"],
      ["2026-11-02T08:00:00.000", "old"],
    ]);
    await learn("u2", "Minh", [["2026-11-10T07:00:00.000", "cat"]]);
    // A minute of listening is a study day too.
    await syncAs("u2", "d", 0, [
      rec("listen", "vid@2026-11-12", { pos: 70, heard: 70, done: false, at: "x" }, hlc(9)),
      rec("listen", "vid@2026-11-13", { pos: 10, heard: 10, done: false, at: "x" }, hlc(10)),
    ]);

    const seen = await req("GET", `/v1/circles/${id}?from=${week}`, "u2");
    expect(seen.status).toBe(200);
    expect(seen.body.week[0]).toBe("2026-11-09");
    expect(seen.body.week[6]).toBe("2026-11-15");
    const people = Object.fromEntries(
      seen.body.people.map((p: { name: string; days: string[]; me: boolean }) => [p.name, p]),
    );
    expect(people.Lan.days).toEqual(["2026-11-09", "2026-11-11"]);
    expect(people.Minh.days).toEqual(["2026-11-10", "2026-11-12"]);
    expect(people.Minh.me).toBe(true);
    expect(JSON.stringify(seen.body)).not.toContain("u1");

    const list = await req("GET", "/v1/circles", "u2");
    expect(list.body.circles.map((c: { name: string }) => c.name)).toEqual(["Nhóm IELTS"]);
  });

  it("only members see a circle, and a bad code finds nothing", async () => {
    const { id } = (await req("POST", "/v1/circles", "u1", { name: "G" })).body.circle;
    expect((await req("GET", `/v1/circles/${id}?from=${week}`, "u3")).status).toBe(404);
    expect((await req("POST", "/v1/circles/join", "u3", { code: "ABCDEF" })).status).toBe(404);
    expect((await req("GET", "/v1/circles", null)).status).toBe(401);
  });

  it("checks the name and goal", async () => {
    expect((await req("POST", "/v1/circles", "u1", { name: " " })).body.detail).toBe("name");
    expect((await req("POST", "/v1/circles", "u1", { name: "G", goal: 8 })).body.detail).toBe("goal");
  });

  it("the owner can rename and remove members; leaving hands the group on", async () => {
    const { id, code } = (await req("POST", "/v1/circles", "u1", { name: "G" })).body.circle;
    await req("POST", "/v1/circles/join", "u2", { code });
    await req("POST", "/v1/circles/join", "u3", { code });
    expect((await req("PUT", `/v1/circles/${id}`, "u2", { name: "X", goal: 2 })).status).toBe(404);
    expect((await req("PUT", `/v1/circles/${id}`, "u1", { name: "Nhóm sáng", goal: 5 })).status).toBe(200);

    const people = (await req("GET", `/v1/circles/${id}?from=${week}`, "u1")).body.people;
    const third = people[2].id;
    expect((await req("DELETE", `/v1/circles/${id}/members/${third}`, "u2")).status).toBe(404);
    expect((await req("DELETE", `/v1/circles/${id}/members/${third}`, "u1")).status).toBe(200);
    expect((await req("GET", `/v1/circles/${id}?from=${week}`, "u3")).status).toBe(404);

    expect((await req("DELETE", `/v1/circles/${id}/members/me`, "u1")).status).toBe(200);
    const now = await req("GET", `/v1/circles/${id}?from=${week}`, "u2");
    expect(now.body).toMatchObject({ name: "Nhóm sáng", goal: 5, owner: true, members: 1 });
    await req("DELETE", `/v1/circles/${id}/members/me`, "u2");
    const { n } = (await env.DB.prepare("SELECT COUNT(*) AS n FROM circles").first<{ n: number }>())!;
    expect(n).toBe(0);
  });
});

describe("classes", () => {
  async function sharedDeck(uid: string) {
    const res = await req("POST", "/v1/shares", uid, {
      deckId: "d1",
      title: "Unit 1",
      language: "en",
      words: [
        { word: "Apple", meaning: "táo" },
        { word: "pear", meaning: "lê" },
        { word: "plum", meaning: "mận" },
      ],
    });
    return res.body.code as string;
  }

  it("the teacher sets a deck and sees each student's progress; students see their own", async () => {
    const { id, code } = (await req("POST", "/v1/circles", "t", { kind: "class", name: "Lớp 6A" })).body.circle;
    await req("POST", "/v1/circles/join", "s1", { code });
    await req("POST", "/v1/circles/join", "s2", { code });
    const deck = await sharedDeck("t");
    expect((await req("POST", `/v1/circles/${id}/assignments`, "s1", { shareCode: deck, due: "2026-11-20" })).status).toBe(404);
    const set = await req("POST", `/v1/circles/${id}/assignments`, "t", { shareCode: deck, due: "2026-11-20" });
    expect(set.status).toBe(200);

    await learn("s1", "An", [
      ["2026-11-10T08:00:00.000", "apple"],
      ["2026-11-10T08:01:00.000", "pear"],
    ]);
    await learn("s2", "Bình", [["2026-11-11T08:00:00.000", "kiwi"]]);

    const teacher = (await req("GET", `/v1/circles/${id}?from=${week}`, "t")).body;
    expect(teacher.people).toHaveLength(3);
    const ids = Object.fromEntries(teacher.people.map((p: { name: string; id: string }) => [p.name, p.id]));
    const a = teacher.assignments[0];
    expect(a).toMatchObject({ title: "Unit 1", total: 3, due: "2026-11-20", shareCode: deck });
    expect(a.progress).toEqual({ [ids.An]: 2, [ids.Bình]: 0 });

    const student = (await req("GET", `/v1/circles/${id}?from=${week}`, "s2")).body;
    // A student sees the teacher and themselves, and only their own progress.
    expect(student.people.map((p: { me: boolean; owner: boolean }) => [p.me, p.owner])).toEqual([
      [false, true],
      [true, false],
    ]);
    expect(Object.values(student.assignments[0].progress)).toEqual([0]);

    expect((await req("DELETE", `/v1/circles/${id}/assignments/${set.body.id}`, "t")).status).toBe(200);
    expect((await req("GET", `/v1/circles/${id}?from=${week}`, "t")).body.assignments).toHaveLength(0);
  });

  it("refuses a deck code that was never shared, and a bad date", async () => {
    const { id } = (await req("POST", "/v1/circles", "t", { kind: "class", name: "L" })).body.circle;
    expect((await req("POST", `/v1/circles/${id}/assignments`, "t", { shareCode: "ABCDEF", due: "2026-11-20" })).status).toBe(404);
    const deck = await sharedDeck("t");
    expect((await req("POST", `/v1/circles/${id}/assignments`, "t", { shareCode: deck, due: "soon" })).status).toBe(400);
  });
});
