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

type TokenUsage = {
  cacheWriteInputTokens: number;
  cachedInputTokens: number;
  inputTokens: number;
  outputTokens: number;
  reasoningOutputTokens: number;
  totalTokens: number;
};

const DEFAULT_PATTERN =
  /\b(why did you|why'd you|can we do|could we do|instead|next time|prefer|don't|do not|should have|shouldn't|rather than)\b/i;

function usage(): never {
  console.error(`Usage:
  codex-session-snippets --latest [--query <text>] [--limit <n>] [--usage]
  codex-session-snippets --thread <thread-id> [--query <text>] [--limit <n>] [--usage]`);
  process.exit(2);
}

function valueAfter(argv: string[], index: number): string {
  return argv[index + 1] ?? "";
}

function parseLimit(value: string): number {
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < 1) {
    usage();
  }
  return parsed;
}

export function parseArgs(argv: string[]) {
  let latest = false;
  let threadId = "";
  let query = "";
  let limit = 8;
  let usageOnly = false;

  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    switch (token) {
      case "--latest":
        latest = true;
        break;
      case "--thread":
        threadId = valueAfter(argv, index);
        index += 1;
        break;
      case "--query":
        query = valueAfter(argv, index);
        index += 1;
        break;
      case "--limit":
        limit = parseLimit(valueAfter(argv, index));
        index += 1;
        break;
      case "--usage":
        usageOnly = true;
        break;
      default:
        usage();
    }
  }

  if (latest === (threadId.length > 0)) {
    usage();
  }

  if (usageOnly && query.length > 0) {
    usage();
  }

  return { latest, limit, query, threadId, usage: usageOnly };
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

export function textFromContent(content: unknown): string {
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

export function entryText(entry: RolloutEntry): string {
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

export function entryRole(entry: RolloutEntry): string {
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

function tokenNumber(value: unknown): number | undefined {
  if (typeof value !== "number" || !Number.isFinite(value) || value < 0) {
    return undefined;
  }
  return value;
}

/**
 * This returns cumulative usage from the latest complete Codex token-count event.
 */
export function latestTokenUsage(entries: RolloutEntry[]): TokenUsage | undefined {
  for (const entry of entries.toReversed()) {
    if (entry.type !== "event_msg" || !entry.payload || typeof entry.payload !== "object") {
      continue;
    }

    const payload = entry.payload as Record<string, unknown>;
    if (payload.type !== "token_count" || !payload.info || typeof payload.info !== "object") {
      continue;
    }

    const info = payload.info as Record<string, unknown>;
    if (!info.total_token_usage || typeof info.total_token_usage !== "object") {
      continue;
    }

    const total = info.total_token_usage as Record<string, unknown>;
    const usage = {
      cacheWriteInputTokens: tokenNumber(total.cache_write_input_tokens),
      cachedInputTokens: tokenNumber(total.cached_input_tokens),
      inputTokens: tokenNumber(total.input_tokens),
      outputTokens: tokenNumber(total.output_tokens),
      reasoningOutputTokens: tokenNumber(total.reasoning_output_tokens),
      totalTokens: tokenNumber(total.total_tokens),
    };
    if (Object.values(usage).some((value) => value === undefined)) {
      continue;
    }
    return usage as TokenUsage;
  }

  return undefined;
}

function printTokenUsage(entries: RolloutEntry[]) {
  const tokenUsage = latestTokenUsage(entries);
  if (tokenUsage === undefined) {
    throw new Error("No complete token usage event found in this Codex thread");
  }

  const format = (value: number) => value.toLocaleString("en-US");
  console.log(`input tokens: ${format(tokenUsage.inputTokens)}`);
  console.log(`cached input tokens: ${format(tokenUsage.cachedInputTokens)}`);
  console.log(`cache write input tokens: ${format(tokenUsage.cacheWriteInputTokens)}`);
  console.log(`output tokens: ${format(tokenUsage.outputTokens)}`);
  console.log(`reasoning output tokens: ${format(tokenUsage.reasoningOutputTokens)}`);
  console.log(`total tokens: ${format(tokenUsage.totalTokens)}`);
}

export function truncate(text: string) {
  const normalized = text.replace(/\s+/g, " ").trim();
  if (normalized.length <= 600) {
    return normalized;
  }
  return `${normalized.slice(0, 597)}...`;
}

export function shouldSearch(role: string, text: string, explicitQuery: boolean) {
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
  const matcher =
    args.query.length > 0
      ? new RegExp(args.query.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i")
      : DEFAULT_PATTERN;
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

  if (args.usage) {
    console.log(`thread: ${thread.id}`);
    printTokenUsage(entries);
    return;
  }

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

if (import.meta.main) {
  main();
}
