# worker/

The sync API on Cloudflare Workers (TypeScript, D1 `hifive` in APAC, personal Cloudflare account), deployed to `https://hifive-api.hifive-worker.workers.dev`. Deploy with the `deploy-worker` skill.

- A new table or column is a new numbered migration in `migrations/`, never an edit to an applied one. Apply it remotely (`npm run migrate:remote`) before deploying code that needs it.
- Tests use `@cloudflare/vitest-plugin`, which isolates storage per file only, so `test/setup.ts` empties the tables before each test.
- `POST /v1/decks/generate` asks Workers AI (binding `AI`, `src/generate.ts`) for a deck's words, 5 decks per account per UTC day (`ai_usage`). Tests pass their own model to `createHandler` and run with `remoteBindings: false`, so they never reach Cloudflare or spend Neurons.
- `/v1/sync` answers 401 for a bad Firebase ID token and 503 when Google's keys can't be fetched.
