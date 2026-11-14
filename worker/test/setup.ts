import { applyD1Migrations, env } from "cloudflare:test";
import { beforeEach } from "vitest";

await applyD1Migrations(env.DB, env.TEST_MIGRATIONS);

// The plugin isolates storage per test file only, so each test starts empty.
beforeEach(async () => {
  await env.DB.batch([
    env.DB.prepare("DELETE FROM records"),
    env.DB.prepare("DELETE FROM devices"),
    env.DB.prepare("DELETE FROM users"),
    env.DB.prepare("DELETE FROM shares"),
    env.DB.prepare("DELETE FROM share_adds"),
    env.DB.prepare("DELETE FROM share_reports"),
    env.DB.prepare("DELETE FROM blocks"),
    env.DB.prepare("DELETE FROM circles"),
    env.DB.prepare("DELETE FROM circle_members"),
    env.DB.prepare("DELETE FROM assignments"),
  ]);
});
