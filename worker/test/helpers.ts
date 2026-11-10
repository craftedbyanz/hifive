import { env } from "cloudflare:test";
import { createLocalJWKSet, exportJWK, generateKeyPair, SignJWT, type JWK } from "jose";

import { createHandler } from "../src/index";
import type { WireRecord } from "../src/sync";

const project = "hifive-3371b";
const { publicKey, privateKey } = await generateKeyPair("RS256");
const jwk: JWK = { ...(await exportJWK(publicKey)), kid: "test", alg: "RS256" };
const other = await generateKeyPair("RS256");

export const handler = createHandler(createLocalJWKSet({ keys: [jwk] }));

/** A Firebase-shaped ID token; [overrides] break one part of it. */
export async function token(
  uid: string,
  overrides: { audience?: string; expiresIn?: string; foreignKey?: boolean; email?: string } = {},
): Promise<string> {
  return new SignJWT({ email: overrides.email })
    .setProtectedHeader({ alg: "RS256", kid: "test" })
    .setSubject(uid)
    .setIssuer(`https://securetoken.google.com/${project}`)
    .setAudience(overrides.audience ?? project)
    .setIssuedAt()
    .setExpirationTime(overrides.expiresIn ?? "1h")
    .sign(overrides.foreignKey ? other.privateKey : privateKey);
}

export async function call(body: unknown, auth?: string, method = "POST"): Promise<Response> {
  return handler.fetch(
    new Request("https://api.test/v1/sync", {
      method,
      headers: {
        "content-type": "application/json",
        ...(auth ? { authorization: `Bearer ${auth}` } : {}),
      },
      body: method === "POST" ? JSON.stringify(body) : undefined,
    }),
    env,
  );
}

/** Syncs as [uid] from [deviceId] and returns the parsed response. */
export async function syncAs(
  uid: string,
  deviceId: string,
  cursor: number,
  records: WireRecord[] = [],
) {
  const res = await call({ deviceId, cursor, records }, await token(uid));
  if (res.status !== 200) throw new Error(`sync failed: ${res.status} ${await res.text()}`);
  return (await res.json()) as { cursor: number; hasMore: boolean; records: WireRecord[] };
}

/** An HLC stamp like the app's: zero-padded millis, base-36 counter, device. */
export function hlc(millis: number, device = "dev-a", counter = 0): string {
  return `${String(millis).padStart(15, "0")}:${counter.toString(36).padStart(4, "0")}:${device}`;
}

export function rec(kind: string, id: string, data: WireRecord["data"], stamp: string): WireRecord {
  return { kind, id, data, hlc: stamp };
}
