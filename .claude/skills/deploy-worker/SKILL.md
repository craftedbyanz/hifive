---
name: deploy-worker
description: Deploy the hifive sync Worker (worker/, Cloudflare Workers with D1) - test, apply new D1 migrations remotely first, deploy, smoke-check. Use when the user asks to deploy or ship the Worker, the API, the backend, the word catalog or a D1 migration.
---

# Deploy the sync Worker

The Worker is `hifive-api` on the user's personal Cloudflare account, served at `https://hifive-api.hifive-worker.workers.dev`, with D1 database `hifive` (APAC). The word catalog in `worker/catalog/` ships with it as static assets, so catalog edits deploy the same way.

## 1. Test

```sh
cd worker
[ -d node_modules ] || npm ci
npm run typecheck && npm test
```

Run `scripts/check.sh` from the repo root as well when the app side changed.

## 2. Migrations first

A migration is a new numbered file in `worker/migrations/`; never edit one already applied. See which are pending remotely:

```sh
npx wrangler d1 migrations list hifive --remote
```

If any are listed, apply them before deploying code that needs them:

```sh
npm run migrate:remote
```

## 3. Deploy

```sh
npx wrangler deploy
```

## 4. Smoke-check

```sh
curl -s -o /dev/null -w '%{http_code}\n' https://hifive-api.hifive-worker.workers.dev/v1/catalog/manifest.json   # 200
curl -s -o /dev/null -w '%{http_code}\n' -X POST https://hifive-api.hifive-worker.workers.dev/v1/sync              # 401 without a token
```

A 503 from `/v1/sync` with a token means Google's Firebase keys couldn't be fetched (`src/auth.ts`).

## 5. Report

Commit and push per the project rules, then report which migrations were applied, the deployed version ID that wrangler printed, and the smoke-check results.
