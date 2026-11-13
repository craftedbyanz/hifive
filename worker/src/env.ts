export interface Env {
  DB: D1Database;
  /** The word catalog's files: `manifest.json` and `<lang>/<version>.json`. */
  CATALOG: Fetcher;
  /** The Firebase project whose ID tokens are accepted. */
  FIREBASE_PROJECT_ID: string;
}
