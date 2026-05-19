#!/usr/bin/env bun

import { build, parse } from "plist@3.1.0";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";

type JsonObject = Record<string, unknown>;
type ThemeSettings = Record<string, string>;
type ThemeRule = {
  name?: string;
  scope?: string;
  settings?: ThemeSettings;
};
type ThemeDocument = {
  author?: string;
  colorSpaceName?: string;
  name?: string;
  settings?: ThemeRule[];
  uuid?: string;
};
type OpencodeThemeEntry = {
  dark: string;
  light?: string;
};

const projectRoot = resolve(import.meta.dir, "..");
const referenceDir = resolve(projectRoot, "home/.codex/references/nightfly");
const fly16SourcePath = resolve(referenceDir, "fly16.tmTheme");
const opencodeSourcePath = resolve(referenceDir, "nightfly-opencode.json");
const outputPath = resolve(projectRoot, "home/.codex/themes/nightfly.tmTheme");

const fly16SourceUrl = "https://raw.githubusercontent.com/bluz71/fly16-bat/master/fly16.tmTheme";
const opencodeSourceUrl =
  "https://raw.githubusercontent.com/bluz71/vim-nightfly-colors/master/extras/nightfly-opencode.json";
const nightflyVimPaletteUrl =
  "https://raw.githubusercontent.com/bluz71/vim-nightfly-colors/master/autoload/nightfly.vim";

// These palette constants are taken from `autoload/nightfly.vim`.
const nightflyPalette = {
  black: "#011627",
  darkBlue: "#092236",
  regalBlue: "#1d3b53",
  slateBlue: "#2c3043",
  steelBlue: "#4b6479",
  malibu: "#87bcff",
};

const themeId = "nightfly-codex-theme";

function fail(message: string): never {
  throw new Error(message);
}

function usage() {
  return [
    "Usage: bun scripts/sync-codex-nightfly-theme.ts [--check] [--refresh-upstream]",
    "",
    "  --check            Fail if the generated theme differs from the tracked file",
    "  --refresh-upstream Refresh vendored upstream reference files before generating",
  ].join("\n");
}

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function readRequiredFile(path: string) {
  if (!existsSync(path)) {
    fail(
      `Missing ${path}. Run \`bun scripts/sync-codex-nightfly-theme.ts --refresh-upstream\` first.`,
    );
  }

  return readFileSync(path, "utf8");
}

function parseThemeDocument(path: string) {
  const value = parse(readRequiredFile(path));
  if (!isObject(value)) {
    fail(`Expected plist object in ${path}`);
  }

  return value as ThemeDocument;
}

function parseJsonObject(path: string) {
  const parsed = JSON.parse(readRequiredFile(path)) as unknown;
  if (!isObject(parsed)) {
    fail(`Expected JSON object in ${path}`);
  }

  return parsed as JsonObject;
}

function getString(object: Record<string, unknown>, key: string, context: string) {
  const value = object[key];
  if (typeof value !== "string") {
    fail(`Expected ${context}.${key} to be a string`);
  }

  return value;
}

function getObject(object: Record<string, unknown>, key: string, context: string) {
  const value = object[key];
  if (!isObject(value)) {
    fail(`Expected ${context}.${key} to be an object`);
  }

  return value;
}

function getThemeRules(theme: ThemeDocument) {
  if (!Array.isArray(theme.settings) || theme.settings.length === 0) {
    fail("Expected plist settings array");
  }

  return theme.settings;
}

function getRuleSettings(rule: ThemeRule) {
  if (!isObject(rule.settings)) {
    rule.settings = {};
  }

  return rule.settings;
}

function findRuleByScope(rules: ThemeRule[], scope: string) {
  const rule = rules.find((candidate) => candidate.scope === scope);
  if (!rule) {
    fail(`Expected scope ${scope} in fly16.tmTheme`);
  }

  return rule;
}

function resolveThemeColor(
  defs: Record<string, unknown>,
  theme: Record<string, unknown>,
  key: string,
) {
  const entry = theme[key];
  if (!isObject(entry)) {
    fail(`Expected theme.${key} to be an object`);
  }

  const darkValue = entry.dark;
  if (typeof darkValue !== "string") {
    fail(`Expected theme.${key}.dark to be a string`);
  }

  if (darkValue.startsWith("#")) {
    return darkValue;
  }

  return getString(defs, darkValue, "defs");
}

async function fetchText(url: string) {
  const response = await fetch(url);
  if (!response.ok) {
    fail(`Failed to fetch ${url}: ${response.status} ${response.statusText}`);
  }

  return response.text();
}

async function refreshUpstreamReferences() {
  mkdirSync(referenceDir, { recursive: true });

  const [fly16Source, opencodeSource] = await Promise.all([
    fetchText(fly16SourceUrl),
    fetchText(opencodeSourceUrl),
  ]);

  writeFileSync(fly16SourcePath, fly16Source, "utf8");
  writeFileSync(opencodeSourcePath, opencodeSource, "utf8");
}

function generateTheme() {
  const opencode = parseJsonObject(opencodeSourcePath);
  const defs = getObject(opencode, "defs", "opencode");
  const theme = getObject(opencode, "theme", "opencode");

  const base16Map: Record<string, string> = {
    "#00000000": nightflyPalette.black,
    "#01000000": getString(defs, "red", "defs"),
    "#02000000": getString(defs, "green", "defs"),
    "#03000000": getString(defs, "yellow", "defs"),
    "#04000000": getString(defs, "blue", "defs"),
    "#05000000": getString(defs, "purple", "defs"),
    "#06000000": getString(defs, "cyan", "defs"),
    "#07000000": resolveThemeColor(defs, theme, "text"),
    "#08000000": getString(defs, "brightBlack", "defs"),
    "#09000000": getString(defs, "brightRed", "defs"),
    "#0a000000": getString(defs, "brightGreen", "defs"),
    "#0b000000": getString(defs, "brightYellow", "defs"),
    "#0c000000": nightflyPalette.malibu,
    "#0d000000": getString(defs, "brightPurple", "defs"),
    "#0e000000": getString(defs, "brightCyan", "defs"),
    "#0f000000": getString(defs, "brightWhite", "defs"),
  };

  const themeDocument = parseThemeDocument(fly16SourcePath);
  const rules = getThemeRules(themeDocument);

  themeDocument.author =
    "Generated from bluz71/fly16-bat and bluz71/vim-nightfly-colors for Codex";
  themeDocument.name = "nightfly";
  themeDocument.colorSpaceName = "sRGB";
  themeDocument.uuid = themeId;

  for (const rule of rules) {
    const settings = getRuleSettings(rule);
    for (const [key, value] of Object.entries(settings)) {
      settings[key] = base16Map[value] ?? value;
    }
  }

  Object.assign(getRuleSettings(rules[0]), {
    background: resolveThemeColor(defs, theme, "background"),
    caret: getString(defs, "cursor", "defs"),
    foreground: resolveThemeColor(defs, theme, "text"),
    gutter: resolveThemeColor(defs, theme, "background"),
    gutterForeground: nightflyPalette.steelBlue,
    invisibles: nightflyPalette.steelBlue,
    lineHighlight: nightflyPalette.darkBlue,
    selection: nightflyPalette.regalBlue,
  });

  getRuleSettings(findRuleByScope(rules, "meta.separator")).background = nightflyPalette.regalBlue;
  getRuleSettings(findRuleByScope(rules, "markup.inserted")).background = resolveThemeColor(
    defs,
    theme,
    "diffAddedBg",
  );
  getRuleSettings(findRuleByScope(rules, "markup.deleted")).background = resolveThemeColor(
    defs,
    theme,
    "diffRemovedBg",
  );

  const changedSettings = getRuleSettings(findRuleByScope(rules, "markup.changed"));
  changedSettings.background = nightflyPalette.slateBlue;
  changedSettings.foreground = nightflyPalette.malibu;

  const headerComment = [
    "<!--",
    "Generated by `scripts/sync-codex-nightfly-theme.ts`.",
    "",
    "Vendored upstream inputs:",
    `- ${fly16SourcePath.replace(`${projectRoot}/`, "")} from ${fly16SourceUrl}`,
    `- ${opencodeSourcePath.replace(`${projectRoot}/`, "")} from ${opencodeSourceUrl}`,
    "",
    "Additional top-level palette constants come from:",
    `- ${nightflyVimPaletteUrl}`,
    "",
    "Do not hand-edit this file. Regenerate it with:",
    "- `bun scripts/sync-codex-nightfly-theme.ts`",
    "- `bun scripts/sync-codex-nightfly-theme.ts --refresh-upstream`",
    "-->",
  ].join("\n");

  return `${build(themeDocument).replace(
    "<plist version=\"1.0\">",
    `${headerComment}\n<plist version="1.0">`,
  )}\n`;
}

async function main() {
  const args = new Set(Bun.argv.slice(2));
  const allowedArgs = new Set(["--check", "--help", "--refresh-upstream"]);

  for (const argument of args) {
    if (!allowedArgs.has(argument)) {
      fail(`Unknown argument: ${argument}\n\n${usage()}`);
    }
  }

  if (args.has("--help")) {
    process.stdout.write(`${usage()}\n`);
    return;
  }

  if (args.has("--refresh-upstream")) {
    await refreshUpstreamReferences();
  }

  const generatedTheme = generateTheme();

  if (args.has("--check")) {
    const currentTheme = readRequiredFile(outputPath);
    if (currentTheme !== generatedTheme) {
      fail(
        `Tracked Nightfly theme is out of date. Run \`bun scripts/sync-codex-nightfly-theme.ts\` to regenerate it.`,
      );
    }
    return;
  }

  mkdirSync(dirname(outputPath), { recursive: true });
  writeFileSync(outputPath, generatedTheme, "utf8");
}

await main();
