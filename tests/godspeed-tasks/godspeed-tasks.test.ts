import { describe, expect, it } from "bun:test";

import {
  buildInboxSnapshot,
  discoverLists,
  getLocalEvidenceSignals,
  isLocallyVerifiableTask,
} from "../../home/.codex/skills/godspeed-tasks/scripts/godspeed-tasks";

type GodspeedList = Parameters<typeof discoverLists>[0][number];
type GodspeedTask = Parameters<typeof buildInboxSnapshot>[0]["workTasks"][number];

function list(params: Partial<GodspeedList> & Pick<GodspeedList, "id" | "indent_level" | "list_type" | "name">): GodspeedList {
  return {
    archived_at: null,
    id: params.id,
    indent_level: params.indent_level,
    list_type: params.list_type,
    name: params.name,
    order_index: params.order_index ?? 0,
    smart_list_query: params.smart_list_query ?? null,
  };
}

function task(
  params: Partial<GodspeedTask> & Pick<GodspeedTask, "created_at" | "id" | "notes" | "title" | "updated_at">,
): GodspeedTask {
  return {
    created_at: params.created_at,
    due_at: params.due_at ?? null,
    duration_minutes: params.duration_minutes ?? null,
    id: params.id,
    notes: params.notes,
    starts_at: params.starts_at ?? null,
    timeless_due_at: params.timeless_due_at ?? null,
    timeless_starts_at: params.timeless_starts_at ?? null,
    title: params.title,
    updated_at: params.updated_at,
  };
}

function mirroredLists(): GodspeedList[] {
  return [
    list({
      id: "root-inbox",
      indent_level: 0,
      list_type: "inbox",
      name: "Inbox",
      order_index: 10,
    }),
    list({
      id: "work-folder",
      indent_level: 0,
      list_type: "folder",
      name: "🏢 Work",
      order_index: 20,
    }),
    list({
      id: "work-today",
      indent_level: 1,
      list_type: "smart",
      name: "Today",
      order_index: 21,
      smart_list_query: "folder:\"work-folder\"",
    }),
    list({
      id: "work-inbox",
      indent_level: 1,
      list_type: "list",
      name: "📥 Inbox",
      order_index: 22,
    }),
    list({
      id: "work-next",
      indent_level: 1,
      list_type: "list",
      name: "⚡ Next Actions",
      order_index: 23,
    }),
    list({
      id: "work-someday",
      indent_level: 1,
      list_type: "list",
      name: "🌱 Someday",
      order_index: 24,
    }),
    list({
      id: "personal-folder",
      indent_level: 0,
      list_type: "folder",
      name: "🏡 Personal",
      order_index: 30,
    }),
    list({
      id: "personal-today",
      indent_level: 1,
      list_type: "smart",
      name: "Today",
      order_index: 31,
      smart_list_query: "folder:\"personal-folder\"",
    }),
    list({
      id: "personal-inbox",
      indent_level: 1,
      list_type: "list",
      name: "📥 Inbox",
      order_index: 32,
    }),
    list({
      id: "personal-next",
      indent_level: 1,
      list_type: "list",
      name: "⚡ Next Actions",
      order_index: 33,
    }),
    list({
      id: "personal-someday",
      indent_level: 1,
      list_type: "list",
      name: "🌱 Someday",
      order_index: 34,
    }),
  ];
}

describe("discoverLists", () => {
  it("resolves the mirrored work and personal folders and ignores the root inbox", () => {
    const resolved = discoverLists(mirroredLists());

    expect(resolved.ignored.rootInbox?.id).toBe("root-inbox");
    expect(resolved.work.folder.id).toBe("work-folder");
    expect(resolved.work.inbox.id).toBe("work-inbox");
    expect(resolved.work.nextActions.id).toBe("work-next");
    expect(resolved.work.someday.id).toBe("work-someday");
    expect(resolved.work.today?.id).toBe("work-today");
    expect(resolved.personal.folder.id).toBe("personal-folder");
    expect(resolved.personal.inbox.id).toBe("personal-inbox");
    expect(resolved.personal.nextActions.id).toBe("personal-next");
    expect(resolved.personal.someday.id).toBe("personal-someday");
    expect(resolved.personal.today?.id).toBe("personal-today");
  });

  it("fails when a required child list is missing", () => {
    const lists = mirroredLists().filter((entry) => entry.id !== "work-inbox");
    expect(() => discoverLists(lists)).toThrow('Expected exactly one child list list named "📥 Inbox"');
  });

  it("fails when a required child list is duplicated", () => {
    const lists = [
      ...mirroredLists(),
      list({
        id: "work-next-duplicate",
        indent_level: 1,
        list_type: "list",
        name: "⚡ Next Actions",
        order_index: 23.5,
      }),
    ];
    expect(() => discoverLists(lists)).toThrow(
      'Expected exactly one child list list named "⚡ Next Actions"',
    );
  });

  it("fails when a child list appears before a folder", () => {
    const lists = [
      list({
        id: "orphan",
        indent_level: 1,
        list_type: "list",
        name: "📥 Inbox",
        order_index: 1,
      }),
      ...mirroredLists(),
    ];
    expect(() => discoverLists(lists)).toThrow('Found child list "📥 Inbox" without a preceding folder');
  });
});

describe("buildInboxSnapshot", () => {
  const resolvedLists = discoverLists(mirroredLists());

  it("builds an all-scope snapshot and sorts tasks by created time", () => {
    const snapshot = buildInboxSnapshot({
      personalTasks: [
        task({
          created_at: "2026-04-02T00:00:00.000Z",
          id: "personal-2",
          notes: "",
          title: "Later personal task",
          updated_at: "2026-04-02T00:00:00.000Z",
        }),
        task({
          created_at: "2026-04-01T00:00:00.000Z",
          id: "personal-1",
          notes: "",
          title: "Earlier personal task",
          updated_at: "2026-04-01T00:00:00.000Z",
        }),
      ],
      resolvedLists,
      scope: "all",
      workTasks: [
        task({
          created_at: "2026-04-03T00:00:00.000Z",
          id: "work-1",
          notes: "",
          title: "Work task",
          updated_at: "2026-04-03T00:00:00.000Z",
        }),
      ],
    });

    expect(snapshot.scope).toBe("all");
    expect(snapshot.inboxes.work?.tasks).toHaveLength(1);
    expect(snapshot.inboxes.personal?.tasks.map((entry) => entry.id)).toEqual(["personal-1", "personal-2"]);
  });

  it("supports single-folder snapshots for work", () => {
    const snapshot = buildInboxSnapshot({
      resolvedLists,
      scope: "work",
      workTasks: [],
    });

    expect(snapshot.inboxes.work?.tasks).toEqual([]);
    expect(snapshot.inboxes.personal).toBeUndefined();
    expect(snapshot.resolvedLists.personal).toBeUndefined();
  });

  it("supports personal-only snapshots", () => {
    const snapshot = buildInboxSnapshot({
      personalTasks: [],
      resolvedLists,
      scope: "personal",
    });

    expect(snapshot.inboxes.personal?.tasks).toEqual([]);
    expect(snapshot.inboxes.work).toBeUndefined();
    expect(snapshot.resolvedLists.work).toBeUndefined();
  });
});

describe("local evidence gating", () => {
  it("marks command and repo-oriented tasks as locally verifiable", () => {
    const signals = getLocalEvidenceSignals(
      task({
        created_at: "2026-04-01T00:00:00.000Z",
        id: "task-1",
        notes: "Use `gh pr view` and update AGENTS.md in the dotfiles repo.",
        title: "Don't use webfetch for github, use the gh cli",
        updated_at: "2026-04-01T00:00:00.000Z",
      }),
    );

    expect(signals).toContain("command");
    expect(signals).toContain("repo-keyword");
    expect(isLocallyVerifiableTask(
      task({
        created_at: "2026-04-01T00:00:00.000Z",
        id: "task-1",
        notes: "Use `gh pr view` and update AGENTS.md in the dotfiles repo.",
        title: "Don't use webfetch for github, use the gh cli",
        updated_at: "2026-04-01T00:00:00.000Z",
      }),
    )).toBe(true);
  });

  it("marks machine-state tasks as locally verifiable", () => {
    const signals = getLocalEvidenceSignals(
      task({
        created_at: "2026-04-01T00:00:00.000Z",
        id: "task-2",
        notes: "sudo mscupdate for example",
        title: "Figure out why sudo touch ID isn't working",
        updated_at: "2026-04-01T00:00:00.000Z",
      }),
    );

    expect(signals).toContain("machine-state");
    expect(signals).toContain("command");
  });

  it("leaves real-world tasks in normal inbox triage", () => {
    expect(
      isLocallyVerifiableTask(
        task({
          created_at: "2026-04-01T00:00:00.000Z",
          id: "task-3",
          notes: "",
          title: "Schedule dermatologist appointment regarding split nail",
          updated_at: "2026-04-01T00:00:00.000Z",
        }),
      ),
    ).toBe(false);
  });
});
