#!/usr/bin/env bun

import {
  cpSync,
  existsSync,
  lstatSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  readdirSync,
  renameSync,
  rmSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { basename, dirname, join, resolve } from "node:path";
import { tmpdir } from "node:os";

type Mode = "codex-agents" | "portable";

type ParsedArgs = {
  claudeOutput: string;
  claudeSkillsOutput: string;
  codexAgentsOutput: string;
  codexSkillsOutput: string;
  mode: Mode;
  output: string;
  rulerBin: string;
  skillSources: string[];
  sources: string[];
  validateOnly: boolean;
};

type ManagedIndexRow = Record<string, string>;
type StagedSkill = {
  name: string;
  sourceDir: string;
};

function parseArgs(argv: string[]): ParsedArgs {
  const [mode, ...rest] = argv;
  const sources: string[] = [];
  const skillSources: string[] = [];
  let claudeOutput = "";
  let claudeSkillsOutput = "";
  let codexAgentsOutput = "";
  let codexSkillsOutput = "";
  let output = "";
  let rulerBin = process.env.RULER_BIN ?? "";
  let validateOnly = false;

  for (let index = 0; index < rest.length; index += 1) {
    const token = rest[index];

    if (token === "--output") {
      output = rest[index + 1] ?? "";
      index += 1;
      continue;
    }

    if (token === "--codex-agents-output") {
      codexAgentsOutput = rest[index + 1] ?? "";
      index += 1;
      continue;
    }

    if (token === "--claude-output") {
      claudeOutput = rest[index + 1] ?? "";
      index += 1;
      continue;
    }

    if (token === "--codex-skills-output") {
      codexSkillsOutput = rest[index + 1] ?? "";
      index += 1;
      continue;
    }

    if (token === "--claude-skills-output") {
      claudeSkillsOutput = rest[index + 1] ?? "";
      index += 1;
      continue;
    }

    if (token === "--ruler-bin") {
      rulerBin = rest[index + 1] ?? "";
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

  if (mode === "codex-agents" && !output && !validateOnly) {
    throw new Error(
      "Usage: sync-ruler.ts codex-agents [--validate-only] --output <path> [--ruler-bin <path>] --source <path> ...",
    );
  }

  if (
    mode === "portable" &&
    !validateOnly &&
    (!codexAgentsOutput || !claudeOutput || !codexSkillsOutput || !claudeSkillsOutput)
  ) {
    throw new Error(
      "Usage: sync-ruler.ts portable [--validate-only] --codex-agents-output <path> --claude-output <path> --codex-skills-output <path> --claude-skills-output <path> [--ruler-bin <path>] --source <path> ... [--skill-source <path> ...]",
    );
  }

  if (mode !== "codex-agents" && mode !== "portable") {
    throw new Error(
      "Usage: sync-ruler.ts <codex-agents|portable> [--validate-only] [options]",
    );
  }

  return {
    claudeOutput: claudeOutput ? resolve(claudeOutput) : "",
    claudeSkillsOutput: claudeSkillsOutput ? resolve(claudeSkillsOutput) : "",
    codexAgentsOutput: codexAgentsOutput ? resolve(codexAgentsOutput) : "",
    codexSkillsOutput: codexSkillsOutput ? resolve(codexSkillsOutput) : "",
    mode,
    output: output ? resolve(output) : "",
    rulerBin,
    skillSources,
    sources,
    validateOnly,
  };
}

function existingFiles(paths: string[]) {
  return paths.filter((path) => existsSync(path) && statSync(path).isFile());
}

function existingDirectories(paths: string[]) {
  return paths.filter((path) => existsSync(path) && statSync(path).isDirectory());
}

function buildHeader(lines: string[]) {
  return `${lines.map((line) => `# ${line}`).join("\n")}\n\n`;
}

function removeTargetIfSymlink(path: string) {
  try {
    if (lstatSync(path).isSymbolicLink()) {
      rmSync(path, { force: true });
    }
  } catch (error) {
    if (!(error instanceof Error && "code" in error && error.code === "ENOENT")) {
      throw error;
    }
  }
}

function writeManagedFile(outputPath: string, body: string, headerLines: string[]) {
  mkdirSync(dirname(outputPath), { recursive: true });
  removeTargetIfSymlink(outputPath);
  writeFileSync(outputPath, `${buildHeader(headerLines)}${body}`, "utf8");
}

function renderRulerAgentsSource(sourcePaths: string[]) {
  const sources = existingFiles(sourcePaths);

  if (sources.length === 0) {
    throw new Error("No existing Ruler AGENTS.md sources were provided.");
  }

  const sections = sources
    .map((source) => {
      const body = readFileSync(source, "utf8").trim();
      return body ? `<!-- Source: ${source} -->\n\n${body}` : "";
    })
    .filter(Boolean);

  return {
    body: `${sections.join("\n\n---\n\n")}\n`,
    sources,
  };
}

function rulerCommand(rulerBin: string) {
  if (rulerBin) {
    return {
      args: [rulerBin],
      displayName: rulerBin,
    };
  }

  return {
    args: ["npx", "-y", "@intellectronica/ruler"],
    displayName: "npx -y @intellectronica/ruler",
  };
}

function runRuler(stagingRoot: string, agents: string[], validateOnly: boolean, rulerBin: string) {
  const command = rulerCommand(rulerBin);
  const args = [
    ...command.args,
    "apply",
    ...(validateOnly ? ["--dry-run"] : []),
    "--agents",
    agents.join(","),
    "--local-only",
    "--no-mcp",
    "--no-subagents",
    "--no-gitignore",
    "--no-backup",
    "--project-root",
    stagingRoot,
  ];
  const result = Bun.spawnSync(args, {
    stderr: "pipe",
    stdout: "pipe",
  });

  if (result.exitCode === 0) {
    return;
  }

  const stdout = new TextDecoder().decode(result.stdout).trim();
  const stderr = new TextDecoder().decode(result.stderr).trim();
  const details = [stdout, stderr].filter(Boolean).join("\n");

  throw new Error(`Ruler command failed: ${command.displayName}\n${details}`);
}

function replaceDirectory(targetDir: string, sourceDir: string) {
  const stagingRoot = mkdtempSync(join(dirname(targetDir), ".tmp-ruler-skill-"));
  const stagingDir = join(stagingRoot, basename(targetDir));

  cpSync(sourceDir, stagingDir, { recursive: true });
  rmSync(targetDir, { force: true, recursive: true });
  renameSync(stagingDir, targetDir);
  rmSync(stagingRoot, { force: true, recursive: true });
}

function listDirectories(path: string) {
  return readdirSync(path, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => resolve(path, entry.name))
    .sort((left, right) => left.localeCompare(right));
}

function stageSkills(sourceRoots: string[], targetRoot: string) {
  const roots = existingDirectories(sourceRoots);
  const skills = new Map<string, StagedSkill>();

  mkdirSync(targetRoot, { recursive: true });

  for (const root of roots) {
    for (const sourceDir of listDirectories(root)) {
      const name = basename(sourceDir);
      const targetDir = resolve(targetRoot, name);

      if (!existsSync(resolve(sourceDir, "SKILL.md"))) {
        throw new Error(`Expected SKILL.md in ${sourceDir}`);
      }

      replaceDirectory(targetDir, sourceDir);
      skills.set(name, { name, sourceDir });
    }
  }

  return Array.from(skills.values()).sort((left, right) => left.name.localeCompare(right.name));
}

function parseManagedIndex(path: string) {
  if (!existsSync(path) || !statSync(path).isFile()) {
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

function sourceLooksPortable(sourceDir: string) {
  return sourceDir.includes("/home/.ruler/skills/");
}

function installGeneratedSkills(
  generatedRoot: string,
  outputRoot: string,
  stagedSkills: StagedSkill[],
) {
  if (stagedSkills.length === 0) {
    return;
  }

  if (!existsSync(generatedRoot) || !statSync(generatedRoot).isDirectory()) {
    throw new Error(`Ruler did not generate skills at ${generatedRoot}`);
  }

  mkdirSync(outputRoot, { recursive: true });

  const indexPath = resolve(outputRoot, ".dotty-managed-skills.tsv");
  const currentNames = new Set(stagedSkills.map((skill) => skill.name));
  const previousRows = parseManagedIndex(indexPath);
  const rows: ManagedIndexRow[] = [];

  for (const row of previousRows) {
    const skillName = row.skill_name;
    const sourceDir = row.source_dir;
    const targetDir = row.target_dir;

    if (!skillName || !targetDir || currentNames.has(skillName)) {
      continue;
    }

    if (sourceDir && sourceLooksPortable(sourceDir)) {
      rmSync(targetDir, { force: true, recursive: true });
      continue;
    }

    rows.push(row);
  }

  for (const skill of stagedSkills) {
    const generatedDir = resolve(generatedRoot, skill.name);
    const targetDir = resolve(outputRoot, skill.name);

    if (!existsSync(resolve(generatedDir, "SKILL.md"))) {
      throw new Error(`Ruler did not generate expected skill ${skill.name} at ${generatedDir}`);
    }

    replaceDirectory(targetDir, generatedDir);
    rows.push({
      skill_name: skill.name,
      source_dir: skill.sourceDir,
      target_dir: targetDir,
    });
  }

  rows.sort((left, right) => (left.skill_name ?? "").localeCompare(right.skill_name ?? ""));
  writeManagedIndex(indexPath, ["skill_name", "source_dir", "target_dir"], rows);
}

function stageRulerProject(sourcePaths: string[], skillSourcePaths: string[], agents: string[]) {
  const { body, sources } = renderRulerAgentsSource(sourcePaths);
  const stagingRoot = mkdtempSync(join(tmpdir(), "dotty-ruler-"));
  const rulerDir = join(stagingRoot, ".ruler");

  mkdirSync(rulerDir, { recursive: true });
  writeFileSync(join(rulerDir, "AGENTS.md"), body, "utf8");
  const stagedSkills = stageSkills(skillSourcePaths, join(rulerDir, "skills"));
  writeFileSync(
    join(rulerDir, "ruler.toml"),
    [
      `default_agents = [${agents.map((agent) => `"${agent}"`).join(", ")}]`,
      "",
      ...agents.flatMap((agent) => [`[agents.${agent}]`, "enabled = true", ""]),
    ].join("\n"),
    "utf8",
  );

  return { sources, stagedSkills, stagingRoot };
}

function syncCodexAgents(
  outputPath: string,
  sourcePaths: string[],
  validateOnly: boolean,
  rulerBin: string,
) {
  const { sources, stagingRoot } = stageRulerProject(sourcePaths, [], ["codex"]);

  try {
    runRuler(stagingRoot, ["codex"], validateOnly, rulerBin);

    if (validateOnly) {
      return;
    }

    const generatedPath = join(stagingRoot, "AGENTS.md");
    if (!existsSync(generatedPath)) {
      throw new Error(`Ruler did not generate ${generatedPath}`);
    }

    const generatedBody = readFileSync(generatedPath, "utf8");
    writeManagedFile(
      outputPath,
      generatedBody,
      [
        "Generated by dotty from tracked Ruler instruction sources.",
        "Edit one of these source files, then run `dotty update`.",
        ...sources.map((source) => `Source: ${source}`),
      ],
    );
  } finally {
    rmSync(stagingRoot, { force: true, recursive: true });
  }
}

function syncPortable(
  codexAgentsOutput: string,
  claudeOutput: string,
  codexSkillsOutput: string,
  claudeSkillsOutput: string,
  sourcePaths: string[],
  skillSourcePaths: string[],
  validateOnly: boolean,
  rulerBin: string,
) {
  const agents = ["codex", "claude"];
  const { sources, stagedSkills, stagingRoot } = stageRulerProject(sourcePaths, skillSourcePaths, agents);

  try {
    runRuler(stagingRoot, agents, validateOnly, rulerBin);

    if (validateOnly) {
      return;
    }

    const generatedCodexAgents = join(stagingRoot, "AGENTS.md");
    const generatedClaude = join(stagingRoot, "CLAUDE.md");

    if (!existsSync(generatedCodexAgents)) {
      throw new Error(`Ruler did not generate ${generatedCodexAgents}`);
    }

    if (!existsSync(generatedClaude)) {
      throw new Error(`Ruler did not generate ${generatedClaude}`);
    }

    writeManagedFile(codexAgentsOutput, readFileSync(generatedCodexAgents, "utf8"), [
      "Generated by dotty from tracked Ruler instruction sources.",
      "Edit one of these source files, then run `dotty update`.",
      ...sources.map((source) => `Source: ${source}`),
    ]);
    writeManagedFile(claudeOutput, readFileSync(generatedClaude, "utf8"), [
      "Generated by dotty from tracked Ruler instruction sources.",
      "Edit one of these source files, then run `dotty update`.",
      ...sources.map((source) => `Source: ${source}`),
    ]);
    installGeneratedSkills(join(stagingRoot, ".codex", "skills"), codexSkillsOutput, stagedSkills);
    installGeneratedSkills(join(stagingRoot, ".claude", "skills"), claudeSkillsOutput, stagedSkills);
  } finally {
    rmSync(stagingRoot, { force: true, recursive: true });
  }
}

function main() {
  const {
    claudeOutput,
    claudeSkillsOutput,
    codexAgentsOutput,
    codexSkillsOutput,
    mode,
    output,
    rulerBin,
    skillSources,
    sources,
    validateOnly,
  } = parseArgs(process.argv.slice(2));

  if (mode === "codex-agents") {
    syncCodexAgents(output, sources, validateOnly, rulerBin);
    return;
  }

  if (mode === "portable") {
    syncPortable(
      codexAgentsOutput,
      claudeOutput,
      codexSkillsOutput,
      claudeSkillsOutput,
      sources,
      skillSources,
      validateOnly,
      rulerBin,
    );
  }
}

main();
