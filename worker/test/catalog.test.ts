import { env } from "cloudflare:test";
import { describe, expect, it } from "vitest";

import { handler } from "./helpers";

const get = (path: string) => handler.fetch(new Request(`https://api.test${path}`), env);

describe("catalog", () => {
  it("serves the manifest without signing in, cached for an hour", async () => {
    const res = await get("/v1/catalog/manifest");
    expect(res.status).toBe(200);
    expect(res.headers.get("cache-control")).toBe("public, max-age=3600");
    const manifest = (await res.json()) as { languages: { en: { version: number } } };
    expect(manifest.languages.en.version).toBe(2);
  });

  it("serves a pack by language and version, cached for good", async () => {
    const res = await get("/v1/catalog/en/2.json");
    expect(res.status).toBe(200);
    expect(res.headers.get("cache-control")).toContain("immutable");
    const pack = (await res.json()) as { decks: unknown[]; listening: unknown[] };
    expect(pack.decks).toHaveLength(3);
    expect(pack.listening).toHaveLength(1);
    // Published versions stay, so apps holding version 1 still load it.
    expect((await get("/v1/catalog/en/1.json")).status).toBe(200);
  });

  it("answers 404 for a missing pack or a path outside the catalog", async () => {
    expect((await get("/v1/catalog/en/9.json")).status).toBe(404);
    expect((await get("/v1/catalog/../secret")).status).toBe(404);
    expect((await get("/v1/catalog/EN/1.json")).status).toBe(404);
    expect((await get("/manifest.json")).status).toBe(404);
  });
});
