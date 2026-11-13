/**
 * The word catalog, shipped with the Worker as static assets and served to
 * anyone: learners need words before
 * they sign in, and nothing in it is personal.
 *
 * - `GET /v1/catalog/manifest` gives `{ languages: { en: { version, path } } }`.
 *   Apps check it about once a day; it may be cached for an hour.
 * - `GET /v1/catalog/<lang>/<version>.json` gives that pack. A version never
 *   changes once published, so it is cached for a year.
 */
const packPath = /^\/v1\/catalog\/([a-z]{2,3})\/(\d{1,6})\.json$/;

export async function serveCatalog(url: URL, files: Fetcher): Promise<Response | null> {
  if (url.pathname === "/v1/catalog/manifest") {
    return file(files, url, "manifest.json", "public, max-age=3600");
  }
  const match = packPath.exec(url.pathname);
  if (match) {
    return file(files, url, `${match[1]}/${match[2]}.json`, "public, max-age=31536000, immutable");
  }
  return null;
}

async function file(files: Fetcher, url: URL, path: string, cache: string): Promise<Response> {
  const found = await files.fetch(new Request(new URL(`/${path}`, url.origin)));
  if (!found.ok) {
    return Response.json({ error: "not_found" }, { status: 404, headers: { "cache-control": "no-store" } });
  }
  return new Response(found.body, {
    headers: { "content-type": "application/json; charset=utf-8", "cache-control": cache },
  });
}
