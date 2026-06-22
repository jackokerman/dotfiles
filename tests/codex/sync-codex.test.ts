import { describe, expect, test } from "bun:test";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";

const repoRoot = resolve(import.meta.dir, "../..");
const syncScript = join(repoRoot, "scripts", "ts", "sync-codex.ts");
const hooksSource = join(repoRoot, "home", ".codex", "hooks.json");

function withTempDir(run: (dir: string) => void) {
  const dir = mkdtempSync(join(tmpdir(), "codex-sync-"));

  try {
    run(dir);
  } finally {
    rmSync(dir, { force: true, recursive: true });
  }
}

function runSync(args: string[]) {
  return Bun.spawnSync(["bun", "run", syncScript, ...args], {
    cwd: repoRoot,
    stderr: "pipe",
    stdout: "pipe",
  });
}

describe("sync-codex config", () => {
  test("strips deprecated codex_hooks from existing live config", () => {
    withTempDir((dir) => {
      const outputPath = join(dir, "config.toml");
      const sourcePath = join(dir, "source.toml");

      writeFileSync(
        outputPath,
        [
          "[features]",
          "codex_hooks = true",
          "fast_mode = true",
          "",
          "[notice]",
          "custom = true",
          "",
        ].join("\n"),
      );
      writeFileSync(
        sourcePath,
        [
          "model = \"gpt-5.4\"",
          "",
          "[features]",
          "hooks = true",
          "",
        ].join("\n"),
      );

      const result = runSync(["config", "--output", outputPath, "--source", sourcePath]);
      expect(result.exitCode).toBe(0);

      const generated = readFileSync(outputPath, "utf8");
      expect(generated).toContain("hooks = true");
      expect(generated).toContain("fast_mode = true");
      expect(generated).toContain("custom = true");
      expect(generated).not.toContain("codex_hooks");
    });
  });

  test("rejects tracked sources that still use codex_hooks", () => {
    withTempDir((dir) => {
      const outputPath = join(dir, "config.toml");
      const sourcePath = join(dir, "source.toml");

      writeFileSync(sourcePath, ["[features]", "codex_hooks = true", ""].join("\n"));

      const result = runSync(["config", "--output", outputPath, "--source", sourcePath]);
      expect(result.exitCode).not.toBe(0);
      expect(new TextDecoder().decode(result.stderr)).toContain(
        "use [features].hooks instead of [features].codex_hooks",
      );
    });
  });
});

describe("tracked Codex hooks", () => {
  test("wire tmux status lifecycle events through the Codex adapter wrapper", () => {
    const tracked = JSON.parse(readFileSync(hooksSource, "utf8")) as {
      hooks: Record<string, Array<{ hooks: Array<{ command?: string; type: string }> }>>;
    };
    const expectedEvents = [
      "SessionStart",
      "UserPromptSubmit",
      "PreToolUse",
      "PostToolUse",
      "PermissionRequest",
      "Stop",
    ];

    expect(Object.keys(tracked.hooks).sort()).toEqual([...expectedEvents].sort());

    for (const eventName of expectedEvents) {
      expect(tracked.hooks[eventName]).toEqual([
        {
          hooks: [
            {
              type: "command",
              command: `~/.config/tmux/codex-agent-status-hook.sh ${eventName}`,
              timeout: 5,
            },
          ],
        },
      ]);
    }
  });
});
