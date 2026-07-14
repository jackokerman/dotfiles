#!/usr/bin/env bun

import { parse as parseToml } from "smol-toml@1.4.2";
import { parse as parseYaml } from "yaml@2.8.1";
import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { basename, dirname, resolve } from "node:path";

type TomlValue =
  | string
  | number
  | boolean
  | TomlValue[]
  | { [key: string]: TomlValue };

type TomlDocument = Record<string, TomlValue>;
type YamlDocument = Record<string, unknown>;
type SkillSource = {
  name: string;
  openaiYamlFile: string;
  skillFile: string;
  sourceDir: string;
};
type AgentSource = {
  name: string;
  sourceFile: string;
  doc: TomlDocument;
};
type FrontendManifest = {
  defaultSkills: string[];
  excludedTaskCategories: string[];
  optionalSkills: string[];
  preferredAgent: string;
  sourceFile: string;
};

function parseArgs(argv: string[]) {
  const manifestSources: string[] = [];
  const agentSources: string[] = [];
  const skillSources: string[] = [];

  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    const value = argv[index + 1];

    if (token === "--manifest-source" && value) {
      manifestSources.push(resolve(value));
      index += 1;
      continue;
    }

    if (token === "--agent-source" && value) {
      agentSources.push(resolve(value));
      index += 1;
      continue;
    }

    if (token === "--skill-source" && value) {
      skillSources.push(resolve(value));
      index += 1;
      continue;
    }
  }

  return {
    manifestSources,
    agentSources,
    skillSources,
  };
}

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function listDirectories(root: string) {
  if (!existsSync(root)) {
    return [] as string[];
  }

  return readdirSync(root)
    .map((entry) => resolve(root, entry))
    .filter((entry) => statSync(entry).isDirectory())
    .sort();
}

function listTomlFiles(root: string) {
  if (!existsSync(root)) {
    return [] as string[];
  }

  return readdirSync(root)
    .filter((entry) => entry.endsWith(".toml"))
    .map((entry) => resolve(root, entry))
    .sort();
}

function loadToml(path: string) {
  const raw = parseToml(readFileSync(path, "utf8"));
  if (!isObject(raw)) {
    throw new Error(`Expected TOML table in ${path}`);
  }
  return raw as TomlDocument;
}

function loadYaml(path: string) {
  const raw = parseYaml(readFileSync(path, "utf8"));
  if (!isObject(raw)) {
    throw new Error(`Expected YAML object in ${path}`);
  }
  return raw as YamlDocument;
}

function parseStringArray(value: unknown, field: string, sourceFile: string) {
  if (!Array.isArray(value)) {
    throw new Error(`Expected ${field} array in ${sourceFile}`);
  }

  const items = value.map((entry, index) => {
    if (typeof entry !== "string" || entry.length === 0) {
      throw new Error(`Expected non-empty string at ${field}[${index}] in ${sourceFile}`);
    }

    return entry;
  });

  const seen = new Set<string>();
  for (const item of items) {
    if (seen.has(item)) {
      throw new Error(`Duplicate ${field} entry "${item}" in ${sourceFile}`);
    }
    seen.add(item);
  }

  return items;
}

function collectSkillSources(skillRoots: string[]) {
  const skills = new Map<string, SkillSource>();

  for (const root of skillRoots) {
    for (const sourceDir of listDirectories(root)) {
      const name = basename(sourceDir);
      skills.set(name, {
        name,
        openaiYamlFile: resolve(sourceDir, "agents", "openai.yaml"),
        skillFile: resolve(sourceDir, "SKILL.md"),
        sourceDir,
      });
    }
  }

  return skills;
}

function collectAgentSources(agentRoots: string[]) {
  const agents = new Map<string, AgentSource>();

  for (const root of agentRoots) {
    for (const sourceFile of listTomlFiles(root)) {
      const name = basename(sourceFile, ".toml");
      agents.set(name, {
        name,
        sourceFile,
        doc: loadToml(sourceFile),
      });
    }
  }

  return agents;
}

function parseManifest(manifestSources: string[]) {
  if (manifestSources.length === 0) {
    return null;
  }

  const sourceFile = manifestSources[manifestSources.length - 1];
  const doc = loadToml(sourceFile);
  const preferredAgent = doc.preferred_agent;

  if (typeof preferredAgent !== "string" || preferredAgent.length === 0) {
    throw new Error(`Expected preferred_agent string in ${sourceFile}`);
  }

  const defaultSkills = parseStringArray(doc.default_skills, "default_skills", sourceFile);
  const optionalSkills = parseStringArray(doc.optional_skills, "optional_skills", sourceFile);
  const excludedTaskCategories = parseStringArray(
    doc.excluded_task_categories,
    "excluded_task_categories",
    sourceFile,
  );

  for (const skillName of optionalSkills) {
    if (defaultSkills.includes(skillName)) {
      throw new Error(
        `Optional frontend skill "${skillName}" is also listed in default_skills in ${sourceFile}`,
      );
    }
  }

  return {
    defaultSkills,
    excludedTaskCategories,
    optionalSkills,
    preferredAgent,
    sourceFile,
  } satisfies FrontendManifest;
}

function assertStringField(record: Record<string, unknown>, field: string, sourceFile: string) {
  const value = record[field];
  if (typeof value !== "string" || value.length === 0) {
    throw new Error(`Expected interface.${field} string in ${sourceFile}`);
  }

  return value;
}

function validateSkillMetadata(skill: SkillSource) {
  if (!existsSync(skill.skillFile)) {
    throw new Error(`Missing SKILL.md for tracked skill "${skill.name}" at ${skill.skillFile}`);
  }

  if (!existsSync(skill.openaiYamlFile)) {
    throw new Error(
      `Missing agents/openai.yaml for tracked skill "${skill.name}" at ${skill.sourceDir}`,
    );
  }

  const doc = loadYaml(skill.openaiYamlFile);
  const interfaceConfig = doc.interface;
  if (!isObject(interfaceConfig)) {
    throw new Error(`Expected interface object in ${skill.openaiYamlFile}`);
  }

  assertStringField(interfaceConfig, "display_name", skill.openaiYamlFile);
  assertStringField(interfaceConfig, "short_description", skill.openaiYamlFile);
  const defaultPrompt = assertStringField(interfaceConfig, "default_prompt", skill.openaiYamlFile);
  const expectedSkillRef = `$${skill.name}`;
  if (!defaultPrompt.includes(expectedSkillRef)) {
    throw new Error(
      `Expected interface.default_prompt in ${skill.openaiYamlFile} to mention ${expectedSkillRef}`,
    );
  }
}

function extractSkillReferenceName(pathValue: string, sourceFile: string, index: number) {
  if (pathValue.startsWith("skill://")) {
    const name = pathValue.slice("skill://".length);
    if (name.length === 0) {
      throw new Error(`Expected skill name in ${sourceFile} entry ${index + 1}`);
    }

    return name;
  }

  const resolvedPath = pathValue.startsWith("/")
    ? pathValue
    : resolve(dirname(sourceFile), pathValue);
  if (basename(resolvedPath) !== "SKILL.md") {
    throw new Error(
      `Expected skill:// reference or SKILL.md path in ${sourceFile} entry ${index + 1}`,
    );
  }

  return basename(dirname(resolvedPath));
}

function extractAttachedSkills(agent: AgentSource) {
  const skillsTable = agent.doc.skills;
  if (skillsTable === undefined) {
    return [] as string[];
  }

  if (!isObject(skillsTable)) {
    throw new Error(`Expected [skills] table in ${agent.sourceFile}`);
  }

  const configEntries = skillsTable.config;
  if (configEntries === undefined) {
    return [] as string[];
  }

  const entries = Array.isArray(configEntries) ? configEntries : [configEntries];
  return entries.map((entry, index) => {
    if (!isObject(entry)) {
      throw new Error(`Expected [skills.config] object in ${agent.sourceFile} entry ${index + 1}`);
    }

    const pathValue = entry.path;
    if (typeof pathValue !== "string" || pathValue.length === 0) {
      throw new Error(`Expected skill path in ${agent.sourceFile} entry ${index + 1}`);
    }

    return extractSkillReferenceName(pathValue, agent.sourceFile, index);
  });
}

function validateManifest(manifest: FrontendManifest, agents: Map<string, AgentSource>, skills: Map<string, SkillSource>) {
  for (const skillName of manifest.defaultSkills) {
    if (!skills.has(skillName)) {
      throw new Error(
        `Frontend workflow manifest references unknown default skill "${skillName}" in ${manifest.sourceFile}`,
      );
    }
  }

  for (const skillName of manifest.optionalSkills) {
    if (!skills.has(skillName)) {
      throw new Error(
        `Frontend workflow manifest references unknown optional skill "${skillName}" in ${manifest.sourceFile}`,
      );
    }
  }

  if (manifest.excludedTaskCategories.length === 0) {
    throw new Error(`Expected excluded_task_categories entries in ${manifest.sourceFile}`);
  }

  const agent = agents.get(manifest.preferredAgent);
  if (!agent) {
    throw new Error(
      `Frontend workflow manifest references unknown preferred_agent "${manifest.preferredAgent}" in ${manifest.sourceFile}`,
    );
  }

  const attachedSkills = extractAttachedSkills(agent);
  const attachedSkillList = attachedSkills.join(", ");
  const defaultSkillList = manifest.defaultSkills.join(", ");
  if (
    attachedSkills.length !== manifest.defaultSkills.length ||
    attachedSkills.some((skillName, index) => skillName !== manifest.defaultSkills[index])
  ) {
    throw new Error(
      `Frontend agent ${manifest.preferredAgent} in ${agent.sourceFile} must attach exactly [${defaultSkillList}] but found [${attachedSkillList}]`,
    );
  }
}

function main() {
  const { manifestSources, agentSources, skillSources } = parseArgs(process.argv.slice(2));
  const skills = collectSkillSources(skillSources);

  for (const skill of skills.values()) {
    validateSkillMetadata(skill);
  }

  const manifest = parseManifest(manifestSources);
  if (!manifest) {
    return;
  }

  const agents = collectAgentSources(agentSources);
  validateManifest(manifest, agents, skills);
}

main();
