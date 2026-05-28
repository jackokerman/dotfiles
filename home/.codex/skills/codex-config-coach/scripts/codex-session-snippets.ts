#!/usr/bin/env bun
import { Database } from "bun:sqlite";
import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";

type ThreadRow = {
  created_at: number;
  cwd: string;
  id: string;
  rollout_path: string;
  title: string;
};

type RolloutEntry = {
  payload?: unknown;
  timestamp?: string;
  type?: string;
};

const DEFAULT_PATTERN =
  /\b(why did you|why'd you|can we do|could we do|instead|next time|prefer|don't|do not|should have|shouldn't|rather than)\b/i;

function usage(): never {
  console.error(`Usage:
  bun run scripts/codex-session-snippets.ts --latest [--query <text>] [--limit <n>]
  bun run scripts/codex-session-snippets.ts --thread <thread-id> [--query <text>] [--limit <n>]`);
  process.exit(2);
}

function parseArgs(argv: string[]) {
  let latest = false;
  let threadId = "";
  let query = "";
  let limit = 8;

  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (token === "--latest") {
      latest = true;
      continue;
    }
    if (token === "--thread") {
      threadId = argv[index + 1] ?? "";
      index += 1;
      continue;
    }
    if (token === "--query") {
      query = argv[index + 1] ?? "";
      index += 1;
      continue;
    }
    if (token === "--limit") {
      const parsed = Number(argv[index + 1] ?? "");
      if (!Number.isInteger(parsed) || parsed < 1) {
        usage();
      }
      limit = parsed;
      index += 1;
      continue;
    }
    usage();
  }

  if (latest === (threadId.length > 0)) {
    usage();
  }

  return { latest, limit, query, threadId };
}

function openStateDb() {
  const dbPath = `${homedir()}/.codex/state_5.sqlite`;
  if (!existsSync(dbPath)) {
    throw new Error(`Codex state database not found at ${dbPath}`);
  }

  return new Database(dbPath, { readonly: true });
}

function selectThread(db: Database, latest: boolean, threadId: string): ThreadRow {
  if (latest) {
    const row = db
      .query<ThreadRow, []>(
        "select id, rollout_path, created_at, cwd, title from threads where archived = 0 order by created_at desc limit 1",
      )
      .get();
    if (!row) {
      throw new Error("No Codex threads found");
    }
    return row;
  }

  const row = db
    .query<ThreadRow, [string]>(
      "select id, rollout_path, created_at, cwd, title from threads where id = ? limit 1",
    )
    .get(threadId);
  if (!row) {
    throw new Error(`Codex thread not found: ${threadId}`);
  }
  return row;
}

function textFromContent(content: unknown): string {
  if (typeof content === "string") {
    return content;
  }
  if (!Array.isArray(content)) {
    return "";
  }

  return content
    .map((item) => {
      if (typeof item === "string") {
        return item;
      }
      if (item && typeof item === "object") {
        const maybeText = (item as Record<string, unknown>).text;
        if (typeof maybeText === "string") {
          return maybeText;
        }
      }
      return "";
    })
    .filter(Boolean)
    .join("\n");
}

function entryText(entry: RolloutEntry): string {
  const payload = entry.payload;
  if (!payload || typeof payload !== "object") {
    return "";
  }

  const object = payload as Record<string, unknown>;

  if (entry.type === "event_msg") {
    const message = object.message;
    if (typeof message === "string") {
      return message;
    }
  }

  const contentText = textFromContent(object.content);
  if (contentText.length > 0) {
    return contentText;
  }

  const summaryText = textFromContent(object.summary);
  if (summaryText.length > 0) {
    return summaryText;
  }

  return "";
}

function entryRole(entry: RolloutEntry): string {
  const payload = entry.payload;
  if (!payload || typeof payload !== "object") {
    return "unknown";
  }

  const role = (payload as Record<string, unknown>).role;
  return typeof role === "string" ? role : entry.type ?? "unknown";
}

function readEntries(path: string): RolloutEntry[] {
  if (!existsSync(path)) {
    throw new Error(`Rollout file not found: ${path}`);
  }

  return readFileSync(path, "utf8")
    .split("\n")
    .filter(Boolean)
    .map((line, index) => {
      try {
        return JSON.parse(line) as RolloutEntry;
      } catch (error) {
        throw new Error(`Invalid JSONL at ${path}:${index + 1}: ${error}`);
      }
    });
}

function truncate(text: string) {
  const normalized = text.replace(/\s+/g, " ").trim();
  if (normalized.length <= 600) {
    return normalized;
  }
  return `${normalized.slice(0, 597)}...`;
}

function shouldSearch(role: string, text: string, explicitQuery: boolean) {
  if (role !== "user" && (!explicitQuery || role !== "assistant")) {
    return false;
  }

  if (text.startsWith("# AGENTS.md instructions")) {
    return false;
  }

  return true;
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  const db = openStateDb();
  const thread = selectThread(db, args.latest, args.threadId);
  const entries = readEntries(thread.rollout_path);
  const explicitQuery = args.query.length > 0;
  const matcher = args.query.length > 0 ? new RegExp(args.query.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i") : DEFAULT_PATTERN;
  const matches: Array<{ index: number; role: string; text: string; timestamp?: string }> = [];

  entries.forEach((entry, index) => {
    const text = entryText(entry);
    const role = entryRole(entry);
    if (text.length === 0 || !shouldSearch(role, text, explicitQuery) || !matcher.test(text)) {
      return;
    }
    matches.push({
      index,
      role,
      text: truncate(text),
      timestamp: entry.timestamp,
    });
  });

  console.log(`# ${truncate(thread.title)}`);
  console.log(`thread: ${thread.id}`);
  console.log(`cwd: ${thread.cwd}`);
  console.log(`rollout: ${thread.rollout_path}`);
  console.log("");

  if (matches.length === 0) {
    console.log("No matching correction-style snippets found.");
    return;
  }

  for (const match of matches.slice(0, args.limit)) {
    console.log(`## ${match.timestamp ?? `entry ${match.index + 1}`} (${match.role})`);
    console.log(match.text);
    console.log("");
  }
}

main();
