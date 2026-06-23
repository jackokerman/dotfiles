#!/usr/bin/env bun

import PQueue from "p-queue";

type Scope = "all" | "personal" | "work";
type FolderKey = "personal" | "work";
type FolderStateKey = "inbox" | "nextActions" | "someday";
type GodspeedListType = "folder" | "inbox" | "list" | "smart";
type ApiRequestMethod = "DELETE" | "GET" | "PATCH" | "POST";
type GodspeedRateLimitKind = "read" | "write";

type GodspeedList = {
  archived_at: string | null;
  id: string;
  indent_level: number;
  list_type: GodspeedListType;
  name: string;
  order_index: number;
  smart_list_query: string | null;
};

type GodspeedListsResponse = {
  lists: GodspeedList[];
  success: boolean;
};

type GodspeedListResponse = {
  list: GodspeedList;
  success: boolean;
};

type GodspeedLabel = {
  color_hex_string: string;
  created_at: string;
  deleted_at: string | null;
  id: string;
  name: string;
  updated_at: string;
};

type GodspeedLabelResponse = {
  label: GodspeedLabel;
  success: boolean;
};

type GodspeedLabelsResponse = {
  labels: GodspeedLabel[];
  success: boolean;
};

type GodspeedTask = {
  cleared_at?: string | null;
  completed_at?: string | null;
  created_at: string;
  due_at: string | null;
  duration_minutes: number | null;
  id: string;
  indent_level?: number;
  label_ids: string[];
  list_id: string;
  metadata?: Record<string, unknown>;
  notes: string;
  order_index?: number;
  ordinal?: string | null;
  starts_at: string | null;
  timeless_due_at: string | null;
  timeless_starts_at: string | null;
  title: string;
  updated_at: string;
};

type GodspeedTaskResponse = {
  success: boolean;
  task?: GodspeedTask;
  todo_item?: GodspeedTask;
};

type GodspeedTasksResponse = {
  labels?: GodspeedLabel[];
  lists?: GodspeedList[];
  success: boolean;
  tasks: GodspeedTask[];
};

type GodspeedTodoItemsResponse = {
  success: boolean;
  todo_items: GodspeedTask[];
};

type GodspeedBulkUpdateTasksResponse = {
  success: boolean;
  updated_todo_items: GodspeedTask[];
};

type GodspeedDeleteTaskResponse = {
  success: boolean;
};

type NormalizedLabel = {
  colorHexString: string;
  id: string;
  name: string;
};

type NormalizedList = {
  id: string;
  indentLevel: number;
  listType: GodspeedListType;
  name: string;
  orderIndex: number;
  smartListQuery: string | null;
};

type ResolvedFolderLists = {
  folder: NormalizedList;
  inbox: NormalizedList;
  nextActions: NormalizedList;
  someday: NormalizedList;
  today?: NormalizedList;
};

type DiscoverListsResult = {
  ignored: {
    rootInbox?: NormalizedList;
  };
  personal: ResolvedFolderLists;
  work: ResolvedFolderLists;
};

type LocalEvidenceSignal =
  | "command"
  | "file-extension"
  | "local-path"
  | "machine-state"
  | "repo-keyword";

type NormalizedTask = {
  createdAt: string;
  dueAt: string | null;
  durationMinutes: number | null;
  folder: FolderKey;
  id: string;
  labelIds: string[];
  localEvidenceEligible: boolean;
  localEvidenceSignals: LocalEvidenceSignal[];
  notes: string;
  sourceListId: string;
  sourceListName: string;
  startsAt: string | null;
  state: FolderStateKey;
  timelessDueAt: string | null;
  timelessStartsAt: string | null;
  title: string;
  updatedAt: string;
};

type TaskStateSnapshot = {
  listId: string;
  listName: string;
  tasks: NormalizedTask[];
};

type FolderTaskSnapshot = {
  folderId: string;
  folderName: string;
  states: Record<FolderStateKey, TaskStateSnapshot>;
};

type TaskSnapshot = {
  folders: {
    personal?: FolderTaskSnapshot;
    work?: FolderTaskSnapshot;
  };
  resolvedLists: {
    personal?: ResolvedFolderLists;
    work?: ResolvedFolderLists;
  };
  scope: Scope;
};

type InboxSnapshot = {
  inboxes: {
    personal?: {
      inboxId: string;
      tasks: NormalizedTask[];
    };
    work?: {
      inboxId: string;
      tasks: NormalizedTask[];
    };
  };
  resolvedLists: {
    personal?: ResolvedFolderLists;
    work?: ResolvedFolderLists;
  };
  scope: Scope;
};

type SmartListPlan = {
  folder: {
    id: string;
    key: FolderKey;
    name: string;
  };
  label: {
    exists: boolean;
    id?: string;
    name: string;
  };
  smartList: {
    exists?: boolean;
    id?: string;
    name: string;
    orderIndex?: number;
    query: string;
  };
};

type BulkLabelMatch = {
  alreadyLabeled: boolean;
  folder: FolderKey;
  matchedTerms: string[];
  rationale: string;
  sourceListId: string;
  sourceListName: string;
  state: FolderStateKey;
  taskId: string;
  title: string;
};

type BulkLabelPreview = {
  criteria: {
    contains: string[];
  };
  label: {
    exists: boolean;
    id?: string;
    name: string;
  };
  matches: BulkLabelMatch[];
  scope: Scope;
  skippedAlreadyLabeled: BulkLabelMatch[];
};

type LabelMutationResult = {
  label: NormalizedLabel;
  results: Array<{
    labelIds: string[];
    listId: string;
    taskId: string;
    title: string;
  }>;
};

type TaskCreationPlan = {
  folder: {
    key: FolderKey;
    name: string;
  };
  list: NormalizedList;
  state: {
    key: FolderStateKey;
    name: string;
  };
  task: {
    notes: string;
    timelessDueAt: string | null;
    title: string;
  };
};

type TaskCreationResult = {
  folder: FolderKey;
  labelIds: string[];
  labelNames: string[];
  listId: string;
  listName: string;
  state: FolderStateKey;
  taskId: string;
  timelessDueAt: string | null;
  title: string;
};

type OrderedGodspeedTask = Pick<
  GodspeedTask,
  "id" | "indent_level" | "list_id" | "order_index" | "ordinal" | "title"
>;

type TaskBlockEntry = {
  indentLevel: number;
  taskId: string;
};

type TaskBlockRepositionUpdate = {
  indentLevel: number;
  orderIndex: number;
  ordinal: string;
  taskId: string;
  title: string;
};

type TaskBlockRepositionResult = {
  afterTaskId: string;
  beforeTaskId: string;
  listId: string;
  updates: TaskBlockRepositionUpdate[];
};

type OrdinalValue = {
  fraction: number[];
  whole: number[];
};

type ApiRequestOptions = {
  body?: unknown;
  method?: ApiRequestMethod;
  params?: Record<string, string | undefined>;
};

type ParsedCliArgs = {
  command: string;
  options: Map<string, string[]>;
  positionals: string[];
};

type FolderTaskStateMap = Partial<Record<FolderStateKey, GodspeedTask[]>>;

type RateLimitWindow = {
  intervalCap: number;
  intervalMs: number;
};

type GodspeedQueueSet = {
  hour: PQueue;
  minute: PQueue;
};

class UsageError extends Error {}

const godspeedReadMinuteWindow: RateLimitWindow = {
  intervalCap: 10,
  intervalMs: 60_000,
};

const godspeedReadHourWindow: RateLimitWindow = {
  intervalCap: 200,
  intervalMs: 60 * 60_000,
};

const godspeedWriteMinuteWindow: RateLimitWindow = {
  intervalCap: 60,
  intervalMs: 60_000,
};

const godspeedWriteHourWindow: RateLimitWindow = {
  intervalCap: 1_000,
  intervalMs: 60 * 60_000,
};

const maxGodspeedRequestAttempts = 4;
const maxGodspeedRetryDelayMs = 60_000;
const godspeedApiBaseUrl = "https://api.godspeedapp.com";
const godspeedClientId = crypto.randomUUID();
const ordinalBase = 62;
const orderedBase62Chars = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
const ordinalCharToValueMap = Object.fromEntries(
  orderedBase62Chars.split("").map((character, index) => [character, index]),
) satisfies Record<string, number>;

let cachedListsPromise: Promise<GodspeedList[]> | undefined;
let cachedLabelsPromise: Promise<NormalizedLabel[]> | undefined;

const folderNames = {
  personal: "🏡 Personal",
  work: "🏢 Work",
} satisfies Record<FolderKey, string>;

const folderStateNames = {
  inbox: "📥 Inbox",
  nextActions: "⚡ Next Actions",
  someday: "🌱 Someday",
} satisfies Record<FolderStateKey, string>;

const folderStateOrder: FolderStateKey[] = ["inbox", "nextActions", "someday"];

const readQueues = createQueueSet({
  hour: godspeedReadHourWindow,
  minute: godspeedReadMinuteWindow,
});

const writeQueues = createQueueSet({
  hour: godspeedWriteHourWindow,
  minute: godspeedWriteMinuteWindow,
});

const localEvidenceMatchers: Array<{ regex: RegExp; signal: LocalEvidenceSignal }> = [
  {
    regex: /(?:^|[\s(])(?:~\/|\/|\.\/|\.\.\/)[\w./-]+/im,
    signal: "local-path",
  },
  {
    regex: /\b[\w./-]+\.(?:bash|go|java|js|json|lua|md|py|rb|rs|sh|toml|ts|tsx|txt|ya?ml|zsh)\b/i,
    signal: "file-extension",
  },
  {
    regex:
      /(?:^|[\n`])\s*(?:bash|brew|bun|cat|chmod|find|git|gh|ls|npm|pnpm|rg|sed|sudo|test|tmux|touch|yarn|zsh)\b/im,
    signal: "command",
  },
  {
    regex:
      /\b(?:AGENTS\.md|Brewfile|README\.md|branch|claude code|codex|commit|dotfiles|powerlevel10k|pr|pull request|raycast|repo|repository|tmux|workspace)\b/i,
    signal: "repo-keyword",
  },
  {
    regex: /\b(?:sudo|touch id)\b/i,
    signal: "machine-state",
  },
];

function assertEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(
      `Missing required environment variable: ${name}. Prefer running Bun with --env-file "$HOME/.config/godspeed/tasks.env" or exporting ${name} before invoking godspeed-tasks.`,
    );
  }

  return value;
}

function createQueueSet(windows: { hour: RateLimitWindow; minute: RateLimitWindow }): GodspeedQueueSet {
  return {
    hour: new PQueue({
      concurrency: 1,
      interval: windows.hour.intervalMs,
      intervalCap: windows.hour.intervalCap,
      strict: true,
    }),
    minute: new PQueue({
      concurrency: 1,
      interval: windows.minute.intervalMs,
      intervalCap: windows.minute.intervalCap,
      strict: true,
    }),
  };
}

function sleep(delayMs: number): Promise<void> {
  return new Promise((resolve) => {
    setTimeout(resolve, delayMs);
  });
}

function getApiRequestMethod(options: ApiRequestOptions): ApiRequestMethod {
  return options.method ?? "GET";
}

function getGodspeedRateLimitKind(method: ApiRequestMethod): GodspeedRateLimitKind {
  return method === "GET" ? "read" : "write";
}

function getGodspeedQueues(kind: GodspeedRateLimitKind): GodspeedQueueSet {
  return kind === "read" ? readQueues : writeQueues;
}

async function scheduleGodspeedRequest<T>(
  kind: GodspeedRateLimitKind,
  task: () => Promise<T>,
): Promise<T> {
  const queues = getGodspeedQueues(kind);
  return queues.hour.add(() => queues.minute.add(task));
}

function getExponentialRetryDelayMs(attemptNumber: number): number {
  const rawDelayMs = 1_000 * 2 ** (attemptNumber - 1);
  return Math.min(rawDelayMs, maxGodspeedRetryDelayMs);
}

/**
 * Parses a Godspeed retry delay from the response headers when the server provides one.
 */
export function getGodspeedRetryDelayMs(
  headers: Pick<Headers, "get">,
  now: number = Date.now(),
): number | undefined {
  const retryAfter = headers.get("retry-after");
  if (retryAfter) {
    const retryAfterSeconds = Number(retryAfter);
    if (Number.isFinite(retryAfterSeconds)) {
      return Math.max(0, Math.ceil(retryAfterSeconds * 1000));
    }

    const retryAfterTimestamp = Date.parse(retryAfter);
    if (!Number.isNaN(retryAfterTimestamp)) {
      return Math.max(0, retryAfterTimestamp - now);
    }
  }

  const rateLimitReset = headers.get("ratelimit-reset");
  if (!rateLimitReset) {
    return undefined;
  }

  const resetValue = Number(rateLimitReset);
  if (Number.isFinite(resetValue)) {
    if (resetValue >= 1_000_000_000) {
      return Math.max(0, resetValue * 1000 - now);
    }

    return Math.max(0, Math.ceil(resetValue * 1000));
  }

  const resetTimestamp = Date.parse(rateLimitReset);
  if (!Number.isNaN(resetTimestamp)) {
    return Math.max(0, resetTimestamp - now);
  }

  return undefined;
}

function shouldRetryGodspeedResponse(status: number, attemptNumber: number): boolean {
  return (status === 429 || status === 503) && attemptNumber < maxGodspeedRequestAttempts;
}

function dropLeadingZeroes(values: number[]): number[] {
  let index = 0;
  while (index < values.length && values[index] === 0) {
    index += 1;
  }

  return values.slice(index);
}

function dropTrailingZeroes(values: number[]): number[] {
  let index = values.length - 1;
  while (index >= 0 && values[index] === 0) {
    index -= 1;
  }

  return values.slice(0, index + 1);
}

function fromOrdinalString(value: string): OrdinalValue {
  const [wholePart, fractionPart = ""] = value.split(".");
  return {
    fraction: fractionPart.split("").map((character) => ordinalCharToValueMap[character] ?? 0),
    whole: wholePart.split("").map((character) => ordinalCharToValueMap[character] ?? 0),
  };
}

function fromOrdinalNumber(value: number): OrdinalValue {
  const whole: number[] = [];
  let wholeValue = Math.floor(value);
  while (wholeValue > 0) {
    if (wholeValue < ordinalBase) {
      whole.unshift(wholeValue);
      break;
    }

    whole.unshift(wholeValue % ordinalBase);
    wholeValue = Math.floor(wholeValue / ordinalBase);
  }

  const fraction: number[] = [];
  let fractionalValue = value % 1;
  for (let index = 0; index < 12 && fractionalValue !== 0; index += 1) {
    const shiftedFraction = fractionalValue * ordinalBase;
    const digit = Math.floor(shiftedFraction);
    fractionalValue = shiftedFraction - digit;
    fraction.push(digit);
  }

  return { fraction, whole };
}

function toOrdinalString(value: OrdinalValue): string {
  const whole = dropLeadingZeroes(value.whole)
    .map((digit) => orderedBase62Chars[digit] ?? "0")
    .join("");
  const fraction = dropTrailingZeroes(value.fraction)
    .map((digit) => orderedBase62Chars[digit] ?? "0")
    .join("");

  return whole + (fraction.length === 0 ? "" : `.${fraction}`);
}

function toOrdinalNumber(value: OrdinalValue): number {
  const whole = dropLeadingZeroes(value.whole)
    .reverse()
    .reduce((sum, digit, index) => sum + digit * ordinalBase ** index, 0);
  const fraction = value.fraction.reduce(
    (sum, digit, index) => sum + digit / ordinalBase ** (index + 1),
    0,
  );

  return whole + fraction;
}

function addOrdinalDigits(left: number, right: number): { carry: number; sum: number } {
  const sum = left + right;
  if (sum >= ordinalBase) {
    return {
      carry: 1,
      sum: sum - ordinalBase,
    };
  }

  return {
    carry: 0,
    sum,
  };
}

function addOrdinals(left: OrdinalValue, right: OrdinalValue): OrdinalValue {
  let carry = 0;
  const fraction = Array(Math.max(left.fraction.length, right.fraction.length)).fill(0);
  for (let index = fraction.length - 1; index >= 0; index -= 1) {
    const result = addOrdinalDigits((left.fraction[index] ?? 0) + carry, right.fraction[index] ?? 0);
    fraction[index] = result.sum;
    carry = result.carry;
  }

  const whole = Array(Math.max(left.whole.length, right.whole.length) + 1).fill(0);
  for (let index = 0; index < whole.length - 1; index += 1) {
    const result = addOrdinalDigits((left.whole.at(-1 - index) ?? 0) + carry, right.whole.at(-1 - index) ?? 0);
    whole[whole.length - 1 - index] = result.sum;
    carry = result.carry;
  }

  if (carry !== 0) {
    whole[0] = carry;
  }

  return {
    fraction,
    whole: whole[0] === 0 ? whole.slice(1) : whole,
  };
}

function subtractOrdinalDigits(left: number, right: number): { borrow: number; difference: number } {
  const difference = left - right;
  if (difference < 0) {
    return {
      borrow: 1,
      difference: difference + ordinalBase,
    };
  }

  return {
    borrow: 0,
    difference,
  };
}

function subtractOrdinals(left: OrdinalValue, right: OrdinalValue): OrdinalValue {
  let borrow = 0;
  const fraction = Array(Math.max(left.fraction.length, right.fraction.length)).fill(0);
  for (let index = 0; index < fraction.length; index += 1) {
    const result = subtractOrdinalDigits(
      (left.fraction[fraction.length - 1 - index] ?? 0) - borrow,
      right.fraction[fraction.length - 1 - index] ?? 0,
    );
    fraction[fraction.length - 1 - index] = result.difference;
    borrow = result.borrow;
  }

  const whole = Array(Math.max(left.whole.length, right.whole.length)).fill(0);
  for (let index = 0; index < whole.length; index += 1) {
    const result = subtractOrdinalDigits(
      (left.whole.at(-1 - index) ?? 0) - borrow,
      right.whole.at(-1 - index) ?? 0,
    );
    whole[whole.length - 1 - index] = result.difference;
    borrow = result.borrow;
  }

  if (borrow !== 0) {
    whole[0] -= borrow;
  }

  return { fraction, whole };
}

function shiftOrdinalRadixPointLeft(value: OrdinalValue, distance: number): OrdinalValue {
  const digits = [...value.whole, ...value.fraction];
  const whole = Array(Math.max(value.whole.length - distance, 0)).fill(0);
  const fraction = Array(value.fraction.length + distance).fill(0);

  for (let index = 0; index < whole.length; index += 1) {
    whole[index] = digits[index];
  }

  for (let index = 0; index < fraction.length; index += 1) {
    fraction[fraction.length - 1 - index] = digits[digits.length - 1 - index] ?? 0;
  }

  return { fraction, whole };
}

function multiplyOrdinals(left: OrdinalValue, right: OrdinalValue): OrdinalValue {
  const leftDigits = [...left.whole, ...left.fraction];
  const rightDigits = [...right.whole, ...right.fraction];
  const rowLength = leftDigits.length + rightDigits.length;
  const rows = Array.from({ length: rightDigits.length }, () => Array(rowLength).fill(0));

  for (let rightIndex = 0; rightIndex < rightDigits.length; rightIndex += 1) {
    const rightDigit = rightDigits[rightDigits.length - 1 - rightIndex] ?? 0;
    let carry = 0;
    let leftIndex = 0;

    for (; leftIndex < leftDigits.length; leftIndex += 1) {
      const leftDigit = leftDigits[leftDigits.length - 1 - leftIndex] ?? 0;
      const value = rightDigit * leftDigit + carry;
      rows[rightIndex][rowLength - 1 - leftIndex - rightIndex] = value % ordinalBase;
      carry = Math.floor(value / ordinalBase);
    }

    if (carry > 0) {
      rows[rightIndex][rowLength - 1 - leftIndex - rightIndex] = carry;
    }
  }

  let sum: OrdinalValue = { fraction: [], whole: [] };
  for (const row of rows) {
    sum = addOrdinals(sum, {
      fraction: [],
      whole: row,
    });
  }

  return shiftOrdinalRadixPointLeft(sum, left.fraction.length + right.fraction.length);
}

function compareOrdinals(left: OrdinalValue, right: OrdinalValue): number {
  const wholeLength = Math.max(left.whole.length, right.whole.length);
  for (let index = 0; index < wholeLength; index += 1) {
    const leftDigit = left.whole[index - (wholeLength - left.whole.length)] ?? 0;
    const rightDigit = right.whole[index - (wholeLength - right.whole.length)] ?? 0;
    if (leftDigit !== rightDigit) {
      return leftDigit < rightDigit ? -1 : 1;
    }
  }

  const fractionLength = Math.max(left.fraction.length, right.fraction.length);
  for (let index = 0; index < fractionLength; index += 1) {
    const leftDigit = left.fraction[index] ?? 0;
    const rightDigit = right.fraction[index] ?? 0;
    if (leftDigit !== rightDigit) {
      return leftDigit < rightDigit ? -1 : 1;
    }
  }

  return 0;
}

const defaultOrdinalDistance: OrdinalValue = {
  fraction: [],
  whole: [1, 0, 0],
};

function generateOrdinalsInRange(count: number, start: OrdinalValue | null, end: OrdinalValue | null): OrdinalValue[] {
  if (count === 0) {
    return [];
  }

  if (start === null) {
    return generateOrdinalsInRange(count, { fraction: [], whole: [0] }, end);
  }

  if (end === null) {
    return generateOrdinalsInRange(count, start, addOrdinals(start, multiplyOrdinals(defaultOrdinalDistance, fromOrdinalNumber(count))));
  }

  const difference = subtractOrdinals(end, start);
  const scale = count === 1 ? 1 : Math.ceil(Math.log(count) / Math.log(ordinalBase));
  const shiftedDifference = shiftOrdinalRadixPointLeft(difference, scale);
  const stepScale = Math.floor(ordinalBase ** scale / (count + 1));
  const step = multiplyOrdinals(shiftedDifference, fromOrdinalNumber(stepScale));
  const randomOffset = multiplyOrdinals(
    shiftOrdinalRadixPointLeft(shiftedDifference, 5),
    fromOrdinalNumber(Math.random()),
  );
  const ordinals = Array<OrdinalValue>(count);
  let current = start;

  for (let index = 0; index < ordinals.length; index += 1) {
    current = addOrdinals(current, step);
    ordinals[index] = addOrdinals(current, randomOffset);
  }

  return ordinals;
}

function clearListsCache(): void {
  cachedListsPromise = undefined;
}

function clearLabelsCache(): void {
  cachedLabelsPromise = undefined;
}

function normalizeList(list: GodspeedList): NormalizedList {
  return {
    id: list.id,
    indentLevel: list.indent_level,
    listType: list.list_type,
    name: list.name,
    orderIndex: list.order_index,
    smartListQuery: list.smart_list_query,
  };
}

function normalizeLabel(label: GodspeedLabel): NormalizedLabel {
  return {
    colorHexString: label.color_hex_string,
    id: label.id,
    name: label.name,
  };
}

function sortLists(lists: GodspeedList[]): GodspeedList[] {
  return [...lists].sort((left, right) => left.order_index - right.order_index);
}

function sortLabels(labels: GodspeedLabel[]): GodspeedLabel[] {
  return [...labels].sort((left, right) => left.name.localeCompare(right.name));
}

function canonicalizeListName(name: string): string {
  const firstSpaceIndex = name.indexOf(" ");
  if (firstSpaceIndex === -1) {
    return name;
  }

  const prefix = name.slice(0, firstSpaceIndex);
  if (/[\p{Letter}\p{Number}]/u.test(prefix)) {
    return name;
  }

  return name.slice(firstSpaceIndex + 1);
}

function matchesListName(actualName: string, expectedName: string): boolean {
  return canonicalizeListName(actualName) === canonicalizeListName(expectedName);
}

function selectActiveLists(lists: GodspeedList[]): GodspeedList[] {
  return sortLists(lists.filter((list) => list.archived_at === null));
}

function selectActiveLabels(labels: GodspeedLabel[]): GodspeedLabel[] {
  return sortLabels(labels.filter((label) => label.deleted_at === null));
}

function resolveNamedFolder(lists: GodspeedList[], folder: FolderKey): GodspeedList {
  const matches = lists.filter(
    (list) => list.indent_level === 0 && list.list_type === "folder" && matchesListName(list.name, folderNames[folder]),
  );
  if (matches.length !== 1) {
    throw new Error(`Expected exactly one folder named "${folderNames[folder]}", found ${matches.length}`);
  }

  return matches[0];
}

function collectChildrenByFolder(lists: GodspeedList[]): {
  childrenByFolderId: Map<string, GodspeedList[]>;
  rootInbox?: GodspeedList;
} {
  const childrenByFolderId = new Map<string, GodspeedList[]>();
  let currentFolderId: string | null = null;
  let rootInbox: GodspeedList | undefined;

  for (const list of selectActiveLists(lists)) {
    if (list.indent_level === 0) {
      if (list.list_type === "inbox") {
        rootInbox = list;
        currentFolderId = null;
        continue;
      }

      currentFolderId = list.list_type === "folder" ? list.id : null;
      continue;
    }

    if (list.indent_level === 1) {
      if (!currentFolderId) {
        throw new Error(`Found child list "${list.name}" without a preceding folder`);
      }

      const bucket = childrenByFolderId.get(currentFolderId) ?? [];
      bucket.push(list);
      childrenByFolderId.set(currentFolderId, bucket);
    }
  }

  return { childrenByFolderId, rootInbox };
}

function resolveRequiredChild(
  children: GodspeedList[],
  params: { listType: GodspeedListType; name: string },
): GodspeedList {
  const matches = children.filter(
    (list) => list.list_type === params.listType && matchesListName(list.name, params.name),
  );
  if (matches.length !== 1) {
    throw new Error(
      `Expected exactly one child ${params.listType} list named "${params.name}", found ${matches.length}`,
    );
  }

  return matches[0];
}

function resolveOptionalChild(
  children: GodspeedList[],
  params: { listType: GodspeedListType; name: string },
): GodspeedList | undefined {
  const matches = children.filter(
    (list) => list.list_type === params.listType && matchesListName(list.name, params.name),
  );
  if (matches.length > 1) {
    throw new Error(
      `Expected at most one child ${params.listType} list named "${params.name}", found ${matches.length}`,
    );
  }

  return matches[0];
}

function resolveFolderChildren(lists: GodspeedList[], folder: FolderKey): GodspeedList[] {
  const activeLists = selectActiveLists(lists);
  const folderList = resolveNamedFolder(activeLists, folder);
  const { childrenByFolderId } = collectChildrenByFolder(activeLists);
  return childrenByFolderId.get(folderList.id) ?? [];
}

/**
 * Resolves the mirrored personal and work GTD folders from a flat Godspeed list payload.
 */
export function discoverLists(lists: GodspeedList[]): DiscoverListsResult {
  const activeLists = selectActiveLists(lists);
  const { childrenByFolderId, rootInbox } = collectChildrenByFolder(activeLists);

  function resolveFolderLists(folder: FolderKey): ResolvedFolderLists {
    const folderList = resolveNamedFolder(activeLists, folder);
    const children = childrenByFolderId.get(folderList.id) ?? [];
    const today = resolveOptionalChild(children, { listType: "smart", name: "Today" });

    return {
      folder: normalizeList(folderList),
      inbox: normalizeList(resolveRequiredChild(children, { listType: "list", name: folderStateNames.inbox })),
      nextActions: normalizeList(
        resolveRequiredChild(children, { listType: "list", name: folderStateNames.nextActions }),
      ),
      someday: normalizeList(resolveRequiredChild(children, { listType: "list", name: folderStateNames.someday })),
      today: today ? normalizeList(today) : undefined,
    };
  }

  return {
    ignored: {
      rootInbox: rootInbox ? normalizeList(rootInbox) : undefined,
    },
    personal: resolveFolderLists("personal"),
    work: resolveFolderLists("work"),
  };
}

function dedupeSignals(signals: LocalEvidenceSignal[]): LocalEvidenceSignal[] {
  return [...new Set(signals)];
}

/**
 * Extracts quick local-evidence hints from a task title and notes.
 */
export function getLocalEvidenceSignals(task: Pick<GodspeedTask, "notes" | "title">): LocalEvidenceSignal[] {
  const haystack = `${task.title}\n${task.notes}`;
  return dedupeSignals(
    localEvidenceMatchers.flatMap((matcher) => (matcher.regex.test(haystack) ? [matcher.signal] : [])),
  );
}

/**
 * Returns whether a task looks easy to verify from local machine state or repo context.
 */
export function isLocallyVerifiableTask(task: Pick<GodspeedTask, "notes" | "title">): boolean {
  return getLocalEvidenceSignals(task).length > 0;
}

function sortTasks(tasks: GodspeedTask[]): GodspeedTask[] {
  return [...tasks].sort((left, right) => left.created_at.localeCompare(right.created_at));
}

function sortNormalizedTasks(tasks: NormalizedTask[]): NormalizedTask[] {
  return [...tasks].sort((left, right) => {
    const createdAtCompare = left.createdAt.localeCompare(right.createdAt);
    if (createdAtCompare !== 0) {
      return createdAtCompare;
    }

    return left.title.localeCompare(right.title);
  });
}

function normalizeTask(params: {
  folder: FolderKey;
  sourceList: NormalizedList;
  state: FolderStateKey;
  task: GodspeedTask;
}): NormalizedTask {
  const localEvidenceSignals = getLocalEvidenceSignals(params.task);

  return {
    createdAt: params.task.created_at,
    dueAt: params.task.due_at,
    durationMinutes: params.task.duration_minutes,
    folder: params.folder,
    id: params.task.id,
    labelIds: params.task.label_ids,
    localEvidenceEligible: localEvidenceSignals.length > 0,
    localEvidenceSignals,
    notes: params.task.notes,
    sourceListId: params.sourceList.id,
    sourceListName: params.sourceList.name,
    startsAt: params.task.starts_at,
    state: params.state,
    timelessDueAt: params.task.timeless_due_at,
    timelessStartsAt: params.task.timeless_starts_at,
    title: params.task.title,
    updatedAt: params.task.updated_at,
  };
}

function getFolderStateList(resolvedLists: ResolvedFolderLists, state: FolderStateKey): NormalizedList {
  if (state === "inbox") {
    return resolvedLists.inbox;
  }

  if (state === "nextActions") {
    return resolvedLists.nextActions;
  }

  return resolvedLists.someday;
}

function validateTimelessDate(value: string | undefined): string | undefined {
  if (value === undefined) {
    return undefined;
  }

  const trimmedValue = value.trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(trimmedValue)) {
    throw new UsageError(
      `Timeless due date must be a valid calendar date in YYYY-MM-DD format. Received: ${value}`,
    );
  }

  const parsedDate = new Date(`${trimmedValue}T00:00:00.000Z`);
  if (Number.isNaN(parsedDate.valueOf()) || parsedDate.toISOString().slice(0, 10) !== trimmedValue) {
    throw new UsageError(
      `Timeless due date must be a valid calendar date in YYYY-MM-DD format. Received: ${value}`,
    );
  }

  return trimmedValue;
}

/**
 * Resolves the destination list and normalized fields for a new task.
 */
export function buildTaskCreationPlan(params: {
  folder: FolderKey;
  notes?: string;
  resolvedLists: DiscoverListsResult;
  state: FolderStateKey;
  timelessDueAt?: string;
  title: string;
}): TaskCreationPlan {
  const title = params.title.trim();
  if (!title) {
    throw new UsageError("Task title cannot be empty");
  }

  const folderLists = params.folder === "personal" ? params.resolvedLists.personal : params.resolvedLists.work;
  const list = getFolderStateList(folderLists, params.state);

  return {
    folder: {
      key: params.folder,
      name: folderNames[params.folder],
    },
    list,
    state: {
      key: params.state,
      name: folderStateNames[params.state],
    },
    task: {
      notes: params.notes?.trim() ?? "",
      timelessDueAt: validateTimelessDate(params.timelessDueAt) ?? null,
      title,
    },
  };
}

function buildFolderTaskSnapshot(params: {
  folder: FolderKey;
  resolvedLists: ResolvedFolderLists;
  tasksByState?: FolderTaskStateMap;
}): FolderTaskSnapshot {
  const states = folderStateOrder.reduce<Record<FolderStateKey, TaskStateSnapshot>>((accumulator, state) => {
    const sourceList = getFolderStateList(params.resolvedLists, state);
    const tasks = sortTasks(params.tasksByState?.[state] ?? []).map((task) =>
      normalizeTask({
        folder: params.folder,
        sourceList,
        state,
        task,
      }),
    );

    accumulator[state] = {
      listId: sourceList.id,
      listName: sourceList.name,
      tasks,
    };

    return accumulator;
  }, {} as Record<FolderStateKey, TaskStateSnapshot>);

  return {
    folderId: params.resolvedLists.folder.id,
    folderName: params.resolvedLists.folder.name,
    states,
  };
}

/**
 * Builds a normalized scoped snapshot across the GTD state lists under personal and work.
 */
export function buildTaskSnapshot(params: {
  personalTasksByState?: FolderTaskStateMap;
  resolvedLists: DiscoverListsResult;
  scope: Scope;
  workTasksByState?: FolderTaskStateMap;
}): TaskSnapshot {
  const snapshot: TaskSnapshot = {
    folders: {},
    resolvedLists: {},
    scope: params.scope,
  };

  if (params.scope === "all" || params.scope === "work") {
    snapshot.resolvedLists.work = params.resolvedLists.work;
    snapshot.folders.work = buildFolderTaskSnapshot({
      folder: "work",
      resolvedLists: params.resolvedLists.work,
      tasksByState: params.workTasksByState,
    });
  }

  if (params.scope === "all" || params.scope === "personal") {
    snapshot.resolvedLists.personal = params.resolvedLists.personal;
    snapshot.folders.personal = buildFolderTaskSnapshot({
      folder: "personal",
      resolvedLists: params.resolvedLists.personal,
      tasksByState: params.personalTasksByState,
    });
  }

  return snapshot;
}

/**
 * Builds the legacy inbox-only view used by the inbox triage workflow.
 */
export function buildInboxSnapshot(params: {
  personalTasks?: GodspeedTask[];
  resolvedLists: DiscoverListsResult;
  scope: Scope;
  workTasks?: GodspeedTask[];
}): InboxSnapshot {
  const taskSnapshot = buildTaskSnapshot({
    personalTasksByState: params.personalTasks ? { inbox: params.personalTasks } : undefined,
    resolvedLists: params.resolvedLists,
    scope: params.scope,
    workTasksByState: params.workTasks ? { inbox: params.workTasks } : undefined,
  });

  const snapshot: InboxSnapshot = {
    inboxes: {},
    resolvedLists: taskSnapshot.resolvedLists,
    scope: params.scope,
  };

  if (taskSnapshot.folders.work) {
    snapshot.inboxes.work = {
      inboxId: taskSnapshot.folders.work.states.inbox.listId,
      tasks: taskSnapshot.folders.work.states.inbox.tasks,
    };
  }

  if (taskSnapshot.folders.personal) {
    snapshot.inboxes.personal = {
      inboxId: taskSnapshot.folders.personal.states.inbox.listId,
      tasks: taskSnapshot.folders.personal.states.inbox.tasks,
    };
  }

  return snapshot;
}

function escapeSmartListValue(value: string): string {
  return value.replaceAll("\\", "\\\\").replaceAll('"', '\\"');
}

/**
 * Generates a generic smart-list definition for a runtime label within one top-level folder.
 */
export function buildSmartListPlan(params: {
  folder: FolderKey;
  labelId?: string;
  labelName: string;
  existingSmartList?: { id: string; orderIndex: number };
  orderIndex?: number;
  resolvedLists: DiscoverListsResult;
  smartListName?: string;
}): SmartListPlan {
  const folderLists = params.folder === "personal" ? params.resolvedLists.personal : params.resolvedLists.work;
  const labelName = params.labelName.trim();

  if (!labelName) {
    throw new Error("Label name cannot be empty");
  }

  return {
    folder: {
      id: folderLists.folder.id,
      key: params.folder,
      name: folderLists.folder.name,
    },
    label: {
      exists: params.labelId !== undefined,
      id: params.labelId,
      name: labelName,
    },
    smartList: {
      exists: params.existingSmartList !== undefined,
      id: params.existingSmartList?.id,
      name: params.smartListName?.trim() || labelName,
      orderIndex: params.existingSmartList?.orderIndex ?? params.orderIndex,
      query: `folder:"${escapeSmartListValue(folderLists.folder.id)}" label:"${escapeSmartListValue(labelName)}"`,
    },
  };
}

function normalizeContainsTerms(terms: string[]): string[] {
  const normalizedTerms = terms.map((term) => term.trim().toLowerCase()).filter((term) => term.length > 0);
  return [...new Set(normalizedTerms)];
}

function matchTaskContainsTerms(task: NormalizedTask, contains: string[]): string[] {
  const haystack = `${task.title}\n${task.notes}`.toLowerCase();
  return contains.filter((term) => haystack.includes(term));
}

function compareFolderKeys(left: FolderKey, right: FolderKey): number {
  const order: Record<FolderKey, number> = { personal: 0, work: 1 };
  return order[left] - order[right];
}

function compareFolderStateKeys(left: FolderStateKey, right: FolderStateKey): number {
  const order: Record<FolderStateKey, number> = { inbox: 0, nextActions: 1, someday: 2 };
  return order[left] - order[right];
}

/**
 * Builds a non-mutating bulk-label preview from runtime matching terms and a scoped task snapshot.
 */
export function buildBulkLabelPreview(params: {
  contains: string[];
  labelId?: string;
  labelName: string;
  scope: Scope;
  snapshot: TaskSnapshot;
}): BulkLabelPreview {
  const contains = normalizeContainsTerms(params.contains);
  if (contains.length === 0) {
    throw new Error("At least one non-empty --contains term is required");
  }

  const matches: BulkLabelMatch[] = [];
  const skippedAlreadyLabeled: BulkLabelMatch[] = [];

  for (const folderKey of ["personal", "work"] as const) {
    const folder = params.snapshot.folders[folderKey];
    if (!folder) {
      continue;
    }

    for (const state of folderStateOrder) {
      for (const task of folder.states[state].tasks) {
        const matchedTerms = matchTaskContainsTerms(task, contains);
        if (matchedTerms.length === 0) {
          continue;
        }

        const alreadyLabeled = params.labelId !== undefined && task.labelIds.includes(params.labelId);
        const match: BulkLabelMatch = {
          alreadyLabeled,
          folder: folderKey,
          matchedTerms,
          rationale: `Matched term${matchedTerms.length === 1 ? "" : "s"}: ${matchedTerms.join(", ")}`,
          sourceListId: task.sourceListId,
          sourceListName: task.sourceListName,
          state,
          taskId: task.id,
          title: task.title,
        };

        if (alreadyLabeled) {
          skippedAlreadyLabeled.push(match);
          continue;
        }

        matches.push(match);
      }
    }
  }

  const sortMatches = (entries: BulkLabelMatch[]): BulkLabelMatch[] =>
    [...entries].sort((left, right) => {
      const folderCompare = compareFolderKeys(left.folder, right.folder);
      if (folderCompare !== 0) {
        return folderCompare;
      }

      const stateCompare = compareFolderStateKeys(left.state, right.state);
      if (stateCompare !== 0) {
        return stateCompare;
      }

      return left.title.localeCompare(right.title);
    });

  return {
    criteria: {
      contains,
    },
    label: {
      exists: params.labelId !== undefined,
      id: params.labelId,
      name: params.labelName.trim(),
    },
    matches: sortMatches(matches),
    scope: params.scope,
    skippedAlreadyLabeled: sortMatches(skippedAlreadyLabeled),
  };
}

async function fetchJson<T>(path: string, options: ApiRequestOptions = {}): Promise<T> {
  const token = assertEnv("GODSPEED_API_TOKEN");
  const url = new URL(`${godspeedApiBaseUrl}${path}`);
  for (const [key, value] of Object.entries(options.params ?? {})) {
    if (value !== undefined) {
      url.searchParams.set(key, value);
    }
  }

  const method = getApiRequestMethod(options);
  const rateLimitKind = getGodspeedRateLimitKind(method);

  for (let attemptNumber = 1; attemptNumber <= maxGodspeedRequestAttempts; attemptNumber += 1) {
    const response = await scheduleGodspeedRequest(rateLimitKind, () =>
      fetch(url, {
        body: options.body === undefined ? undefined : JSON.stringify(options.body),
        headers: {
          Authorization: `Bearer ${token}`,
          ...(options.body === undefined ? {} : { "Content-Type": "application/json" }),
        },
        method,
      }),
    );

    if (response.ok) {
      return (await response.json()) as T;
    }

    const body = await response.text();
    if (shouldRetryGodspeedResponse(response.status, attemptNumber)) {
      const retryDelayMs =
        getGodspeedRetryDelayMs(response.headers) ?? getExponentialRetryDelayMs(attemptNumber);
      await sleep(retryDelayMs);
      continue;
    }

    throw new Error(`Godspeed API request failed: ${response.status} ${response.statusText} for ${url}\n${body}`);
  }

  throw new Error(`Godspeed API request exhausted retries for ${url}`);
}

function extractTaskFromResponse(response: GodspeedTaskResponse, context: string): GodspeedTask {
  if (!response.success) {
    throw new Error(`Godspeed API reported an unsuccessful task response for ${context}`);
  }

  const task = response.task ?? response.todo_item;
  if (!task) {
    throw new Error(`Godspeed API returned a task response without task data for ${context}`);
  }

  return task;
}

function normalizeOrderedTask(task: GodspeedTask): OrderedGodspeedTask {
  if (task.indent_level === undefined) {
    throw new Error(`Task ${task.id} is missing indent_level`);
  }

  if (task.order_index === undefined) {
    throw new Error(`Task ${task.id} is missing order_index`);
  }

  if (!task.ordinal) {
    throw new Error(`Task ${task.id} is missing ordinal`);
  }

  return {
    id: task.id,
    indent_level: task.indent_level,
    list_id: task.list_id,
    order_index: task.order_index,
    ordinal: task.ordinal,
    title: task.title,
  };
}

function compareOrdinalStrings(left: string, right: string): number {
  return compareOrdinals(fromOrdinalString(left), fromOrdinalString(right));
}

/**
 * Builds a deterministic reposition plan for a contiguous task block between two existing tasks.
 */
export function buildTaskBlockRepositionPlan(params: {
  afterTask: OrderedGodspeedTask;
  beforeTask: OrderedGodspeedTask;
  entries: TaskBlockEntry[];
  tasks: OrderedGodspeedTask[];
}): TaskBlockRepositionResult {
  if (params.entries.length === 0) {
    throw new UsageError("At least one task entry is required to reposition a task block");
  }

  if (params.afterTask.id === params.beforeTask.id) {
    throw new UsageError("The after and before boundary tasks must be different");
  }

  if (params.afterTask.list_id !== params.beforeTask.list_id) {
    throw new UsageError("The after and before boundary tasks must belong to the same list");
  }

  if (compareOrdinalStrings(params.afterTask.ordinal, params.beforeTask.ordinal) !== -1) {
    throw new UsageError("The after boundary task must appear before the before boundary task");
  }

  const boundaryTaskIds = new Set([params.afterTask.id, params.beforeTask.id]);
  const tasksById = new Map(params.tasks.map((task) => [task.id, task]));
  const ordinals = generateOrdinalsInRange(
    params.entries.length,
    fromOrdinalString(params.afterTask.ordinal),
    fromOrdinalString(params.beforeTask.ordinal),
  );

  return {
    afterTaskId: params.afterTask.id,
    beforeTaskId: params.beforeTask.id,
    listId: params.afterTask.list_id,
    updates: params.entries.map((entry, index) => {
      if (boundaryTaskIds.has(entry.taskId)) {
        throw new UsageError("Task block entries cannot include the after or before boundary task");
      }

      const task = tasksById.get(entry.taskId);
      if (!task) {
        throw new UsageError(`Task ${entry.taskId} was not returned by the Godspeed API`);
      }

      if (task.list_id !== params.afterTask.list_id) {
        throw new UsageError(`Task ${entry.taskId} is not in the same list as the boundary tasks`);
      }

      return {
        indentLevel: entry.indentLevel,
        orderIndex: toOrdinalNumber(ordinals[index]),
        ordinal: toOrdinalString(ordinals[index]),
        taskId: task.id,
        title: task.title,
      };
    }),
  };
}

async function loadResolvedLists(): Promise<DiscoverListsResult> {
  return discoverLists(await loadLists());
}

async function loadLists(): Promise<GodspeedList[]> {
  if (!cachedListsPromise) {
    cachedListsPromise = (async () => {
      const response = await fetchJson<GodspeedListsResponse>("/lists");
      if (!response.success) {
        throw new Error("Godspeed API reported an unsuccessful list response");
      }

      return response.lists;
    })().catch((error) => {
      clearListsCache();
      throw error;
    });
  }

  return cachedListsPromise;
}

async function loadLabels(): Promise<NormalizedLabel[]> {
  if (!cachedLabelsPromise) {
    cachedLabelsPromise = (async () => {
      const response = await fetchJson<GodspeedLabelsResponse>("/labels");
      if (!response.success) {
        throw new Error("Godspeed API reported an unsuccessful label response");
      }

      return selectActiveLabels(response.labels).map(normalizeLabel);
    })().catch((error) => {
      clearLabelsCache();
      throw error;
    });
  }

  return cachedLabelsPromise;
}

async function loadIncompleteTasks(listId: string): Promise<GodspeedTask[]> {
  const response = await fetchJson<GodspeedTasksResponse>("/tasks", {
    params: {
      list_id: listId,
      status: "incomplete",
    },
  });

  if (!response.success) {
    throw new Error("Godspeed API reported an unsuccessful task response");
  }

  return response.tasks;
}

async function createList(body: Record<string, unknown>): Promise<GodspeedList> {
  const response = await fetchJson<GodspeedListResponse>("/lists", {
    body,
    method: "POST",
  });

  if (!response.success) {
    throw new Error("Godspeed API reported an unsuccessful list creation response");
  }

  clearListsCache();
  return response.list;
}

async function createTask(body: Record<string, unknown>): Promise<GodspeedTask> {
  const response = await fetchJson<GodspeedTaskResponse>("/tasks", {
    body,
    method: "POST",
  });

  return extractTaskFromResponse(response, "task creation");
}

async function patchTask(taskId: string, body: Record<string, unknown>): Promise<GodspeedTask> {
  const response = await fetchJson<GodspeedTaskResponse>(`/tasks/${taskId}`, {
    body,
    method: "PATCH",
  });

  return extractTaskFromResponse(response, `task update for ${taskId}`);
}

async function loadTaskById(taskId: string): Promise<GodspeedTask> {
  const response = await fetchJson<GodspeedTaskResponse>(`/tasks/${taskId}`);
  return extractTaskFromResponse(response, `task lookup for ${taskId}`);
}

async function loadTasksByIds(taskIds: string[]): Promise<GodspeedTask[]> {
  const uniqueTaskIds = [...new Set(taskIds)];
  if (uniqueTaskIds.length === 0) {
    return [];
  }

  const response = await fetchJson<GodspeedTodoItemsResponse>("/todo_items/with_ids", {
    params: {
      item_ids: uniqueTaskIds.join(","),
    },
  });

  if (!response.success) {
    throw new Error("Godspeed API reported an unsuccessful bulk task lookup response");
  }

  return response.todo_items;
}

async function deleteTaskById(taskId: string): Promise<void> {
  const response = await fetchJson<GodspeedDeleteTaskResponse>(`/tasks/${taskId}`, {
    method: "DELETE",
  });

  if (!response.success) {
    throw new Error(`Godspeed API reported an unsuccessful task deletion for ${taskId}`);
  }
}

async function bulkUpdateTasks(
  updates: Array<{ taskId: string; updateBody: Record<string, unknown> }>,
): Promise<GodspeedTask[]> {
  if (updates.length === 0) {
    return [];
  }

  const response = await fetchJson<GodspeedBulkUpdateTasksResponse>("/todo_items/bulk_update", {
    body: {
      client_id: godspeedClientId,
      update_bodies: updates.map(({ taskId, updateBody }) => ({
        todo_item_id: taskId,
        update_body: updateBody,
      })),
    },
    method: "POST",
  });

  if (!response.success) {
    throw new Error("Godspeed API reported an unsuccessful bulk task update response");
  }

  return response.updated_todo_items;
}

function findLabelByName(labels: NormalizedLabel[], name: string): NormalizedLabel | undefined {
  const exactMatches = labels.filter((label) => label.name === name);
  if (exactMatches.length > 1) {
    throw new Error(`Found multiple labels named "${name}"`);
  }

  if (exactMatches.length === 1) {
    return exactMatches[0];
  }

  const caseInsensitiveMatches = labels.filter((label) => label.name.toLowerCase() === name.toLowerCase());
  if (caseInsensitiveMatches.length > 1) {
    throw new Error(`Found multiple labels matching "${name}" case-insensitively`);
  }

  return caseInsensitiveMatches[0];
}

function validateLabelColor(color: string): string {
  if (!/^#[0-9a-fA-F]{6}$/.test(color)) {
    throw new UsageError(`Label color must be a hex string like #2563eb. Received: ${color}`);
  }

  return color;
}

function normalizeLabelNames(labelNames: string[]): string[] {
  const dedupedLabelNames = new Map<string, string>();

  for (const labelName of labelNames) {
    const trimmedLabelName = labelName.trim();
    if (!trimmedLabelName) {
      continue;
    }

    const normalizedKey = trimmedLabelName.toLowerCase();
    if (!dedupedLabelNames.has(normalizedKey)) {
      dedupedLabelNames.set(normalizedKey, trimmedLabelName);
    }
  }

  return [...dedupedLabelNames.values()];
}

async function ensureLabel(params: {
  color?: string;
  name: string;
}): Promise<{ created: boolean; label: NormalizedLabel }> {
  const labels = await loadLabels();
  const existingLabel = findLabelByName(labels, params.name);
  if (existingLabel) {
    return {
      created: false,
      label: existingLabel,
    };
  }

  const response = await fetchJson<GodspeedLabelResponse>("/labels", {
    body: {
      color_hex_string: validateLabelColor(params.color ?? "#2563eb"),
      id: crypto.randomUUID(),
      name: params.name,
    },
    method: "POST",
  });

  if (!response.success) {
    throw new Error(`Godspeed API reported an unsuccessful label creation for "${params.name}"`);
  }

  clearLabelsCache();
  return {
    created: true,
    label: normalizeLabel(response.label),
  };
}

function findSmartListByName(lists: GodspeedList[], name: string): GodspeedList | undefined {
  const matches = selectActiveLists(lists).filter((list) => list.list_type === "smart" && list.name === name);
  if (matches.length > 1) {
    throw new Error(`Found multiple smart lists named "${name}"`);
  }

  return matches[0];
}

function computeSmartListOrderIndex(children: GodspeedList[]): number {
  const orderedChildren = sortLists(children);
  const today = resolveOptionalChild(orderedChildren, {
    listType: "smart",
    name: "Today",
  });
  if (today) {
    const nextSibling = orderedChildren.find((list) => list.order_index > today.order_index);
    if (nextSibling) {
      return (today.order_index + nextSibling.order_index) / 2;
    }

    return today.order_index + 1;
  }

  if (orderedChildren.length >= 2) {
    return (orderedChildren[0].order_index + orderedChildren[1].order_index) / 2;
  }

  if (orderedChildren.length === 1) {
    return orderedChildren[0].order_index + 1;
  }

  return 1;
}

async function ensureSmartList(params: {
  folder: FolderKey;
  labelName: string;
  smartListName?: string;
}): Promise<{ created: boolean; smartList: SmartListPlan["smartList"] }> {
  const lists = await loadLists();
  const resolvedLists = discoverLists(lists);
  const smartListName = params.smartListName?.trim() || params.labelName.trim();
  const existingSmartList = findSmartListByName(lists, smartListName);
  const labels = await loadLabels();
  const existingLabel = findLabelByName(labels, params.labelName);
  const folderChildren = resolveFolderChildren(lists, params.folder);

  if (existingSmartList) {
    const plan = buildSmartListPlan({
      existingSmartList: {
        id: existingSmartList.id,
        orderIndex: existingSmartList.order_index,
      },
      folder: params.folder,
      labelId: existingLabel?.id,
      labelName: params.labelName,
      resolvedLists,
      smartListName,
    });

    return {
      created: false,
      smartList: plan.smartList,
    };
  }

  const plan = buildSmartListPlan({
    folder: params.folder,
    labelId: existingLabel?.id,
    labelName: params.labelName,
    orderIndex: computeSmartListOrderIndex(folderChildren),
    resolvedLists,
    smartListName,
  });

  const createdList = await createList({
    id: crypto.randomUUID(),
    indent_level: 1,
    list_type: "smart",
    name: plan.smartList.name,
    order_index: plan.smartList.orderIndex,
    smart_list_query: plan.smartList.query,
  });

  return {
    created: true,
    smartList: {
      ...plan.smartList,
      exists: true,
      id: createdList.id,
      orderIndex: createdList.order_index,
    },
  };
}

async function createScopedTask(params: {
  folder: FolderKey;
  labelNames: string[];
  notes?: string;
  state: FolderStateKey;
  timelessDueAt?: string;
  title: string;
}): Promise<TaskCreationResult> {
  const resolvedLists = await loadResolvedLists();
  const plan = buildTaskCreationPlan({
    folder: params.folder,
    notes: params.notes,
    resolvedLists,
    state: params.state,
    timelessDueAt: params.timelessDueAt,
    title: params.title,
  });
  const knownLabels = await loadLabels();
  const normalizedLabelNames = normalizeLabelNames(params.labelNames);
  const resolvedLabels = await Promise.all(
    normalizedLabelNames.map(async (labelName) => {
      const existingLabel = findLabelByName(knownLabels, labelName);
      if (existingLabel) {
        return existingLabel;
      }

      return (await ensureLabel({ name: labelName })).label;
    }),
  );
  const task = await createTask({
    id: crypto.randomUUID(),
    label_ids: resolvedLabels.map((label) => label.id),
    list_id: plan.list.id,
    notes: plan.task.notes,
    timeless_due_at: plan.task.timelessDueAt,
    title: plan.task.title,
  });

  return {
    folder: plan.folder.key,
    labelIds: task.label_ids,
    labelNames: resolvedLabels.map((label) => label.name),
    listId: task.list_id,
    listName: plan.list.name,
    state: plan.state.key,
    taskId: task.id,
    timelessDueAt: task.timeless_due_at,
    title: task.title,
  };
}

async function loadScopeTasks(
  resolvedLists: DiscoverListsResult,
  scope: Scope,
): Promise<{ personalTasksByState?: FolderTaskStateMap; workTasksByState?: FolderTaskStateMap }> {
  const loadFolder = async (folder: FolderKey): Promise<FolderTaskStateMap> => {
    const folderLists = folder === "personal" ? resolvedLists.personal : resolvedLists.work;
    const [inbox, nextActions, someday] = await Promise.all([
      loadIncompleteTasks(folderLists.inbox.id),
      loadIncompleteTasks(folderLists.nextActions.id),
      loadIncompleteTasks(folderLists.someday.id),
    ]);

    return {
      inbox,
      nextActions,
      someday,
    };
  };

  const [workTasksByState, personalTasksByState] = await Promise.all([
    scope === "all" || scope === "work" ? loadFolder("work") : Promise.resolve(undefined),
    scope === "all" || scope === "personal" ? loadFolder("personal") : Promise.resolve(undefined),
  ]);

  return {
    personalTasksByState,
    workTasksByState,
  };
}

async function applyLabelToTaskIds(params: {
  createIfMissing: boolean;
  labelName: string;
  remove?: boolean;
  taskIds: string[];
}): Promise<LabelMutationResult> {
  if (params.taskIds.length === 0) {
    throw new UsageError("At least one --task-id is required");
  }

  const labels = await loadLabels();
  let label = findLabelByName(labels, params.labelName);

  if (!label) {
    if (params.remove) {
      return {
        label: {
          colorHexString: "",
          id: "",
          name: params.labelName,
        },
        results: [],
      };
    }

    if (!params.createIfMissing) {
      throw new Error(`Label "${params.labelName}" does not exist`);
    }

    label = (await ensureLabel({ name: params.labelName })).label;
  }

  const taskBody = params.remove
    ? { remove_label_ids: [label.id] }
    : {
        add_label_ids: [label.id],
      };
  const results = await Promise.all(
    params.taskIds.map(async (taskId) => {
      const task = await patchTask(taskId, taskBody);
      return {
        labelIds: task.label_ids,
        listId: task.list_id,
        taskId: task.id,
        title: task.title,
      };
    }),
  );

  return {
    label,
    results,
  };
}

function parseNonNegativeInteger(value: string, context: string): number {
  const parsedValue = Number(value);
  if (!Number.isInteger(parsedValue) || parsedValue < 0) {
    throw new UsageError(`${context} must be a non-negative integer. Received: ${value}`);
  }

  return parsedValue;
}

function parseTaskBlockEntry(value: string): TaskBlockEntry {
  const separatorIndex = value.lastIndexOf(":");
  if (separatorIndex <= 0 || separatorIndex === value.length - 1) {
    throw new UsageError(`Task block entries must look like <task-id>:<indent-level>. Received: ${value}`);
  }

  return {
    indentLevel: parseNonNegativeInteger(
      value.slice(separatorIndex + 1),
      `Indent level for task ${value.slice(0, separatorIndex)}`,
    ),
    taskId: value.slice(0, separatorIndex),
  };
}

function parseTaskBlockEntries(values: string[]): TaskBlockEntry[] {
  if (values.length === 0) {
    throw new UsageError("At least one --task entry is required");
  }

  const entries = values.map(parseTaskBlockEntry);
  const uniqueTaskIds = new Set(entries.map((entry) => entry.taskId));
  if (uniqueTaskIds.size !== entries.length) {
    throw new UsageError("Duplicate task ids are not allowed in --task entries");
  }

  return entries;
}

function buildTaskPatchBody(options: Map<string, string[]>): Record<string, unknown> {
  const body: Record<string, unknown> = {};
  const title = getOption(options, "title");
  if (title !== undefined) {
    const trimmedTitle = title.trim();
    if (trimmedTitle.length === 0) {
      throw new UsageError("--title cannot be empty");
    }

    body.title = trimmedTitle;
  }

  const notes = getOption(options, "notes");
  if (notes !== undefined) {
    body.notes = notes.trim();
  }

  const listId = getOption(options, "list-id");
  if (listId !== undefined) {
    body.list_id = listId;
  }

  const due = getOption(options, "due");
  if (due !== undefined) {
    if (due === "none") {
      body.due_at = null;
      body.timeless_due_at = null;
    } else {
      body.timeless_due_at = validateTimelessDate(due) ?? null;
    }
  }

  if (Object.keys(body).length === 0) {
    throw new UsageError("update-task requires at least one of --title, --notes, --list-id, or --due");
  }

  return body;
}

async function repositionTaskBlock(params: {
  afterTaskId: string;
  beforeTaskId: string;
  entries: TaskBlockEntry[];
}): Promise<TaskBlockRepositionResult> {
  const tasks = await loadTasksByIds([
    params.afterTaskId,
    params.beforeTaskId,
    ...params.entries.map((entry) => entry.taskId),
  ]);
  const tasksById = new Map(tasks.map((task) => [task.id, normalizeOrderedTask(task)]));
  const afterTask = tasksById.get(params.afterTaskId);
  const beforeTask = tasksById.get(params.beforeTaskId);

  if (!afterTask) {
    throw new UsageError(`Task ${params.afterTaskId} was not returned for --after-task-id`);
  }

  if (!beforeTask) {
    throw new UsageError(`Task ${params.beforeTaskId} was not returned for --before-task-id`);
  }

  const plan = buildTaskBlockRepositionPlan({
    afterTask,
    beforeTask,
    entries: params.entries,
    tasks: params.entries.map((entry) => {
      const task = tasksById.get(entry.taskId);
      if (!task) {
        throw new UsageError(`Task ${entry.taskId} was not returned for --task`);
      }

      return task;
    }),
  });
  const updatedTasks = await bulkUpdateTasks(
    plan.updates.map((update) => ({
      taskId: update.taskId,
      updateBody: {
        indent_level: update.indentLevel,
        order_index: update.orderIndex,
        ordinal: update.ordinal,
      },
    })),
  );
  const updatedTasksById = new Map(updatedTasks.map((task) => [task.id, normalizeOrderedTask(task)]));

  return {
    afterTaskId: plan.afterTaskId,
    beforeTaskId: plan.beforeTaskId,
    listId: plan.listId,
    updates: plan.updates.map((update) => {
      const updatedTask = updatedTasksById.get(update.taskId);
      if (!updatedTask) {
        throw new Error(`Godspeed API did not return updated task ${update.taskId}`);
      }

      return {
        indentLevel: updatedTask.indent_level,
        orderIndex: updatedTask.order_index,
        ordinal: updatedTask.ordinal,
        taskId: updatedTask.id,
        title: updatedTask.title,
      };
    }),
  };
}

function parseScope(scope: string | undefined): Scope {
  if (!scope || scope === "all" || scope === "personal" || scope === "work") {
    return (scope ?? "all") as Scope;
  }

  throw new UsageError(`Unsupported scope: ${scope}`);
}

function parseFolderKey(folder: string | undefined): FolderKey {
  if (folder === "personal" || folder === "work") {
    return folder;
  }

  throw new UsageError(`Unsupported folder: ${folder ?? "<missing>"}`);
}

function parseFolderStateKey(state: string | undefined): FolderStateKey {
  if (state === "inbox") {
    return "inbox";
  }

  if (state === "next-actions" || state === "nextActions") {
    return "nextActions";
  }

  if (state === "someday") {
    return "someday";
  }

  throw new UsageError(`Unsupported state: ${state ?? "<missing>"}`);
}

function collectCliArgs(argv: string[]): ParsedCliArgs {
  const [command, ...rest] = argv;
  if (!command) {
    throw new UsageError(buildUsageText());
  }

  const options = new Map<string, string[]>();
  const positionals: string[] = [];

  for (let index = 0; index < rest.length; index += 1) {
    const token = rest[index];
    if (!token.startsWith("--")) {
      positionals.push(token);
      continue;
    }

    const optionToken = token.slice(2);
    const equalsIndex = optionToken.indexOf("=");
    if (equalsIndex >= 0) {
      const key = optionToken.slice(0, equalsIndex);
      const value = optionToken.slice(equalsIndex + 1);
      const existingValues = options.get(key) ?? [];
      existingValues.push(value);
      options.set(key, existingValues);
      continue;
    }

    const nextToken = rest[index + 1];
    if (!nextToken || nextToken.startsWith("--")) {
      throw new UsageError(`Missing value for --${optionToken}`);
    }

    const existingValues = options.get(optionToken) ?? [];
    existingValues.push(nextToken);
    options.set(optionToken, existingValues);
    index += 1;
  }

  return {
    command,
    options,
    positionals,
  };
}

function getOption(options: Map<string, string[]>, key: string): string | undefined {
  const values = options.get(key);
  if (!values || values.length === 0) {
    return undefined;
  }

  return values[values.length - 1];
}

function getRequiredOption(options: Map<string, string[]>, key: string): string {
  const value = getOption(options, key);
  if (!value) {
    throw new UsageError(`Missing required option: --${key}`);
  }

  return value;
}

function getRepeatedOption(options: Map<string, string[]>, key: string): string[] {
  return options.get(key) ?? [];
}

function expectNoPositionals(parsedArgs: ParsedCliArgs): void {
  if (parsedArgs.positionals.length > 0) {
    throw new UsageError(`Unexpected positional arguments: ${parsedArgs.positionals.join(" ")}`);
  }
}

function buildUsageText(): string {
  return [
    "Usage: godspeed-tasks.ts <command> [options]",
    "",
    "Commands:",
    "  discover-lists",
    "  discover-labels",
    "  inbox-snapshot [--scope work|personal|all]",
    "  task-snapshot [--scope work|personal|all]",
    "  get-task --task-id <id>",
    "  create-task --folder work|personal --state inbox|next-actions|someday --title <title> [--notes <text>] [--label <name> ...] [--due <YYYY-MM-DD>]",
    "  update-task --task-id <id> [--title <title>] [--notes <text>] [--list-id <id>] [--due <YYYY-MM-DD|none>]",
    "  delete-task --task-id <id>",
    "  ensure-label --name <label-name> [--color <#rrggbb>]",
    "  set-task-labels --add-label <label-name> --task-id <id> [--task-id <id> ...]",
    "  remove-task-labels --remove-label <label-name> --task-id <id> [--task-id <id> ...]",
    "  reposition-task-block --task <id>:<indent-level> [--task <id>:<indent-level> ...] --after-task-id <id> --before-task-id <id>",
    "  preview-bulk-labeling --label <label-name> --contains <term> [--contains <term> ...] [--scope work|personal|all]",
    "  apply-bulk-labeling --label <label-name> --task-id <id> [--task-id <id> ...]",
    "  smart-list-plan --folder work|personal --label <label-name> [--smart-list-name <name>]",
    "  ensure-smart-list --folder work|personal --label <label-name> [--smart-list-name <name>]",
  ].join("\n");
}

async function runCommand(parsedArgs: ParsedCliArgs): Promise<unknown> {
  if (parsedArgs.command === "discover-lists") {
    expectNoPositionals(parsedArgs);
    return loadResolvedLists();
  }

  if (parsedArgs.command === "discover-labels") {
    expectNoPositionals(parsedArgs);
    return {
      labels: await loadLabels(),
    };
  }

  if (parsedArgs.command === "inbox-snapshot") {
    expectNoPositionals(parsedArgs);
    const scope = parseScope(getOption(parsedArgs.options, "scope"));
    const resolvedLists = await loadResolvedLists();
    const tasks = await loadScopeTasks(resolvedLists, scope);

    return buildInboxSnapshot({
      personalTasks: tasks.personalTasksByState?.inbox,
      resolvedLists,
      scope,
      workTasks: tasks.workTasksByState?.inbox,
    });
  }

  if (parsedArgs.command === "task-snapshot") {
    expectNoPositionals(parsedArgs);
    const scope = parseScope(getOption(parsedArgs.options, "scope"));
    const resolvedLists = await loadResolvedLists();
    const tasks = await loadScopeTasks(resolvedLists, scope);

    return buildTaskSnapshot({
      personalTasksByState: tasks.personalTasksByState,
      resolvedLists,
      scope,
      workTasksByState: tasks.workTasksByState,
    });
  }

  if (parsedArgs.command === "get-task") {
    expectNoPositionals(parsedArgs);
    return {
      task: await loadTaskById(getRequiredOption(parsedArgs.options, "task-id")),
    };
  }

  if (parsedArgs.command === "create-task") {
    expectNoPositionals(parsedArgs);
    return createScopedTask({
      folder: parseFolderKey(getRequiredOption(parsedArgs.options, "folder")),
      labelNames: getRepeatedOption(parsedArgs.options, "label"),
      notes: getOption(parsedArgs.options, "notes"),
      state: parseFolderStateKey(getRequiredOption(parsedArgs.options, "state")),
      timelessDueAt: getOption(parsedArgs.options, "due"),
      title: getRequiredOption(parsedArgs.options, "title"),
    });
  }

  if (parsedArgs.command === "update-task") {
    expectNoPositionals(parsedArgs);
    const taskId = getRequiredOption(parsedArgs.options, "task-id");
    return {
      task: await patchTask(taskId, buildTaskPatchBody(parsedArgs.options)),
    };
  }

  if (parsedArgs.command === "delete-task") {
    expectNoPositionals(parsedArgs);
    const taskId = getRequiredOption(parsedArgs.options, "task-id");
    await deleteTaskById(taskId);
    return {
      taskId,
    };
  }

  if (parsedArgs.command === "ensure-label") {
    expectNoPositionals(parsedArgs);
    return ensureLabel({
      color: getOption(parsedArgs.options, "color"),
      name: getRequiredOption(parsedArgs.options, "name"),
    });
  }

  if (parsedArgs.command === "set-task-labels") {
    expectNoPositionals(parsedArgs);
    return applyLabelToTaskIds({
      createIfMissing: true,
      labelName: getRequiredOption(parsedArgs.options, "add-label"),
      taskIds: getRepeatedOption(parsedArgs.options, "task-id"),
    });
  }

  if (parsedArgs.command === "remove-task-labels") {
    expectNoPositionals(parsedArgs);
    return applyLabelToTaskIds({
      createIfMissing: false,
      labelName: getRequiredOption(parsedArgs.options, "remove-label"),
      remove: true,
      taskIds: getRepeatedOption(parsedArgs.options, "task-id"),
    });
  }

  if (parsedArgs.command === "reposition-task-block") {
    expectNoPositionals(parsedArgs);
    return repositionTaskBlock({
      afterTaskId: getRequiredOption(parsedArgs.options, "after-task-id"),
      beforeTaskId: getRequiredOption(parsedArgs.options, "before-task-id"),
      entries: parseTaskBlockEntries(getRepeatedOption(parsedArgs.options, "task")),
    });
  }

  if (parsedArgs.command === "preview-bulk-labeling") {
    expectNoPositionals(parsedArgs);
    const labelName = getRequiredOption(parsedArgs.options, "label");
    const scope = parseScope(getOption(parsedArgs.options, "scope"));
    const contains = getRepeatedOption(parsedArgs.options, "contains");
    const resolvedLists = await loadResolvedLists();
    const labels = await loadLabels();
    const existingLabel = findLabelByName(labels, labelName);
    const tasks = await loadScopeTasks(resolvedLists, scope);
    const snapshot = buildTaskSnapshot({
      personalTasksByState: tasks.personalTasksByState,
      resolvedLists,
      scope,
      workTasksByState: tasks.workTasksByState,
    });

    return buildBulkLabelPreview({
      contains,
      labelId: existingLabel?.id,
      labelName,
      scope,
      snapshot,
    });
  }

  if (parsedArgs.command === "apply-bulk-labeling") {
    expectNoPositionals(parsedArgs);
    return applyLabelToTaskIds({
      createIfMissing: true,
      labelName: getRequiredOption(parsedArgs.options, "label"),
      taskIds: getRepeatedOption(parsedArgs.options, "task-id"),
    });
  }

  if (parsedArgs.command === "smart-list-plan") {
    expectNoPositionals(parsedArgs);
    const labelName = getRequiredOption(parsedArgs.options, "label");
    const folder = parseFolderKey(getRequiredOption(parsedArgs.options, "folder"));
    const resolvedLists = await loadResolvedLists();
    const labels = await loadLabels();
    const existingLabel = findLabelByName(labels, labelName);

    return buildSmartListPlan({
      folder,
      labelId: existingLabel?.id,
      labelName,
      resolvedLists,
      smartListName: getOption(parsedArgs.options, "smart-list-name"),
    });
  }

  if (parsedArgs.command === "ensure-smart-list") {
    expectNoPositionals(parsedArgs);
    return ensureSmartList({
      folder: parseFolderKey(getRequiredOption(parsedArgs.options, "folder")),
      labelName: getRequiredOption(parsedArgs.options, "label"),
      smartListName: getOption(parsedArgs.options, "smart-list-name"),
    });
  }

  throw new UsageError(buildUsageText());
}

async function main(): Promise<void> {
  const parsedArgs = collectCliArgs(Bun.argv.slice(2));
  const result = await runCommand(parsedArgs);
  console.log(JSON.stringify(result, null, 2));
}

if (import.meta.main) {
  try {
    await main();
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error(message);
    process.exit(error instanceof UsageError ? 2 : 1);
  }
}
