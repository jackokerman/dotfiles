#!/usr/bin/env bun

import { mergeWith } from "es-toolkit@1.45.1";
import { parse as parseToml, stringify } from "smol-toml@1.4.2";
import { parse as parseYaml } from "yaml@2.8.1";
import {
  cpSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readdirSync,
  readFileSync,
  renameSync,
  rmSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { basename, dirname, isAbsolute, join, resolve } from "node:path";

type TomlValue =
  | string
  | number
  | boolean
  | TomlValue[]
  | { [key: string]: TomlValue };

type TomlDocument = Record<string, TomlValue>;
type JsonValue = null | boolean | number | string | JsonValue[] | { [key: string]: JsonValue };
type JsonObject = Record<string, JsonValue>;
type Mode = "agents" | "config" | "custom-agents" | "hooks" | "skills";
type HookAction = JsonObject & { type: string };
type HookEventEntry = JsonObject & { hooks: HookAction[] };
type HookMap = Record<string, HookEventEntry[]>;
type ManagedIndexRow = Record<string, string>;
type SkillSource = {
  description: string;
  name: string;
  skillFile: string;
  sourceDir: string;
};
type AgentSource = {
  body: string;
  name: string;
  sourceFile: string;
};

function parseArgs(argv: string[]) {
  const [mode, ...rest] = argv;
  const sources: string[] = [];
  const skillSources: string[] = [];
  let output = "";
  let skillsOutput = "";
  let validateOnly = false;

  for (let index = 0; index < rest.length; index += 1) {
    const token = rest[index];
    if (token === "--output") {
      output = rest[index + 1] ?? "";
      index += 1;
      continue;
    }

    if (token === "--skills-output") {
      skillsOutput = rest[index + 1] ?? "";
      index += 1;
      continue;
    }

    if (token === "--source") {
      const source = rest[index + 1];
      if (source) {
        sources.push(resolve(source));
      }
      index += 1;
      continue;
    }

    if (token === "--skill-source") {
      const source = rest[index + 1];
      if (source) {
        skillSources.push(resolve(source));
      }
      index += 1;
      continue;
    }

    if (token === "--validate-only") {
      validateOnly = true;
      continue;
    }
  }

  if (
    (mode !== "agents" &&
      mode !== "config" &&
      mode !== "custom-agents" &&
      mode !== "hooks" &&
      mode !== "skills") ||
    (!output && !validateOnly) ||
    (mode === "custom-agents" && !validateOnly && !skillsOutput)
  ) {
    throw new Error(
      "Usage: sync-codex.ts <agents|config|custom-agents|hooks|skills> [--validate-only] --output <path> [--skills-output <path>] [--source <path> ...] [--skill-source <path> ...]",
    );
  }

  return {
    mode: mode as Mode,
    output: output ? resolve(output) : "",
    skillSources,
    skillsOutput: skillsOutput ? resolve(skillsOutput) : "",
    sources,
    validateOnly,
  };
}

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function clone<T>(value: T): T {
  return structuredClone(value);
}

function loadToml(path: string): TomlDocument {
  if (!existsSync(path)) {
    return {};
  }

  return parseTomlDocument(readFileSync(path, "utf8"), path);
}

function parseTomlDocument(text: string, context: string): TomlDocument {
  const value = parseToml(text);

  if (!isObject(value)) {
    throw new Error(`Expected TOML table in ${context}`);
  }

  return value as TomlDocument;
}

function replaceArrays(_targetValue: unknown, sourceValue: unknown) {
  if (Array.isArray(sourceValue)) {
    return clone(sourceValue);
  }

  return undefined;
}

function loadJson(path: string): JsonObject {
  if (!existsSync(path)) {
    return {};
  }

  return parseJsonObject(readFileSync(path, "utf8"), path);
}

function parseJsonObject(text: string, context: string): JsonObject {
  const parsed = JSON.parse(text) as JsonValue;
  if (!isObject(parsed)) {
    throw new Error(`Expected JSON object in ${context}`);
  }

  return parsed as JsonObject;
}

function buildHeader(lines: string[]) {
  return `${lines.map((line) => `# ${line}`).join("\n")}\n\n`;
}

function writeManagedFile(outputPath: string, body: string, headerLines: string[]) {
  mkdirSync(dirname(outputPath), { recursive: true });
  writeFileSync(outputPath, `${buildHeader(headerLines)}${body}`, "utf8");
}

function existingPaths(paths: string[]) {
  return paths.filter((path) => existsSync(path));
}

function ensureDirectory(path: string, context: string) {
  if (!existsSync(path) || !statSync(path).isDirectory()) {
    throw new Error(`Expected directory at ${context}: ${path}`);
  }
}

function ensureFile(path: string, context: string) {
  if (!existsSync(path) || !statSync(path).isFile()) {
    throw new Error(`Expected file at ${context}: ${path}`);
  }
}

function isFile(path: string) {
  return existsSync(path) && statSync(path).isFile();
}

function listDirectories(path: string) {
  ensureDirectory(path, "source root");

  return readdirSync(path, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => resolve(path, entry.name))
    .sort((left, right) => left.localeCompare(right));
}

function listTomlFiles(path: string) {
  ensureDirectory(path, "source root");

  return readdirSync(path, { withFileTypes: true })
    .filter((entry) => entry.isFile() && entry.name.endsWith(".toml"))
    .map((entry) => resolve(path, entry.name))
    .sort((left, right) => left.localeCompare(right));
}

function parseSkillFrontmatter(text: string, context: string) {
  const match = text.match(/^---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)/);
  if (!match) {
    throw new Error(`Expected YAML frontmatter in ${context}`);
  }

  const frontmatter = parseYaml(match[1]);
  if (!isObject(frontmatter)) {
    throw new Error(`Expected YAML frontmatter object in ${context}`);
  }

  const name = frontmatter.name;
  const description = frontmatter.description;

  if (typeof name !== "string" || name.length === 0) {
    throw new Error(`Expected non-empty skill name in ${context}`);
  }

  if (typeof description !== "string" || description.length === 0) {
    throw new Error(`Expected non-empty skill description in ${context}`);
  }

  if (description.length > 1024) {
    throw new Error(`Skill description is too long in ${context}: ${description.length}`);
  }

  return { description, name };
}

function collectSkillSources(sourceRoots: string[]) {
  const skills = new Map<string, SkillSource>();
  const roots = existingPaths(sourceRoots);

  for (const root of roots) {
    for (const sourceDir of listDirectories(root)) {
      const skillFile = resolve(sourceDir, "SKILL.md");
      ensureFile(skillFile, "skill file");

      const { description, name } = parseSkillFrontmatter(readFileSync(skillFile, "utf8"), skillFile);
      const expectedName = basename(sourceDir);
      if (name !== expectedName) {
        throw new Error(
          `Skill directory name mismatch in ${skillFile}: expected "${expectedName}", found "${name}"`,
        );
      }

      skills.set(name, {
        description,
        name,
        skillFile,
        sourceDir,
      });
    }
  }

  return {
    roots,
    skills,
  };
}

function parseManagedIndex(path: string) {
  if (!isFile(path)) {
    return [] as ManagedIndexRow[];
  }

  const text = readFileSync(path, "utf8").trim();
  if (text.length === 0) {
    return [] as ManagedIndexRow[];
  }

  const [headerLine, ...rowLines] = text.split("\n");
  const headers = headerLine.split("\t");

  return rowLines
    .filter(Boolean)
    .map((line) => {
      const values = line.split("\t");
      return headers.reduce<ManagedIndexRow>((row, header, index) => {
        row[header] = values[index] ?? "";
        return row;
      }, {});
    });
}

function writeManagedIndex(path: string, headers: string[], rows: ManagedIndexRow[]) {
  const body = [
    headers.join("\t"),
    ...rows.map((row) => headers.map((header) => row[header] ?? "").join("\t")),
  ].join("\n");

  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, `${body}\n`, "utf8");
}

function replaceDirectory(targetDir: string, sourceDir: string) {
  const stagingRoot = mkdtempSync(join(dirname(targetDir), ".tmp-codex-skill-"));
  const stagingDir = join(stagingRoot, basename(targetDir));

  cpSync(sourceDir, stagingDir, { recursive: true });
  rmSync(targetDir, { force: true, recursive: true });
  renameSync(stagingDir, targetDir);
  rmSync(stagingRoot, { force: true, recursive: true });
}

function syncSkills(outputPath: string, sourceRoots: string[], validateOnly: boolean) {
  const { skills } = collectSkillSources(sourceRoots);

  if (validateOnly) {
    return;
  }

  mkdirSync(outputPath, { recursive: true });
  const indexPath = resolve(outputPath, ".dotty-managed-skills.tsv");
  const previousRows = parseManagedIndex(indexPath);
  const currentNames = new Set<string>();
  const rows: ManagedIndexRow[] = [];

  for (const skill of skills.values()) {
    const targetDir = resolve(outputPath, skill.name);
    currentNames.add(skill.name);
    replaceDirectory(targetDir, skill.sourceDir);
    rows.push({
      skill_name: skill.name,
      source_dir: skill.sourceDir,
      target_dir: targetDir,
    });
  }

  for (const row of previousRows) {
    const skillName = row.skill_name;
    const targetDir = row.target_dir;
    if (!skillName || !targetDir || currentNames.has(skillName)) {
      continue;
    }
    rmSync(targetDir, { force: true, recursive: true });
  }

  writeManagedIndex(indexPath, ["skill_name", "source_dir", "target_dir"], rows);
}

function validateSkillConfigEntries(sourceFile: string, doc: TomlDocument) {
  const skillsTable = doc.skills;
  if (skillsTable === undefined) {
    return [];
  }

  if (!isObject(skillsTable)) {
    throw new Error(`Expected [skills] table in ${sourceFile}`);
  }

  const configEntries = skillsTable.config;
  if (configEntries === undefined) {
    return [];
  }

  if (Array.isArray(configEntries)) {
    return configEntries;
  }

  if (isObject(configEntries)) {
    return [configEntries];
  }

  throw new Error(`Expected [skills.config] entries in ${sourceFile}`);
}

function resolveSkillReference(
  pathValue: string,
  sourceFile: string,
  skillSources: Map<string, SkillSource>,
  skillsOutput: string,
) {
  if (pathValue.startsWith("skill://")) {
    const skillName = pathValue.slice("skill://".length);
    if (skillName.length === 0) {
      throw new Error(`Expected skill name in ${sourceFile}`);
    }

    if (!skillSources.has(skillName)) {
      throw new Error(`Unknown tracked skill "${skillName}" referenced by ${sourceFile}`);
    }

    if (!skillsOutput) {
      return skillSources.get(skillName)!.skillFile;
    }

    return resolve(skillsOutput, skillName, "SKILL.md");
  }

  const resolvedPath = isAbsolute(pathValue) ? pathValue : resolve(dirname(sourceFile), pathValue);
  ensureFile(resolvedPath, `agent skill path referenced by ${sourceFile}`);
  return resolvedPath;
}

function normalizeAgentDocument(
  sourceFile: string,
  expectedName: string,
  skillSources: Map<string, SkillSource>,
  skillsOutput: string,
) {
  const doc = loadToml(sourceFile);

  if (doc.name !== expectedName) {
    throw new Error(
      `Agent name mismatch in ${sourceFile}: expected "${expectedName}", found "${String(doc.name ?? "")}"`,
    );
  }

  const description = doc.description;
  if (typeof description !== "string" || description.length === 0) {
    throw new Error(`Expected non-empty description in ${sourceFile}`);
  }

  if (description.length > 1024) {
    throw new Error(`Agent description is too long in ${sourceFile}: ${description.length}`);
  }

  const developerInstructions = doc.developer_instructions;
  if (typeof developerInstructions !== "string" || developerInstructions.length === 0) {
    throw new Error(`Expected non-empty developer_instructions in ${sourceFile}`);
  }

  const skillEntries = validateSkillConfigEntries(sourceFile, doc);
  if (skillEntries.length === 0) {
    return doc;
  }

  const skillsTable = clone(doc.skills as Record<string, TomlValue>);
  skillsTable.config = skillEntries.map((entry, index) => {
    if (!isObject(entry)) {
      throw new Error(`Expected skill config table at ${sourceFile} entry ${index + 1}`);
    }

    const pathValue = entry.path;
    if (typeof pathValue !== "string" || pathValue.length === 0) {
      throw new Error(`Expected skill config path at ${sourceFile} entry ${index + 1}`);
    }

    return {
      ...(clone(entry as Record<string, TomlValue>)),
      path: resolveSkillReference(pathValue, sourceFile, skillSources, skillsOutput),
    };
  });

  return {
    ...doc,
    skills: skillsTable,
  };
}

function collectAgentSources(
  sourceRoots: string[],
  skillSourceRoots: string[],
  skillsOutput: string,
) {
  const { skills } = collectSkillSources(skillSourceRoots);
  const agents = new Map<string, AgentSource>();
  const roots = existingPaths(sourceRoots);

  for (const root of roots) {
    for (const sourceFile of listTomlFiles(root)) {
      const name = basename(sourceFile, ".toml");
      const body = stringify(normalizeAgentDocument(sourceFile, name, skills, skillsOutput));
      parseTomlDocument(body, `generated agent ${name}`);

      agents.set(name, {
        body,
        name,
        sourceFile,
      });
    }
  }

  return {
    agents,
    roots,
    skills,
  };
}

function syncCustomAgents(
  outputPath: string,
  sourceRoots: string[],
  skillSourceRoots: string[],
  skillsOutput: string,
  validateOnly: boolean,
) {
  const { agents } = collectAgentSources(sourceRoots, skillSourceRoots, skillsOutput);

  if (validateOnly) {
    return;
  }

  mkdirSync(outputPath, { recursive: true });
  const indexPath = resolve(outputPath, ".dotty-managed-agents.tsv");
  const previousRows = parseManagedIndex(indexPath);
  const currentNames = new Set<string>();
  const rows: ManagedIndexRow[] = [];

  for (const agent of agents.values()) {
    const targetFile = resolve(outputPath, `${agent.name}.toml`);
    currentNames.add(agent.name);
    writeManagedFile(targetFile, agent.body, [
      "Generated by dotty from tracked Codex custom agents.",
      "Edit the tracked source and run `dotty update`.",
      `Source: ${agent.sourceFile}`,
    ]);
    rows.push({
      agent_name: agent.name,
      source_file: agent.sourceFile,
      target_file: targetFile,
    });
  }

  for (const row of previousRows) {
    const agentName = row.agent_name;
    const targetFile = row.target_file;
    if (!agentName || !targetFile || currentNames.has(agentName)) {
      continue;
    }
    rmSync(targetFile, { force: true });
  }

  writeManagedIndex(indexPath, ["agent_name", "source_file", "target_file"], rows);
}

function renderAgents(sourcePaths: string[]) {
  const sources = existingPaths(sourcePaths);
  const sections = sources.map((source) => readFileSync(source, "utf8").trim()).filter(Boolean);
  const body = sections.length > 0 ? `${sections.join("\n\n---\n\n")}\n` : "";

  return { body, sources };
}

function syncAgents(outputPath: string, sourcePaths: string[], validateOnly: boolean) {
  const { body, sources } = renderAgents(sourcePaths);

  if (validateOnly) {
    return;
  }

  writeManagedFile(outputPath, body, [
    "Generated by dotty from tracked Codex instruction fragments.",
    "Edit one of these source files, then run `dotty update`.",
    ...sources.map((source) => `Source: ${source}`),
  ]);
}

function renderConfig(outputPath: string, sourcePaths: string[], validateOnly: boolean) {
  let merged = validateOnly ? {} : clone(loadToml(outputPath));
  const sources = existingPaths(sourcePaths);

  for (const source of sources) {
    merged = mergeWith(merged, loadToml(source), replaceArrays) as TomlDocument;
  }

  const body = stringify(merged);
  parseTomlDocument(body, "generated Codex config");

  return { body, sources };
}

function syncConfig(outputPath: string, sourcePaths: string[], validateOnly: boolean) {
  const { body, sources } = renderConfig(outputPath, sourcePaths, validateOnly);

  if (validateOnly) {
    return;
  }

  writeManagedFile(outputPath, body, [
    "Generated by dotty from tracked Codex config fragments.",
    "Tracked fragments are deep-merged over the live local file; tables merge recursively and arrays are replaced by later sources.",
    "Edit one of these source files, then run `dotty update`.",
    ...sources.map((source) => `Source: ${source}`),
  ]);
}

function validateHookAction(entry: JsonValue, context: string): HookAction {
  if (!isObject(entry)) {
    throw new Error(`Expected hook action object in ${context}`);
  }

  if (typeof entry.type !== "string" || entry.type.length === 0) {
    throw new Error(`Expected hook action with string type in ${context}`);
  }

  if (entry.type === "command" && typeof entry.command !== "string") {
    throw new Error(`Expected command hook with string command in ${context}`);
  }

  return clone(entry as HookAction);
}

function validateHookEventEntry(entry: JsonValue, context: string): HookEventEntry {
  if (!isObject(entry)) {
    throw new Error(`Expected hook event entry object in ${context}`);
  }

  if (!Array.isArray(entry.hooks)) {
    throw new Error(`Expected hook event entry with hooks array in ${context}`);
  }

  const hooks = entry.hooks.map((action, index) =>
    validateHookAction(action, `${context}.hooks[${index}]`),
  );

  return {
    ...(clone(entry as JsonObject)),
    hooks,
  };
}

function loadHooks(path: string) {
  const parsed = loadJson(path);
  const rawHooks = parsed.hooks;

  if (!isObject(rawHooks)) {
    throw new Error(`Expected JSON object with hooks table in ${path}`);
  }

  const hooks: HookMap = {};

  for (const [eventName, eventHooks] of Object.entries(rawHooks)) {
    if (!Array.isArray(eventHooks)) {
      throw new Error(`Expected hook array for event "${eventName}" in ${path}`);
    }

    hooks[eventName] = eventHooks.map((entry, index) =>
      validateHookEventEntry(entry, `${path} (${eventName}[${index}])`),
    );
  }

  return hooks;
}

function renderHooks(sourcePaths: string[]) {
  const sources = existingPaths(sourcePaths);
  const hooks: HookMap = {};

  for (const source of sources) {
    const parsed = loadHooks(source);
    for (const [eventName, eventHooks] of Object.entries(parsed)) {
      hooks[eventName] ??= [];
      hooks[eventName].push(...eventHooks.map((entry) => clone(entry)));
    }
  }

  const body = `${JSON.stringify({ hooks }, null, 2)}\n`;
  parseJsonObject(body, "generated Codex hooks");

  return body;
}

function syncHooks(outputPath: string, sourcePaths: string[], validateOnly: boolean) {
  const body = renderHooks(sourcePaths);

  if (validateOnly) {
    return;
  }

  mkdirSync(dirname(outputPath), { recursive: true });
  writeFileSync(outputPath, body, "utf8");
}

function main() {
  const { mode, output, skillSources, skillsOutput, sources, validateOnly } = parseArgs(
    process.argv.slice(2),
  );

  if (mode === "agents") {
    syncAgents(output, sources, validateOnly);
    return;
  }

  if (mode === "skills") {
    syncSkills(output, sources, validateOnly);
    return;
  }

  if (mode === "custom-agents") {
    syncCustomAgents(output, sources, skillSources, skillsOutput, validateOnly);
    return;
  }

  if (mode === "hooks") {
    syncHooks(output, sources, validateOnly);
    return;
  }

  syncConfig(output, sources, validateOnly);
}

main();
