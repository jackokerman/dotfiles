# Things task management

Things is the local task manager. Keep sync disabled and treat the database on each Mac as local state.

Use Things' built-in lists directly:

- Inbox for untriaged capture.
- Anytime for next actions.
- Someday for deferred work.
- Today and Upcoming for scheduled work.

Do not recreate those states as areas, projects, tags, or custom lists. Use projects for multi-step outcomes and tags only for real categories.

## Agent automation

The tracked `things-tasks` skill owns task automation through Things' supported AppleScript dictionary. Its helper is generated to:

```bash
~/.codex/skills/things-tasks/scripts/things-tasks.js
```

Invoke it with `osascript`:

```bash
osascript -l JavaScript ~/.codex/skills/things-tasks/scripts/things-tasks.js snapshot
osascript -l JavaScript ~/.codex/skills/things-tasks/scripts/things-tasks.js task create --state inbox --title "Follow up"
```

The helper does not enable cloud sync, request Full Disk Access, or read Things' private database.
