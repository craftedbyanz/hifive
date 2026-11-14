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
    expect(manifest.languages.en.version).toBe(3);
  });

  it("serves a pack by language and version, cached for good", async () => {
    const res = await get("/v1/catalog/en/3.json");
    expect(res.status).toBe(200);
    expect(res.headers.get("cache-control")).toContain("immutable");
    const pack = (await res.json()) as {
      decks: unknown[];
      listening: { episodes: { id: string; seconds: number }[] }[];
    };
    expect(pack.decks).toHaveLength(3);
    expect(pack.listening[0].episodes).toHaveLength(100);
    expect(pack.listening[0].episodes[0]).toMatchObject({ id: "F5QyH36MnVo", seconds: 1216 });
    // Published versions stay, so apps holding an older one still load it.
    expect((await get("/v1/catalog/en/1.json")).status).toBe(200);
    expect((await get("/v1/catalog/en/2.json")).status).toBe(200);
  });

  it("answers 404 for a missing pack or a path outside the catalog", async () => {
    expect((await get("/v1/catalog/en/9.json")).status).toBe(404);
    expect((await get("/v1/catalog/../secret")).status).toBe(404);
    expect((await get("/v1/catalog/EN/1.json")).status).toBe(404);
    expect((await get("/manifest.json")).status).toBe(404);
  });
});
