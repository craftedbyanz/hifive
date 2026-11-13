import type { JWTVerifyGetKey } from "jose";

import { AuthUnavailable, googleKeys, verifyIdToken, type Caller } from "./auth";
import { serveCatalog } from "./catalog";
import type { Env } from "./env";
import { parseSyncRequest, sync } from "./sync";

/** Larger bodies are refused before parsing: 500 records of 64 KiB, roughly. */
const maxBodyBytes = 33 * 1024 * 1024;

const json = (body: unknown, status = 200) =>
  Response.json(body, { status, headers: { "cache-control": "no-store" } });

/** Builds the API; tests pass their own signing keys. */
export function createHandler(keys: JWTVerifyGetKey, now: () => Date = () => new Date()) {
  return {
    async fetch(request: Request, env: Env): Promise<Response> {
      const url = new URL(request.url);
      if (request.method === "GET" && url.pathname.startsWith("/v1/catalog/")) {
        return (await serveCatalog(url, env.CATALOG)) ?? json({ error: "not_found" }, 404);
      }
      if (url.pathname !== "/v1/sync") return json({ error: "not_found" }, 404);
      if (request.method !== "POST") return json({ error: "method_not_allowed" }, 405);

      const header = request.headers.get("authorization") ?? "";
      const token = header.startsWith("Bearer ") ? header.slice(7) : "";
      let caller: Caller | null = null;
      try {
        caller = token ? await verifyIdToken(token, env.FIREBASE_PROJECT_ID, keys) : null;
      } catch (e) {
        if (e instanceof AuthUnavailable) {
          console.error("auth keys unavailable", e.message);
          return json({ error: "auth_unavailable" }, 503);
        }
        throw e;
      }
      if (!caller) return json({ error: "unauthorized" }, 401);

      const length = Number(request.headers.get("content-length") ?? 0);
      if (length > maxBodyBytes) return json({ error: "too_large" }, 413);
      let body: unknown;
      try {
        body = await request.json();
      } catch {
        return json({ error: "invalid_json" }, 400);
      }
      const parsed = parseSyncRequest(body);
      if (typeof parsed === "string") {
        return json({ error: "invalid_request", detail: parsed }, 400);
      }
      return json(await sync(env.DB, caller.uid, caller.email, parsed, now()));
    },
  };
}

export default createHandler(googleKeys) satisfies ExportedHandler<Env>;
