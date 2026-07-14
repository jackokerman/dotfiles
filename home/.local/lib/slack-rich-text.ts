#!/usr/bin/env bun

import { execFileSync, spawn } from "node:child_process";
import {
  fstatSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { marked } from "marked@18.0.3";

type InlineToken = {
  type: string;
  href?: string | null;
  raw?: string;
  text?: string;
  tokens?: InlineToken[];
};

type BlockToken = {
  type: string;
  items?: ListItemToken[];
  ordered?: boolean;
  raw?: string;
  text?: string;
  tokens?: BlockToken[] | InlineToken[];
};

type ListItemToken = {
  type: string;
  raw?: string;
  text?: string;
  tokens?: BlockToken[];
};

export type InputSelection = {
  plainText: string;
  source: "clipboard" | "stdin";
};

type CliOptions = {
  help: boolean;
  paste: boolean;
  renderPayload: boolean;
};

const HELP_TEXT = `Usage: slack-rich-text [--paste] [--render-payload]

Convert markdown-ish text into the HTML + plain-text clipboard payload that
Slack preserves as rich text on paste.

Input priority:
1. stdin, when data is piped in
2. the current clipboard contents

Options:
  --render-payload  write the prepared JSON payload to stdout without copying
  --paste   queue a Cmd+V after copying rich text to the clipboard
  --help    show this help text
`;

export function normalizeNewlines(input: string): string {
  return input.replace(/\r\n?/g, "\n");
}

export function trimSurroundingBlankLines(input: string): string {
  return normalizeNewlines(input)
    .replace(/^(?:[ \t]*\n)+/, "")
    .replace(/(?:\n[ \t]*)+$/, "");
}

export function selectPlainTextInput({
  clipboardText,
  stdinText,
}: {
  clipboardText: string;
  stdinText: string | null;
}): InputSelection {
  if (stdinText !== null) {
    return {
      plainText: trimSurroundingBlankLines(stdinText),
      source: "stdin",
    };
  }

  return {
    plainText: trimSurroundingBlankLines(clipboardText),
    source: "clipboard",
  };
}

function escapeHtml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function escapeInlineText(value: string): string {
  return escapeHtml(normalizeNewlines(value).replace(/\n+/g, " "));
}

function escapeMultilineText(value: string): string {
  return escapeHtml(normalizeNewlines(value)).replace(/\n/g, "<br/>");
}

function isSafeHref(href: string | null | undefined): href is string {
  if (!href) {
    return false;
  }

  try {
    const url = new URL(href);
    return url.protocol === "http:" || url.protocol === "https:" || url.protocol === "mailto:";
  } catch {
    return false;
  }
}

function asInlineTokens(token: BlockToken | InlineToken): InlineToken[] {
  if (Array.isArray(token.tokens) && token.tokens.length > 0) {
    return token.tokens as InlineToken[];
  }

  if (typeof token.text === "string" && token.text !== "") {
    return [{ type: "text", text: token.text }];
  }

  return [];
}

function renderInlineTokens(tokens: InlineToken[]): string {
  return tokens
    .map((token) => {
      switch (token.type) {
        case "br":
          return "<br/>";
        case "codespan":
          return `<code>${escapeHtml(token.text ?? "")}</code>`;
        case "del":
          return `<s>${renderInlineTokens(token.tokens ?? [])}</s>`;
        case "em":
          return `<em>${renderInlineTokens(token.tokens ?? [])}</em>`;
        case "escape":
        case "html":
        case "tag":
          return escapeInlineText(token.raw ?? token.text ?? "");
        case "image":
          return escapeInlineText(token.text ?? token.href ?? "");
        case "link": {
          const label = renderPlainInlineTokens(
            token.tokens ?? [{ type: "text", text: token.text ?? token.href ?? "" }],
          );
          if (!isSafeHref(token.href)) {
            return label;
          }
          return `<a href="${escapeHtml(token.href)}">${label}</a>`;
        }
        case "strong":
          return `<strong>${renderInlineTokens(token.tokens ?? [])}</strong>`;
        case "text":
          if (Array.isArray(token.tokens) && token.tokens.length > 0) {
            return renderInlineTokens(token.tokens);
          }
          return escapeInlineText(token.text ?? token.raw ?? "");
        default:
          return escapeInlineText(token.text ?? token.raw ?? "");
      }
    })
    .join("");
}

function renderPlainInlineTokens(tokens: InlineToken[]): string {
  return tokens
    .map((token) => {
      switch (token.type) {
        case "br":
          return "<br/>";
        case "del":
        case "em":
        case "strong":
        case "text":
          if (Array.isArray(token.tokens) && token.tokens.length > 0) {
            return renderPlainInlineTokens(token.tokens);
          }
          return escapeInlineText(token.text ?? token.raw ?? "");
        case "escape":
        case "html":
        case "tag":
          return escapeInlineText(token.raw ?? token.text ?? "");
        case "image":
          return escapeInlineText(token.text ?? token.href ?? "");
        case "link":
          return renderPlainInlineTokens(
            token.tokens ?? [{ type: "text", text: token.text ?? token.href ?? "" }],
          );
        default:
          return escapeInlineText(token.text ?? token.raw ?? "");
      }
    })
    .join("");
}

function renderParagraph(token: BlockToken, options: { inline?: boolean } = {}): string {
  const content = renderInlineTokens(asInlineTokens(token));
  if (options.inline) {
    return `<span>${content}</span>`;
  }

  return `<p>${content}</p>`;
}

function renderCodeBlock(token: BlockToken): string {
  return `<pre><code>${escapeHtml(token.text ?? "")}</code></pre>`;
}

function renderUnsupportedBlock(token: BlockToken): string {
  return `<p>${escapeMultilineText(token.raw ?? token.text ?? "")}</p>`;
}

function renderListItemToken(token: BlockToken): string {
  switch (token.type) {
    case "blockquote":
      return renderBlockquote(token);
    case "code":
      return renderCodeBlock(token);
    case "list":
      return renderList(token);
    case "paragraph":
      return renderParagraph(token);
    case "space":
      return "<p><br/></p>";
    case "text":
      return renderInlineTokens(asInlineTokens(token));
    default:
      return renderUnsupportedBlock(token);
  }
}

function renderListItem(item: ListItemToken): string {
  const content = (item.tokens ?? []).map(renderListItemToken).join("");
  if (content !== "") {
    return `<li>${content}</li>`;
  }

  return `<li>${escapeInlineText(item.text ?? item.raw ?? "")}</li>`;
}

function renderList(token: BlockToken): string {
  const tag = token.ordered ? "ol" : "ul";
  const itemsHtml = (token.items ?? []).map(renderListItem).join("");
  return `<${tag}>${itemsHtml}</${tag}>`;
}

function renderBlockquote(token: BlockToken): string {
  const blocks = (token.tokens as BlockToken[] | undefined) ?? [];
  return `<blockquote>${blocks.map(renderBlock).join("")}</blockquote>`;
}

function renderBlock(token: BlockToken, options: { isLast?: boolean } = {}): string {
  switch (token.type) {
    case "blockquote":
      return renderBlockquote(token);
    case "code":
      return renderCodeBlock(token);
    case "heading":
      return renderParagraph(token, { inline: options.isLast });
    case "list":
      return renderList(token);
    case "paragraph":
      return renderParagraph(token, { inline: options.isLast });
    case "space":
      return "<p><br/></p>";
    default:
      return renderUnsupportedBlock(token);
  }
}

export function renderSlackRichTextHtml(markdown: string): string {
  const trimmed = trimSurroundingBlankLines(markdown);
  const tokens = marked.lexer(trimmed, {
    gfm: true,
  }) as BlockToken[];
  return `<!doctype html><html><body>${tokens
    .map((token, index) => renderBlock(token, { isLast: index === tokens.length - 1 }))
    .join("")}</body></html>`;
}

export type SlackRichTextPayload = {
  html: string;
  plainText: string;
};

export function buildSlackRichTextPayload(markdown: string): SlackRichTextPayload {
  const plainText = trimSurroundingBlankLines(markdown);
  return {
    html: renderSlackRichTextHtml(plainText),
    plainText,
  };
}

function hasPipedStdin(): boolean {
  try {
    return !fstatSync(0).isCharacterDevice();
  } catch {
    return false;
  }
}

function readStdinText(): string | null {
  if (!hasPipedStdin()) {
    return null;
  }

  return readFileSync(0, "utf8");
}

function readClipboardText(): string {
  return execFileSync("pbpaste", { encoding: "utf8" });
}

export function copyRichTextToClipboard(plainText: string, html: string): void {
  const tempDir = mkdtempSync(join(tmpdir(), "slack-rich-text-"));
  const payloadPath = join(tempDir, "payload.json");

  try {
    writeFileSync(payloadPath, JSON.stringify({ html, plainText }), "utf8");

    execFileSync("/usr/bin/osascript", ["-l", "JavaScript", "-"], {
      encoding: "utf8",
      env: {
        ...process.env,
        PAYLOAD_PATH: payloadPath,
      },
      input: `
ObjC.import("AppKit");
ObjC.import("Foundation");

function readPayload() {
    const env = $.NSProcessInfo.processInfo.environment;
    const payloadPath = ObjC.unwrap(env.objectForKey("PAYLOAD_PATH"));
    const data = $.NSData.dataWithContentsOfFile($(payloadPath));
    if (!data) {
        throw new Error("Unable to read clipboard payload");
    }

    const json = ObjC.unwrap($.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding));
    return JSON.parse(json);
}

const payload = readPayload();
const pasteboard = $.NSPasteboard.generalPasteboard;
pasteboard.clearContents;
pasteboard.setStringForType($(payload.html), $.NSPasteboardTypeHTML);
pasteboard.setStringForType($(payload.plainText), $.NSPasteboardTypeString);
`,
    });
  } finally {
    rmSync(tempDir, { force: true, recursive: true });
  }
}

export function buildQueuedPasteScript(): string {
  return `set maxAttempts to 150
set currentFrontmostApp to ""

tell application "System Events"
    set currentFrontmostApp to name of first application process whose frontmost is true
    if currentFrontmostApp is "Raycast" then
        set visible of application process "Raycast" to false
        delay 0.1
    end if
end tell

repeat maxAttempts times
    tell application "System Events"
        set currentFrontmostApp to name of first application process whose frontmost is true
    end tell

    if currentFrontmostApp is not "Raycast" then
        exit repeat
    end if

    delay 0.1
end repeat

if currentFrontmostApp is "Raycast" then
    return
end if

delay 0.05

tell application "System Events"
    keystroke "v" using command down
end tell
`;
}

function queuePaste(): void {
  const child = spawn("/usr/bin/osascript", ["-"], {
    detached: true,
    stdio: ["pipe", "ignore", "ignore"],
  });

  child.stdin.end(buildQueuedPasteScript());
  child.unref();
}

function parseCliArgs(args: string[]): CliOptions {
  const options: CliOptions = {
    help: false,
    paste: false,
    renderPayload: false,
  };

  for (const arg of args) {
    switch (arg) {
      case "--help":
      case "-h":
        options.help = true;
        break;
      case "--paste":
        options.paste = true;
        break;
      case "--render-payload":
        options.renderPayload = true;
        break;
      default:
        throw new Error(`Unknown argument: ${arg}`);
    }
  }

  if (options.renderPayload && options.paste) {
    throw new Error("--render-payload cannot be combined with --paste");
  }

  return options;
}

export async function runCli(args: string[]): Promise<void> {
  const options = parseCliArgs(args);
  if (options.help) {
    console.log(HELP_TEXT);
    return;
  }

  const stdinText = readStdinText();
  const selection = selectPlainTextInput({
    clipboardText: stdinText === null ? readClipboardText() : "",
    stdinText,
  });

  if (selection.plainText.trim() === "") {
    throw new Error(`${selection.source} input is empty`);
  }

  const payload = buildSlackRichTextPayload(selection.plainText);

  if (options.renderPayload) {
    console.log(JSON.stringify(payload));
    return;
  }

  copyRichTextToClipboard(payload.plainText, payload.html);

  if (options.paste) {
    queuePaste();
    console.log("Queued Slack rich-text paste");
    return;
  }

  console.log("Copied Markdown as Slack rich text");
}

if (import.meta.main) {
  runCli(process.argv.slice(2)).catch((error) => {
    const message = error instanceof Error ? error.message : String(error);
    console.error(message);
    process.exit(1);
  });
}
