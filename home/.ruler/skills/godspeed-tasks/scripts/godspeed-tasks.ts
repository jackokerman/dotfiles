#!/usr/bin/env bun

type Scope = "all" | "personal" | "work";
type FolderKey = "personal" | "work";

type GodspeedListType = "folder" | "inbox" | "list" | "smart";

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

type GodspeedTask = {
  created_at: string;
  due_at: string | null;
  duration_minutes: number | null;
  id: string;
  notes: string;
  starts_at: string | null;
  timeless_due_at: string | null;
  timeless_starts_at: string | null;
  title: string;
  updated_at: string;
};

type GodspeedTasksResponse = {
  success: boolean;
  tasks: GodspeedTask[];
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

type NormalizedInboxTask = {
  createdAt: string;
  dueAt: string | null;
  durationMinutes: number | null;
  folder: FolderKey;
  id: string;
  localEvidenceEligible: boolean;
  localEvidenceSignals: LocalEvidenceSignal[];
  notes: string;
  sourceListId: string;
  sourceListName: string;
  startsAt: string | null;
  timelessDueAt: string | null;
  timelessStartsAt: string | null;
  title: string;
  updatedAt: string;
};

type InboxSnapshot = {
  inboxes: {
    personal?: {
      inboxId: string;
      tasks: NormalizedInboxTask[];
    };
    work?: {
      inboxId: string;
      tasks: NormalizedInboxTask[];
    };
  };
  resolvedLists: {
    personal?: ResolvedFolderLists;
    work?: ResolvedFolderLists;
  };
  scope: Scope;
};

const folderNames = {
  personal: "🏡 Personal",
  work: "🏢 Work",
} satisfies Record<FolderKey, string>;

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

class UsageError extends Error {}

function assertEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }

  return value;
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

function sortLists(lists: GodspeedList[]): GodspeedList[] {
  return [...lists].sort((left, right) => left.order_index - right.order_index);
}

function selectActiveLists(lists: GodspeedList[]): GodspeedList[] {
  return sortLists(lists.filter((list) => list.archived_at === null));
}

function resolveNamedFolder(lists: GodspeedList[], folder: FolderKey): GodspeedList {
  const matches = lists.filter(
    (list) => list.indent_level === 0 && list.list_type === "folder" && list.name === folderNames[folder],
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
      continue;
    }
  }

  return { childrenByFolderId, rootInbox };
}

function resolveRequiredChild(
  children: GodspeedList[],
  params: { listType: GodspeedListType; name: string },
): GodspeedList {
  const matches = children.filter((list) => list.list_type === params.listType && list.name === params.name);
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
  const matches = children.filter((list) => list.list_type === params.listType && list.name === params.name);
  if (matches.length > 1) {
    throw new Error(
      `Expected at most one child ${params.listType} list named "${params.name}", found ${matches.length}`,
    );
  }

  return matches[0];
}

export function discoverLists(lists: GodspeedList[]): DiscoverListsResult {
  const activeLists = selectActiveLists(lists);
  const { childrenByFolderId, rootInbox } = collectChildrenByFolder(activeLists);

  function resolveFolderLists(folder: FolderKey): ResolvedFolderLists {
    const folderList = resolveNamedFolder(activeLists, folder);
    const children = childrenByFolderId.get(folderList.id) ?? [];
    const today = resolveOptionalChild(children, { listType: "smart", name: "Today" });

    return {
      folder: normalizeList(folderList),
      inbox: normalizeList(resolveRequiredChild(children, { listType: "list", name: "📥 Inbox" })),
      nextActions: normalizeList(resolveRequiredChild(children, { listType: "list", name: "⚡ Next Actions" })),
      someday: normalizeList(resolveRequiredChild(children, { listType: "list", name: "🌱 Someday" })),
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

export function getLocalEvidenceSignals(task: Pick<GodspeedTask, "notes" | "title">): LocalEvidenceSignal[] {
  const haystack = `${task.title}\n${task.notes}`;
  return dedupeSignals(
    localEvidenceMatchers.flatMap((matcher) => (matcher.regex.test(haystack) ? [matcher.signal] : [])),
  );
}

export function isLocallyVerifiableTask(task: Pick<GodspeedTask, "notes" | "title">): boolean {
  return getLocalEvidenceSignals(task).length > 0;
}

function normalizeTask(params: {
  folder: FolderKey;
  sourceList: NormalizedList;
  task: GodspeedTask;
}): NormalizedInboxTask {
  const localEvidenceSignals = getLocalEvidenceSignals(params.task);

  return {
    createdAt: params.task.created_at,
    dueAt: params.task.due_at,
    durationMinutes: params.task.duration_minutes,
    folder: params.folder,
    id: params.task.id,
    localEvidenceEligible: localEvidenceSignals.length > 0,
    localEvidenceSignals,
    notes: params.task.notes,
    sourceListId: params.sourceList.id,
    sourceListName: params.sourceList.name,
    startsAt: params.task.starts_at,
    timelessDueAt: params.task.timeless_due_at,
    timelessStartsAt: params.task.timeless_starts_at,
    title: params.task.title,
    updatedAt: params.task.updated_at,
  };
}

function sortTasks(tasks: GodspeedTask[]): GodspeedTask[] {
  return [...tasks].sort((left, right) => left.created_at.localeCompare(right.created_at));
}

export function buildInboxSnapshot(params: {
  personalTasks?: GodspeedTask[];
  resolvedLists: DiscoverListsResult;
  scope: Scope;
  workTasks?: GodspeedTask[];
}): InboxSnapshot {
  const snapshot: InboxSnapshot = {
    inboxes: {},
    resolvedLists: {},
    scope: params.scope,
  };

  if (params.scope === "all" || params.scope === "work") {
    const workTasks = sortTasks(params.workTasks ?? []).map((task) =>
      normalizeTask({
        folder: "work",
        sourceList: params.resolvedLists.work.inbox,
        task,
      }),
    );
    snapshot.resolvedLists.work = params.resolvedLists.work;
    snapshot.inboxes.work = {
      inboxId: params.resolvedLists.work.inbox.id,
      tasks: workTasks,
    };
  }

  if (params.scope === "all" || params.scope === "personal") {
    const personalTasks = sortTasks(params.personalTasks ?? []).map((task) =>
      normalizeTask({
        folder: "personal",
        sourceList: params.resolvedLists.personal.inbox,
        task,
      }),
    );
    snapshot.resolvedLists.personal = params.resolvedLists.personal;
    snapshot.inboxes.personal = {
      inboxId: params.resolvedLists.personal.inbox.id,
      tasks: personalTasks,
    };
  }

  return snapshot;
}

async function fetchJson<T>(path: string, params: Record<string, string> = {}): Promise<T> {
  const token = assertEnv("GODSPEED_API_TOKEN");
  const url = new URL(`https://api.godspeedapp.com${path}`);
  for (const [key, value] of Object.entries(params)) {
    url.searchParams.set(key, value);
  }

  const response = await fetch(url, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Godspeed API request failed: ${response.status} ${response.statusText} for ${url}\n${body}`);
  }

  return (await response.json()) as T;
}

async function loadResolvedLists(): Promise<DiscoverListsResult> {
  const response = await fetchJson<GodspeedListsResponse>("/lists");
  if (!response.success) {
    throw new Error("Godspeed API reported an unsuccessful list response");
  }

  return discoverLists(response.lists);
}

async function loadInboxTasks(listId: string): Promise<GodspeedTask[]> {
  const response = await fetchJson<GodspeedTasksResponse>("/tasks", {
    list_id: listId,
    status: "incomplete",
  });

  if (!response.success) {
    throw new Error("Godspeed API reported an unsuccessful task response");
  }

  return response.tasks;
}

function parseScope(scope: string | undefined): Scope {
  if (!scope || scope === "all" || scope === "personal" || scope === "work") {
    return (scope ?? "all") as Scope;
  }

  throw new UsageError(`Unsupported scope: ${scope}`);
}

function parseArgs(argv: string[]): { command: "discover-lists" | "inbox-snapshot"; scope: Scope } {
  const [command, ...rest] = argv;
  if (command !== "discover-lists" && command !== "inbox-snapshot") {
    throw new UsageError("Usage: godspeed-tasks.ts <discover-lists|inbox-snapshot> [--scope work|personal|all]");
  }

  let scope: Scope = "all";
  for (let index = 0; index < rest.length; index += 1) {
    const token = rest[index];
    if (token === "--scope") {
      scope = parseScope(rest[index + 1]);
      index += 1;
      continue;
    }

    if (token.startsWith("--scope=")) {
      scope = parseScope(token.slice("--scope=".length));
      continue;
    }

    throw new UsageError(`Unexpected argument: ${token}`);
  }

  return { command, scope };
}

async function main(): Promise<void> {
  const args = parseArgs(Bun.argv.slice(2));
  const resolvedLists = await loadResolvedLists();

  if (args.command === "discover-lists") {
    console.log(JSON.stringify(resolvedLists, null, 2));
    return;
  }

  const [workTasks, personalTasks] = await Promise.all([
    args.scope === "all" || args.scope === "work" ? loadInboxTasks(resolvedLists.work.inbox.id) : Promise.resolve([]),
    args.scope === "all" || args.scope === "personal"
      ? loadInboxTasks(resolvedLists.personal.inbox.id)
      : Promise.resolve([]),
  ]);

  const snapshot = buildInboxSnapshot({
    personalTasks,
    resolvedLists,
    scope: args.scope,
    workTasks,
  });

  console.log(JSON.stringify(snapshot, null, 2));
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
