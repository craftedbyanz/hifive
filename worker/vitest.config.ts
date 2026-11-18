import { cloudflareTest, readD1Migrations } from "@cloudflare/vitest-plugin";
import { defineConfig } from "vitest/config";

export default defineConfig(async () => {
  const migrations = await readD1Migrations("migrations");
  return {
    plugins: [
      cloudflareTest({
        wrangler: { configPath: "./wrangler.jsonc" },
        // Tests pass their own word model, so the AI binding never reaches
        // Cloudflare (it would need a login and spend Neurons).
        remoteBindings: false,
        miniflare: { bindings: { TEST_MIGRATIONS: migrations } },
      }),
    ],
    test: { setupFiles: ["./test/setup.ts"] },
  };
});
