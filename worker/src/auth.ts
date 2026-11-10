import { createRemoteJWKSet, errors, jwtVerify, type JWTVerifyGetKey } from "jose";

/** Google's public keys for Firebase ID tokens; jose caches them. */
export const googleKeys: JWTVerifyGetKey = createRemoteJWKSet(
  new URL(
    "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
  ),
);

/** Google's keys couldn't be fetched; the token was never judged. */
export class AuthUnavailable extends Error {}

export interface Caller {
  uid: string;
  email: string | null;
}

/**
 * Checks a Firebase ID token as Firebase documents it: RS256 signed by
 * Google, issued for [projectId], not expired. Returns null when it isn't
 * valid, so callers answer 401 without leaking why. Throws [AuthUnavailable]
 * when the keys can't be fetched, so callers answer 503 and the app retries
 * instead of treating a good token as bad.
 */
export async function verifyIdToken(
  token: string,
  projectId: string,
  keys: JWTVerifyGetKey,
): Promise<Caller | null> {
  try {
    const { payload } = await jwtVerify(token, keys, {
      algorithms: ["RS256"],
      audience: projectId,
      issuer: `https://securetoken.google.com/${projectId}`,
      requiredClaims: ["sub", "iat", "exp"],
    });
    const uid = payload.sub;
    if (!uid || uid.length > 128) return null;
    const email = typeof payload.email === "string" ? payload.email : null;
    return { uid, email };
  } catch (e) {
    if (e instanceof errors.JWKSTimeout) throw new AuthUnavailable(e.message);
    if (e instanceof errors.JOSEError) return null;
    throw new AuthUnavailable(e instanceof Error ? e.message : String(e));
  }
}
