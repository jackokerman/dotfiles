import { describe, expect, test } from "bun:test";
import { spawnSync } from "node:child_process";
import { resolve } from "node:path";

const helperScript = resolve(import.meta.dir, "run-helper.ts");

function runHelper(command: "render" | "select" | "trim", payload: Record<string, string | null>) {
  const result = spawnSync("bun", ["--install=auto", helperScript, command, JSON.stringify(payload)], {
    cwd: resolve(import.meta.dir, "../.."),
    encoding: "utf8",
  });

  if (result.status !== 0) {
    throw new Error(result.stderr || `helper exited with ${result.status}`);
  }

  return JSON.parse(result.stdout) as unknown;
}

describe("slack rich text renderer", () => {
  test("renders headings as plain paragraphs", () => {
    const html = runHelper("render", { input: "## Updates:" }) as string;

    expect(html).toContain("<p>Updates:</p>");
    expect(html).not.toContain("<h2>");
    expect(html).not.toContain("<strong>Updates:</strong>");
  });

  test("preserves blank lines between blocks as Slack spacers", () => {
    const html = runHelper("render", { input: "First paragraph\n\nSecond paragraph" }) as string;

    expect(html).toContain("<p>First paragraph</p><p><br/></p><p>Second paragraph</p>");
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
