/**
 * The word catalog, shipped with the Worker as static assets and served to
 * anyone: learners need words before
 * they sign in, and nothing in it is personal.
 *
 * - `GET /v1/catalog/manifest` gives `{ languages: { en: { version, path } } }`.
 *   Apps check it about once a day; it may be cached for an hour.
 * - `GET /v1/catalog/<lang>/<version>.json` gives that pack. A version never
 *   changes once published, so it is cached for a year.
 * - `GET /v1/catalog/dictionary/<pair>/<version>.sqlite.gz` gives a
 *   dictionary pack (docs/dictionary-plan.md), a gzipped SQLite file built
 *   by `tool/dictionary/build.py`. The manifest's `dictionaries` names the
 *   newest one with its size and SHA-256. Also immutable.
 */
const packPath = /^\/v1\/catalog\/([a-z]{2,3})\/(\d{1,6})\.json$/;
const dictionaryPath = /^\/v1\/catalog\/dictionary\/([a-z]{2,3}-[a-z]{2,3})\/(\d{1,6})\.sqlite\.gz$/;
const forever = "public, max-age=31536000, immutable";

export async function serveCatalog(url: URL, files: Fetcher): Promise<Response | null> {
  if (url.pathname === "/v1/catalog/manifest") {
    return file(files, url, "manifest.json", "public, max-age=3600");
  }
  const match = packPath.exec(url.pathname);
  if (match) {
    return file(files, url, `${match[1]}/${match[2]}.json`, forever);
  }
  const dictionary = dictionaryPath.exec(url.pathname);
  if (dictionary) {
    return file(files, url, `dictionary/${dictionary[1]}/${dictionary[2]}.sqlite.gz`, forever, "application/gzip");
  }
  return null;
}

async function file(
  files: Fetcher,
  url: URL,
  path: string,
  cache: string,
  type = "application/json; charset=utf-8",
): Promise<Response> {
  const found = await files.fetch(new Request(new URL(`/${path}`, url.origin)));
  if (!found.ok) {
    return Response.json({ error: "not_found" }, { status: 404, headers: { "cache-control": "no-store" } });
  }
  return new Response(found.body, { headers: { "content-type": type, "cache-control": cache } });
}
