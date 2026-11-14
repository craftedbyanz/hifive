import type { JWTVerifyGetKey } from "jose";

import { AuthUnavailable, googleKeys, verifyIdToken, type Caller } from "./auth";
import { serveCatalog } from "./catalog";
import {
  assign,
  circleCodePattern,
  createCircle,
  detail,
  joinCircle,
  leave,
  mine,
  parseCircle,
  removeMember,
  unassign,
  updateCircle,
} from "./circles";
import type { Env } from "./env";
import {
  blockOwner,
  codePattern,
  countAdd,
  explore,
  parseShare,
  publish,
  read,
  report,
  reportReasons,
  shareLimits,
  sharePage,
  unblockAll,
  unpublish,
} from "./shares";
import { parseSyncRequest, sync } from "./sync";

/** Larger bodies are refused before parsing: 500 records of 64 KiB, roughly. */
const maxBodyBytes = 33 * 1024 * 1024;

const json = (body: unknown, status = 200) =>
  Response.json(body, { status, headers: { "cache-control": "no-store" } });

/** Builds the API; tests pass their own signing keys. */
export function createHandler(keys: JWTVerifyGetKey, now: () => Date = () => new Date()) {
  /** The signed-in caller, or the response to send instead. */
  async function signedIn(request: Request, env: Env): Promise<Caller | Response> {
    const header = request.headers.get("authorization") ?? "";
    const token = header.startsWith("Bearer ") ? header.slice(7) : "";
    try {
      const caller = token ? await verifyIdToken(token, env.FIREBASE_PROJECT_ID, keys) : null;
      return caller ?? json({ error: "unauthorized" }, 401);
    } catch (e) {
      if (e instanceof AuthUnavailable) {
        console.error("auth keys unavailable", e.message);
        return json({ error: "auth_unavailable" }, 503);
      }
      throw e;
    }
  }

  /** The request's JSON body, or the response to send instead. */
  async function body(request: Request, max: number): Promise<{ value: unknown } | Response> {
    const length = Number(request.headers.get("content-length") ?? 0);
    if (length > max) return json({ error: "too_large" }, 413);
    try {
      return { value: await request.json() };
    } catch {
      return json({ error: "invalid_json" }, 400);
    }
  }

  async function shares(request: Request, env: Env, rest: string): Promise<Response> {
    if (rest === "") {
      if (request.method !== "POST") return json({ error: "method_not_allowed" }, 405);
      const caller = await signedIn(request, env);
      if (caller instanceof Response) return caller;
      const b = await body(request, shareLimits.bodyBytes);
      if (b instanceof Response) return b;
      const parsed = parseShare(b.value);
      if (typeof parsed === "string") {
        return json({ error: "invalid_request", detail: parsed }, 400);
      }
      const code = await publish(env.DB, caller.uid, parsed, now());
      if (code === null) return json({ error: "too_many_shares" }, 429);
      return json({ code });
    }
    const [raw, action] = rest.split("/");
    const code = raw.toUpperCase();
    if (!codePattern.test(code)) return json({ error: "not_found" }, 404);
    if (action !== undefined) {
      if (request.method !== "POST") return json({ error: "method_not_allowed" }, 405);
      const caller = await signedIn(request, env);
      if (caller instanceof Response) return caller;
      if (action === "adds") {
        const adds = await countAdd(env.DB, caller.uid, code);
        return adds === null ? json({ error: "not_found" }, 404) : json({ adds });
      }
      if (action === "reports") {
        const b = await body(request, 4096);
        if (b instanceof Response) return b;
        const reason = (b.value as { reason?: unknown } | null)?.reason;
        if (typeof reason !== "string" || !(reportReasons as readonly string[]).includes(reason)) {
          return json({ error: "invalid_request", detail: "reason" }, 400);
        }
        return (await report(env.DB, caller.uid, code, reason, now()))
          ? json({ ok: true })
          : json({ error: "not_found" }, 404);
      }
      if (action === "block") {
        return (await blockOwner(env.DB, caller.uid, code, now()))
          ? json({ ok: true })
          : json({ error: "not_found" }, 404);
      }
      return json({ error: "not_found" }, 404);
    }
    if (request.method === "GET") {
      const deck = await read(env.DB, code);
      return deck ? json({ code, ...deck }) : json({ error: "not_found" }, 404);
    }
    if (request.method === "DELETE") {
      const caller = await signedIn(request, env);
      if (caller instanceof Response) return caller;
      return (await unpublish(env.DB, caller.uid, code))
        ? json({ ok: true })
        : json({ error: "not_found" }, 404);
    }
    return json({ error: "method_not_allowed" }, 405);
  }

  /** Study groups and classes; every call needs a signed-in account. */
  async function circles(request: Request, env: Env, url: URL): Promise<Response> {
    const caller = await signedIn(request, env);
    if (caller instanceof Response) return caller;
    const parts = url.pathname.split("/").slice(3); // after /v1/circles
    const m = request.method;
    const read = async () => {
      const b = await body(request, 8192);
      return b instanceof Response ? b : b.value;
    };
    if (parts.length === 0) {
      if (m === "GET") return json({ circles: await mine(env.DB, caller.uid) });
      if (m === "POST") {
        const v = await read();
        if (v instanceof Response) return v;
        const parsed = parseCircle(v);
        if (typeof parsed === "string") return json({ error: "invalid_request", detail: parsed }, 400);
        const made = await createCircle(env.DB, caller.uid, parsed, now());
        return made ? json({ circle: made }) : json({ error: "too_many" }, 429);
      }
      return json({ error: "method_not_allowed" }, 405);
    }
    if (parts[0] === "join" && parts.length === 1 && m === "POST") {
      const v = await read();
      if (v instanceof Response) return v;
      const code = String((v as { code?: unknown } | null)?.code ?? "").toUpperCase();
      if (!circleCodePattern.test(code)) return json({ error: "not_found" }, 404);
      const joined = await joinCircle(env.DB, caller.uid, code, now());
      if (joined === "not_found") return json({ error: "not_found" }, 404);
      if (joined === "full" || joined === "too_many") return json({ error: joined }, 429);
      return json({ circle: joined });
    }
    const id = parts[0];
    if (parts.length === 1) {
      if (m === "GET") {
        const d = await detail(env.DB, caller.uid, id, url.searchParams.get("from") ?? "");
        return d ? json(d) : json({ error: "not_found" }, 404);
      }
      if (m === "PUT") {
        const v = await read();
        if (v instanceof Response) return v;
        const parsed = parseCircle(v);
        if (typeof parsed === "string") return json({ error: "invalid_request", detail: parsed }, 400);
        return (await updateCircle(env.DB, caller.uid, id, parsed))
          ? json({ ok: true })
          : json({ error: "not_found" }, 404);
      }
      return json({ error: "method_not_allowed" }, 405);
    }
    if (parts[1] === "members" && parts.length === 3 && m === "DELETE") {
      const done =
        parts[2] === "me"
          ? await leave(env.DB, caller.uid, id)
          : await removeMember(env.DB, caller.uid, id, parts[2]);
      return done ? json({ ok: true }) : json({ error: "not_found" }, 404);
    }
    if (parts[1] === "assignments") {
      if (parts.length === 2 && m === "POST") {
        const v = await read();
        if (v instanceof Response) return v;
        const b = (v ?? {}) as { shareCode?: unknown; due?: unknown };
        const result = await assign(
          env.DB,
          caller.uid,
          id,
          String(b.shareCode ?? "").toUpperCase(),
          String(b.due ?? ""),
          now(),
        );
        if (result === "forbidden" || result === "not_found") return json({ error: "not_found" }, 404);
        if (result === "bad_due") return json({ error: "invalid_request", detail: "due" }, 400);
        if (result === "too_many") return json({ error: "too_many" }, 429);
        return json({ id: result });
      }
      if (parts.length === 3 && m === "DELETE") {
        return (await unassign(env.DB, caller.uid, id, parts[2]))
          ? json({ ok: true })
          : json({ error: "not_found" }, 404);
      }
    }
    return json({ error: "not_found" }, 404);
  }

  return {
    async fetch(request: Request, env: Env): Promise<Response> {
      const url = new URL(request.url);
      if (url.pathname === "/v1/circles" || url.pathname.startsWith("/v1/circles/")) {
        return circles(request, env, url);
      }
      if (request.method === "GET" && url.pathname.startsWith("/v1/catalog/")) {
        return (await serveCatalog(url, env.CATALOG)) ?? json({ error: "not_found" }, 404);
      }
      if (url.pathname === "/v1/shares" || url.pathname.startsWith("/v1/shares/")) {
        return shares(request, env, url.pathname.slice("/v1/shares/".length));
      }
      if (url.pathname === "/v1/explore" && request.method === "GET") {
        // Anyone may look; a signed-in viewer's blocks and reports apply.
        const caller = request.headers.has("authorization") ? await signedIn(request, env) : null;
        const p = url.searchParams;
        const offset = Math.max(0, Math.min(10_000, Number(p.get("offset") ?? 0) || 0));
        return json(
          await explore(env.DB, {
            language: (p.get("lang") ?? "en").slice(0, 8),
            sort: p.get("sort") === "new" ? "new" : "popular",
            query: (p.get("q") ?? "").trim().slice(0, 60),
            offset,
            viewer: caller && !(caller instanceof Response) ? caller.uid : null,
          }),
        );
      }
      if (url.pathname === "/v1/blocks" && request.method === "DELETE") {
        const caller = await signedIn(request, env);
        if (caller instanceof Response) return caller;
        return json({ unblocked: await unblockAll(env.DB, caller.uid) });
      }
      if (request.method === "GET" && url.pathname.startsWith("/s/")) {
        const code = url.pathname.slice(3).toUpperCase();
        const deck = codePattern.test(code) ? await read(env.DB, code) : null;
        return new Response(sharePage(code, deck), {
          status: deck ? 200 : 404,
          headers: {
            "content-type": "text/html; charset=utf-8",
            "cache-control": "public, max-age=60",
          },
        });
      }
      if (url.pathname !== "/v1/sync") return json({ error: "not_found" }, 404);
      if (request.method !== "POST") return json({ error: "method_not_allowed" }, 405);

      const caller = await signedIn(request, env);
      if (caller instanceof Response) return caller;
      const b = await body(request, maxBodyBytes);
      if (b instanceof Response) return b;
      const parsed = parseSyncRequest(b.value);
      if (typeof parsed === "string") {
        return json({ error: "invalid_request", detail: parsed }, 400);
      }
      return json(await sync(env.DB, caller.uid, caller.email, parsed, now()));
    },
  };
}

export default createHandler(googleKeys) satisfies ExportedHandler<Env>;
