import { applyD1Migrations, env } from "cloudflare:test";
import { beforeEach } from "vitest";

await applyD1Migrations(env.DB, env.TEST_MIGRATIONS);

// The plugin isolates storage per test file only, so each test starts empty.
beforeEach(async () => {
  await env.DB.batch([
    env.DB.prepare("DELETE FROM records"),
    env.DB.prepare("DELETE FROM devices"),
    env.DB.prepare("DELETE FROM users"),
  ]);
});
