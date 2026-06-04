import { describe, expect, test } from "bun:test";
import { spawnSync } from "node:child_process";
import { resolve } from "node:path";

const helperScript = resolve(import.meta.dir, "run-helper.ts");

function runHelper(command: "paste-script" | "payload" | "render" | "select" | "trim", payload: Record<string, string | null>) {
  const result = spawnSync("bun", ["--install=auto", helperScript, command, JSON.stringify(payload)], {
    cwd: resolve(import.meta.dir, "../.."),
    encoding: "utf8",
  });

  if (result.status !== 0) {
    throw new Error(result.stderr || `helper exited with ${result.status}`);
  }

  return JSON.parse(result.stdout) as unknown;
}

function runCli(args: string[], input: string) {
  return spawnSync("bun", ["--install=auto", "home/.local/lib/slack-rich-text.ts", ...args], {
    cwd: resolve(import.meta.dir, "../.."),
    encoding: "utf8",
    input,
  });
}

describe("slack rich text renderer", () => {
  test("renders final headings as plain inline text", () => {
    const html = runHelper("render", { input: "## Updates:" }) as string;

    expect(html).toContain("<span>Updates:</span>");
    expect(html).not.toContain("<h2>");
    expect(html).not.toContain("<strong>Updates:</strong>");
  });

  test("renders the final paragraph inline to avoid trailing Slack blank lines", () => {
    const html = runHelper("render", { input: "First paragraph\n\nSecond paragraph" }) as string;

    expect(html).toContain("<p>First paragraph</p><p><br/></p><span>Second paragraph</span>");
    expect(html).not.toContain("<p>Second paragraph</p></body>");
  });

  test("preserves blank lines between blocks as Slack spacers", () => {
    const html = runHelper("render", { input: "First paragraph\n\nSecond paragraph" }) as string;

    expect(html).toContain("<p>First paragraph</p><p><br/></p><span>Second paragraph</span>");
  });

  test("renders nested unordered and ordered lists", () => {
    const html = runHelper("render", { input: "- top\n  - child\n\n1. one\n2. two" }) as string;

    expect(html).toContain("<ul><li>top<ul><li>child</li></ul></li></ul>");
    expect(html).toContain("<ol><li>one</li><li>two</li></ol>");
  });

  test("renders inline markdown features without standup-specific handling", () => {
    const html = runHelper("render", {
      input:
        "Since last time:\n\nThis has [a link](https://example.com), bare https://example.org/path, `code`, **bold**, _italics_, and ~~gone~~.",
    }) as string;

    expect(html).toContain("<p>Since last time:</p>");
    expect(html).toContain('<a href="https://example.com">a link</a>');
    expect(html).toContain('<a href="https://example.org/path">https://example.org/path</a>');
    expect(html).toContain("<code>code</code>");
    expect(html).toContain("<strong>bold</strong>");
    expect(html).toContain("<em>italics</em>");
    expect(html).toContain("<s>gone</s>");
  });

  test("builds a prepared clipboard payload without macOS clipboard access", () => {
    const payload = runHelper("payload", { input: "\n\nhello **Slack**\n\n" }) as {
      html: string;
      plainText: string;
    };

    expect(payload.plainText).toBe("hello **Slack**");
    expect(payload.html).toContain("<strong>Slack</strong>");
  });

  test("render payload mode writes prepared JSON to stdout", () => {
    const result = runCli(["--render-payload"], "\n\nhello [Slack](https://slack.com)\n\n");

    expect(result.status).toBe(0);
    expect(result.stderr).toBe("");
    expect(JSON.parse(result.stdout)).toMatchObject({
      plainText: "hello [Slack](https://slack.com)",
    });
    expect(JSON.parse(result.stdout).html).toContain('<a href="https://slack.com">Slack</a>');
  });

  test("render payload mode cannot be combined with paste mode", () => {
    const result = runCli(["--render-payload", "--paste"], "hello");

    expect(result.status).not.toBe(0);
    expect(result.stderr).toContain("--render-payload cannot be combined with --paste");
  });
});

describe("slack rich text input helpers", () => {
  test("trims only surrounding blank lines", () => {
    expect(runHelper("trim", { input: "\n\nOne\n\nTwo\n\n" })).toBe("One\n\nTwo");
  });

  test("prefers stdin when it is present", () => {
    expect(runHelper("select", { clipboardText: "Clipboard text", stdinText: "\n\nstdin text\n\n" })).toEqual({
      plainText: "stdin text",
      source: "stdin",
    });
  });

  test("falls back to clipboard when stdin is absent", () => {
    expect(runHelper("select", { clipboardText: "\n\nclipboard text\n\n", stdinText: null })).toEqual({
      plainText: "clipboard text",
      source: "clipboard",
    });
  });

  test("does not silently fall back when stdin is explicitly empty", () => {
    expect(runHelper("select", { clipboardText: "clipboard text", stdinText: "\n\n" })).toEqual({
      plainText: "",
      source: "stdin",
    });
  });
});

describe("slack rich text paste helper", () => {
  test("waits for Raycast to stop being frontmost before pasting", () => {
    const script = runHelper("paste-script", {}) as string;

    expect(script).toContain("set maxAttempts to 150");
    expect(script).toContain('set visible of application process "Raycast" to false');
    expect(script).toContain('if currentFrontmostApp is not "Raycast" then');
    expect(script).toContain('keystroke "v" using command down');
  });
});
