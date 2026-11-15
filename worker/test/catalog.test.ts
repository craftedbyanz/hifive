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

  it("names the newest dictionary pack and serves it gzipped, cached for good", async () => {
    const manifest = (await (await get("/v1/catalog/manifest")).json()) as {
      dictionaries: { "en-vi": { version: number; path: string; bytes: number; sha256: string } };
    };
    const pack = manifest.dictionaries["en-vi"];
    expect(pack.path).toBe(`dictionary/en-vi/${pack.version}.sqlite.gz`);
    expect(pack.sha256).toMatch(/^[0-9a-f]{64}$/);
    const res = await get(`/v1/catalog/${pack.path}`);
    expect(res.status).toBe(200);
    expect(res.headers.get("content-type")).toBe("application/gzip");
    expect(res.headers.get("cache-control")).toContain("immutable");
    const bytes = new Uint8Array(await res.arrayBuffer());
    expect(bytes.length).toBe(pack.bytes);
    expect([bytes[0], bytes[1]]).toEqual([0x1f, 0x8b]);
    const digest = new Uint8Array(await crypto.subtle.digest("SHA-256", bytes));
    expect([...digest].map((b) => b.toString(16).padStart(2, "0")).join("")).toBe(pack.sha256);
  });

  it("answers 404 for a missing dictionary pack or pair", async () => {
    expect((await get("/v1/catalog/dictionary/en-vi/999.sqlite.gz")).status).toBe(404);
    expect((await get("/v1/catalog/dictionary/en-xx/1.sqlite.gz")).status).toBe(404);
    expect((await get("/v1/catalog/dictionary/../manifest.json")).status).toBe(404);
  });

  it("answers 404 for a missing pack or a path outside the catalog", async () => {
    expect((await get("/v1/catalog/en/9.json")).status).toBe(404);
    expect((await get("/v1/catalog/../secret")).status).toBe(404);
    expect((await get("/v1/catalog/EN/1.json")).status).toBe(404);
    expect((await get("/manifest.json")).status).toBe(404);
  });
});
