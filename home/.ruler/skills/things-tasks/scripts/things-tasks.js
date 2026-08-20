function usage() {
  return [
    "Usage: things-tasks <command> [options]",
    "",
    "Commands:",
    "  status",
    "  snapshot",
    "  areas",
    "  projects",
    "  tags",
    "  task get --id <id>",
    "  task create --state inbox|anytime|someday --title <title> [--project-id <id>] [--notes <text>] [--checklist-item <text> ...] [--start <YYYY-MM-DD>] [--due <YYYY-MM-DD>] [--tag <name> ...]",
    "  task update --id <id> [--title <title>] [--notes <text>] [--state inbox|anytime|someday] [--start <YYYY-MM-DD>] [--due <YYYY-MM-DD>] [--tag <name> ...]",
    "  task complete --id <id>",
    "  task delete --id <id>",
    "  project get --id <id>",
    "  project create --state anytime|someday --title <title> [--notes <text>] [--tag <name> ...]",
    "  project complete --id <id>",
    "  project delete --id <id>",
  ].join("\n");
}

function parseArgs(argv) {
  const positionals = [];
  const options = {};

  for (let index = 0; index < argv.length; index += 1) {
    const value = argv[index];
    if (!value.startsWith("--")) {
      positionals.push(value);
      continue;
    }

    const name = value.slice(2);
    if (name.length === 0) {
      throw new Error("Invalid empty option");
    }

    const next = argv[index + 1];
    const optionValue = next !== undefined && !next.startsWith("--") ? next : true;
    if (optionValue !== true) {
      index += 1;
    }

    if (options[name] === undefined) {
      options[name] = optionValue;
    } else if (Array.isArray(options[name])) {
      options[name].push(optionValue);
    } else {
      options[name] = [options[name], optionValue];
    }
  }

  return {options: options, positionals: positionals};
}

function requiredOption(options, name) {
  const value = options[name];
  if (typeof value !== "string" || value.length === 0) {
    throw new Error("Missing required --" + name);
  }
  return value;
}

function optionalString(options, name) {
  const value = options[name];
  if (value === undefined) {
    return undefined;
  }
  if (typeof value !== "string") {
    throw new Error("Expected a value for --" + name);
  }
  return value;
}

function repeatedStrings(options, name) {
  const value = options[name];
  if (value === undefined) {
    return [];
  }
  const values = Array.isArray(value) ? value : [value];
  values.forEach(function (entry) {
    if (typeof entry !== "string" || entry.length === 0) {
      throw new Error("Expected a value for --" + name);
    }
  });
  return values;
}

function unique(values) {
  return values.filter(function (value, index) {
    return values.indexOf(value) === index;
  });
}

function parseDateOption(options, name) {
  const value = optionalString(options, name);
  if (value === undefined) {
    return undefined;
  }
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
  if (!match) {
    throw new Error("Expected --" + name + " in YYYY-MM-DD format");
  }
  return new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3]), 12, 0, 0);
}

function dateValue(value) {
  if (!value) {
    return null;
  }
  try {
    return value.toISOString();
  } catch (_error) {
    return String(value);
  }
}

function dateString(value) {
  const year = String(value.getFullYear());
  const month = String(value.getMonth() + 1).padStart(2, "0");
  const day = String(value.getDate()).padStart(2, "0");
  return year + "-" + month + "-" + day;
}

function shellQuote(value) {
  return "'" + value.replace(/'/g, "'\\''") + "'";
}

function nameValue(reference) {
  try {
    const value = reference();
    return value && value.name ? value.name() : null;
  } catch (_error) {
    return null;
  }
}

function tagNames(todo) {
  try {
    return todo.tags().map(function (tag) {
      return tag.name();
    });
  } catch (_error) {
    const raw = todo.tagNames();
    return raw ? raw.split(",").map(function (tag) { return tag.trim(); }).filter(Boolean) : [];
  }
}

function listMembership(app, todoId) {
  return ["Inbox", "Today", "Upcoming", "Anytime", "Someday"].filter(function (listName) {
    try {
      return app.lists.byName(listName).toDos().some(function (todo) {
        return todo.id() === todoId;
      });
    } catch (_error) {
      return false;
    }
  });
}

function buildMembershipIndex(app) {
  const membership = {};
  ["Inbox", "Today", "Upcoming", "Anytime", "Someday"].forEach(function (listName) {
    try {
      app.lists.byName(listName).toDos().forEach(function (todo) {
        const id = todo.id();
        membership[id] = membership[id] || [];
        membership[id].push(listName);
      });
    } catch (_error) {
      // A missing localized list contributes no membership.
    }
  });
  return membership;
}

function serializeTodo(app, todo, membership) {
  return {
    id: todo.id(),
    title: todo.name(),
    notes: todo.notes(),
    status: String(todo.status()),
    tags: tagNames(todo),
    lists: membership ? (membership[todo.id()] || []) : listMembership(app, todo.id()),
    area: nameValue(todo.area),
    project: nameValue(todo.project),
    createdAt: dateValue(todo.creationDate()),
    updatedAt: dateValue(todo.modificationDate()),
    startsAt: dateValue(todo.activationDate()),
    dueAt: dateValue(todo.dueDate()),
    completedAt: dateValue(todo.completionDate()),
  };
}

function todoById(app, id) {
  const todo = app.toDos.byId(id);
  let resolvedId;
  try {
    resolvedId = todo.id();
  } catch (_error) {
    throw new Error("Things task not found: " + id);
  }
  if (resolvedId !== id) {
    throw new Error("Things task not found: " + id);
  }
  return todo;
}

function projectById(app, id) {
  const project = app.projects.byId(id);
  let resolvedId;
  try {
    resolvedId = project.id();
  } catch (_error) {
    throw new Error("Things project not found: " + id);
  }
  if (resolvedId !== id) {
    throw new Error("Things project not found: " + id);
  }
  return project;
}

function stateList(app, state) {
  const listNames = {inbox: "Inbox", anytime: "Anytime", someday: "Someday"};
  const listName = listNames[state];
  if (!listName) {
    throw new Error("Expected --state inbox, anytime, or someday");
  }
  return app.lists.byName(listName);
}

function moveToState(app, todo, state) {
  const target = stateList(app, state);
  const currentApplication = Application.currentApplication();
  currentApplication.includeStandardAdditions = true;
  const script = "tell application \"Things3\" to move to do id \"" + todo.id() + "\" to list \"" + target.name() + "\"";
  currentApplication.doShellScript("/usr/bin/osascript -e " + shellQuote(script));
}

function scheduleTask(todo, date) {
  const currentApplication = Application.currentApplication();
  currentApplication.includeStandardAdditions = true;
  const script = [
    "tell application \"Things3\"",
    "set targetDate to current date",
    "set year of targetDate to " + date.getFullYear(),
    "set month of targetDate to " + (date.getMonth() + 1),
    "set day of targetDate to " + date.getDate(),
    "set time of targetDate to 43200",
    "schedule to do id \"" + todo.id() + "\" for targetDate",
    "end tell",
  ].join("\n");
  currentApplication.doShellScript("/usr/bin/osascript -e " + shellQuote(script));
}

function ensureTags(app, names) {
  const existing = app.tags().map(function (tag) { return tag.name(); });
  names.forEach(function (name) {
    if (existing.indexOf(name) !== -1) {
      return;
    }
    const tag = app.Tag({name: name});
    app.tags.push(tag);
    existing.push(name);
  });
}

function addTaskThroughUrl(app, parameters, title) {
  const beforeIds = {};
  app.toDos().forEach(function (todo) { beforeIds[todo.id()] = true; });
  const query = Object.keys(parameters).map(function (name) {
    return encodeURIComponent(name) + "=" + encodeURIComponent(parameters[name]);
  }).join("&");
  const currentApplication = Application.currentApplication();
  currentApplication.includeStandardAdditions = true;
  currentApplication.doShellScript("/usr/bin/open -g " + shellQuote("things:///add?" + query));
  currentApplication.doShellScript("/bin/sleep 1");
  const created = app.toDos().filter(function (todo) {
    return !beforeIds[todo.id()] && todo.name() === title;
  });
  if (created.length === 1) {
    return created[0];
  }
  throw new Error("Things did not return the created task: " + title);
}

function createTask(app, options) {
  const title = requiredOption(options, "title");
  const state = optionalString(options, "state") || "inbox";
  const tags = unique(repeatedStrings(options, "tag"));
  stateList(app, state);
  const dueDate = parseDateOption(options, "due");
  const startDate = parseDateOption(options, "start");
  const notes = optionalString(options, "notes");
  const projectId = optionalString(options, "project-id");
  const checklistItems = repeatedStrings(options, "checklist-item");
  if (projectId !== undefined) {
    projectById(app, projectId);
  }
  ensureTags(app, tags);

  const parameters = {title: title};
  if (notes !== undefined) parameters.notes = notes;
  if (checklistItems.length > 0) parameters["checklist-items"] = checklistItems.join("\n");
  if (tags.length > 0) parameters.tags = tags.join(",");
  if (projectId !== undefined) parameters["list-id"] = projectId;
  if (startDate !== undefined) {
    parameters.when = dateString(startDate);
  } else if (state !== "inbox") {
    parameters.when = state;
  }
  if (dueDate !== undefined) parameters.deadline = dateString(dueDate);

  return serializeTodo(app, addTaskThroughUrl(app, parameters, title));
}

function createProject(app, options) {
  const title = requiredOption(options, "title");
  const state = optionalString(options, "state") || "anytime";
  if (state === "inbox") {
    throw new Error("Things projects cannot use Inbox; expected --state anytime or someday");
  }
  const properties = {name: title};
  const notes = optionalString(options, "notes");
  const tags = unique(repeatedStrings(options, "tag"));
  if (notes !== undefined) {
    properties.notes = notes;
  }
  if (tags.length > 0) {
    properties.tagNames = tags.join(",");
  }

  const project = app.Project(properties);
  app.projects.push(project);
  const id = project.id();
  moveToState(app, project, state);
  return serializeTodo(app, app.projects.byId(id));
}

function updateTask(app, options) {
  const todo = todoById(app, requiredOption(options, "id"));
  const id = todo.id();
  const title = optionalString(options, "title");
  const notes = optionalString(options, "notes");
  const state = optionalString(options, "state");
  const dueDate = parseDateOption(options, "due");
  const startDate = parseDateOption(options, "start");
  const requestedTags = repeatedStrings(options, "tag");

  if (title !== undefined) {
    todo.name = title;
  }
  if (notes !== undefined) {
    todo.notes = notes;
  }
  if (requestedTags.length > 0) {
    todo.tagNames = unique(requestedTags).join(",");
  }
  if (dueDate !== undefined) {
    todo.dueDate = dueDate;
  }
  if (startDate !== undefined) {
    scheduleTask(todo, startDate);
  }
  if (state !== undefined) {
    moveToState(app, todo, state);
  }

  return serializeTodo(app, todoById(app, id));
}

function run(argv) {
  const parsed = parseArgs(argv);
  const command = parsed.positionals.join(" ");
  if (!command || command === "help") {
    return usage();
  }

  const app = Application("Things3");
  let data;

  if (command === "status") {
    data = {version: app.version(), projectCount: app.projects().length, taskCount: app.toDos().length};
  } else if (command === "snapshot") {
    const membership = buildMembershipIndex(app);
    data = {
      projects: app.projects().map(function (project) { return serializeTodo(app, project, membership); }),
      tasks: app.toDos().map(function (todo) { return serializeTodo(app, todo, membership); }),
    };
  } else if (command === "areas") {
    data = {areas: app.areas().map(function (area) { return {id: area.id(), name: area.name()}; })};
  } else if (command === "projects") {
    data = {projects: app.projects().map(function (project) { return serializeTodo(app, project); })};
  } else if (command === "tags") {
    data = {tags: app.tags().map(function (tag) { return {id: tag.id(), name: tag.name()}; })};
  } else if (command === "task get") {
    data = {task: serializeTodo(app, todoById(app, requiredOption(parsed.options, "id")))};
  } else if (command === "task create") {
    data = {task: createTask(app, parsed.options)};
  } else if (command === "task update") {
    data = {task: updateTask(app, parsed.options)};
  } else if (command === "task complete") {
    const todo = todoById(app, requiredOption(parsed.options, "id"));
    todo.status = "completed";
    data = {task: serializeTodo(app, todo)};
  } else if (command === "task delete") {
    const todo = todoById(app, requiredOption(parsed.options, "id"));
    const id = todo.id();
    app.delete(todo);
    data = {deletedTaskId: id};
  } else if (command === "project get") {
    data = {project: serializeTodo(app, projectById(app, requiredOption(parsed.options, "id")))};
  } else if (command === "project create") {
    data = {project: createProject(app, parsed.options)};
  } else if (command === "project complete") {
    const project = projectById(app, requiredOption(parsed.options, "id"));
    project.status = "completed";
    data = {project: serializeTodo(app, project)};
  } else if (command === "project delete") {
    const project = projectById(app, requiredOption(parsed.options, "id"));
    const id = project.id();
    app.delete(project);
    data = {deletedProjectId: id};
  } else {
    throw new Error("Unknown command: " + command + "\n\n" + usage());
  }

  return JSON.stringify({ok: true, data: data});
}
