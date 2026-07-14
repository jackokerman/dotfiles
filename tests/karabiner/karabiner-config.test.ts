import { describe, expect, test } from "bun:test";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";

const repoRoot = resolve(import.meta.dir, "../..");
const karabinerScript = join(repoRoot, "scripts", "ts", "karabiner-config.ts");
const configPathParts = [".config", "karabiner", "karabiner.json"] as const;

type KarabinerConfig = {
  profiles: Array<{
    name: string;
    selected: boolean;
    devices?: Array<{
      identifiers?: {
        is_keyboard?: boolean;
        product_id?: number;
        vendor_id?: number;
      };
      ignore?: boolean;
      manipulate_caps_lock_led?: boolean;
    }>;
    complex_modifications: {
      rules: Array<{
        description: string;
        manipulators: Array<{
          type: string;
          from: { key_code: string };
          to?: Array<{ key_code?: string; modifiers?: string[] }>;
          conditions?: Array<{
            type: string;
            identifiers?: Array<{
              is_built_in_keyboard?: boolean;
              product_id?: number;
              vendor_id?: number;
            }>;
          }>;
        }>;
      }>;
    };
  }>;
};

function withTempHome(run: (homeDir: string) => void) {
  const homeDir = mkdtempSync(join(tmpdir(), "karabiner-config-"));

  try {
    run(homeDir);
  } finally {
    rmSync(homeDir, { force: true, recursive: true });
  }
}

function generatedConfigPath(homeDir: string) {
  return join(homeDir, ...configPathParts);
}

function writeKarabinerConfig(homeDir: string, contents: KarabinerConfig) {
  const configPath = generatedConfigPath(homeDir);
  mkdirSync(join(homeDir, ".config", "karabiner"), { recursive: true });
  writeFileSync(configPath, `${JSON.stringify(contents, null, 2)}\n`);
}

function runKarabinerConfig(homeDir: string) {
  return Bun.spawnSync(["bun", "--install=fallback", "run", karabinerScript], {
    cwd: repoRoot,
    env: { ...process.env, HOME: homeDir },
    stderr: "pipe",
    stdout: "pipe",
  });
}

describe("karabiner-config", () => {
  test("creates the config file with built-in keyboard control and shared hyper remaps", () => {
    withTempHome((homeDir) => {
      const result = runKarabinerConfig(homeDir);

      expect(result.exitCode).toBe(0);

      const configPath = generatedConfigPath(homeDir);
      expect(existsSync(configPath)).toBe(true);

      const config = JSON.parse(readFileSync(configPath, "utf8")) as KarabinerConfig;
      const profile = config.profiles.find((candidate) => candidate.name === "Default profile");

      expect(profile).toBeDefined();
      expect(profile?.selected).toBe(true);

      const capsLockRule = profile?.complex_modifications.rules.find(
        (rule) => rule.description === "Caps Lock: Tap for Caps Lock, Hold for Control (built-in keyboard only)",
      );
      expect(capsLockRule).toBeDefined();
      expect(capsLockRule?.manipulators).toContainEqual(
        expect.objectContaining({
          from: { key_code: "caps_lock" },
          conditions: [
            {
              type: "device_if",
              identifiers: [{ is_built_in_keyboard: true }],
            },
          ],
        }),
      );

      const hyperRule = profile?.complex_modifications.rules.find(
        (rule) => rule.description === "Right Command: Hyper key (all keyboards except Touch ID Magic Keyboard)",
      );
      expect(hyperRule).toBeDefined();
      expect(hyperRule?.manipulators).toContainEqual({
        type: "basic",
        from: { key_code: "right_command" },
        conditions: [
          {
            type: "device_unless",
            identifiers: [{ product_id: 666, vendor_id: 1452 }],
          },
        ],
        to: [
          {
            key_code: "left_command",
            modifiers: ["option", "control", "shift"],
          },
        ],
      });
    });
  });

  test("re-enables ignored keyboards except the reserved Touch ID Magic Keyboard", () => {
    withTempHome((homeDir) => {
      writeKarabinerConfig(homeDir, {
        profiles: [
          {
            name: "Default profile",
            selected: true,
            devices: [
              {
                identifiers: { is_keyboard: true, product_id: 4897, vendor_id: 17498 },
                ignore: true,
              },
              {
                identifiers: { is_keyboard: true, product_id: 666, vendor_id: 1452 },
                manipulate_caps_lock_led: false,
              },
              {
                identifiers: { is_keyboard: true, product_id: 834, vendor_id: 1452 },
                ignore: true,
              },
            ],
            complex_modifications: { rules: [] },
          },
        ],
      });

      const result = runKarabinerConfig(homeDir);

      expect(result.exitCode).toBe(0);

      const config = JSON.parse(readFileSync(generatedConfigPath(homeDir), "utf8")) as KarabinerConfig;
      const profile = config.profiles.find((candidate) => candidate.name === "Default profile");

      expect(profile?.devices).toEqual([
        {
          identifiers: { is_keyboard: true, product_id: 4897, vendor_id: 17498 },
        },
        {
          identifiers: { is_keyboard: true, product_id: 666, vendor_id: 1452 },
          manipulate_caps_lock_led: false,
        },
        {
          identifiers: { is_keyboard: true, product_id: 834, vendor_id: 1452 },
        },
      ]);
    });
  });
});
