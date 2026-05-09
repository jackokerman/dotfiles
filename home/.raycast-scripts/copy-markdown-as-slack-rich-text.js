#!/usr/bin/env bun

// Required parameters:
// @raycast.schemaVersion 1
// @raycast.title Copy Markdown as Slack Rich Text
// @raycast.mode silent
// @raycast.icon 💬
// @raycast.packageName Writing

/**
 * Convert the current clipboard's markdown-ish text into an HTML + plain-text
 * clipboard payload that Slack preserves as rich text on paste.
 *
 * This is intentionally narrow rather than a full CommonMark renderer. It is
 * optimized for short status updates and notes with:
 * - headings
 * - paragraphs
 * - bullet lists (including nested bullets)
 * - inline code
 * - markdown links and bare URLs
 */

import {execFileSync} from "node:child_process";
import {mkdtempSync, rmSync, writeFileSync} from "node:fs";
import {tmpdir} from "node:os";
import {join} from "node:path";

const SECTION_LABELS = new Set([
    "Since last time:",
    "What's next",
    "What's next:",
    "Blockers",
    "Blockers:",
]);

function readClipboardText() {
    return execFileSync("pbpaste", {encoding: "utf8"});
}

function escapeHtml(value) {
    return value
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll('"', "&quot;")
        .replaceAll("'", "&#39;");
}

function formatCodeSpansOnly(text) {
    const codeTokens = [];
    let working = text;

    working = working.replace(/`([^`]+)`/g, (_, code) => {
        const token = `__CODE_ONLY_${codeTokens.length}__`;
        codeTokens.push(code);
        return token;
    });

    working = escapeHtml(working);

    return working.replace(/__CODE_ONLY_(\d+)__/g, (_, index) => {
        return `<code>${escapeHtml(codeTokens[Number(index)])}</code>`;
    });
}

function formatInline(text) {
    const linkTokens = [];
    const codeTokens = [];
    const urlTokens = [];
    let working = text;

    working = working.replace(/\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)/g, (_, label, url) => {
        const token = `__LINK_${linkTokens.length}__`;
        linkTokens.push({label, url});
        return token;
    });

    working = working.replace(/`([^`]+)`/g, (_, code) => {
        const token = `__CODE_${codeTokens.length}__`;
        codeTokens.push(code);
        return token;
    });

    working = working.replace(/https?:\/\/[^\s<]+/g, (url) => {
        const token = `__URL_${urlTokens.length}__`;
        urlTokens.push(url);
        return token;
    });

    working = escapeHtml(working);

    working = working.replace(/__LINK_(\d+)__/g, (_, index) => {
        const {label, url} = linkTokens[Number(index)];
        return `<a href="${escapeHtml(url)}">${formatCodeSpansOnly(label)}</a>`;
    });

    working = working.replace(/__CODE_(\d+)__/g, (_, index) => {
        return `<code>${escapeHtml(codeTokens[Number(index)])}</code>`;
    });

    working = working.replace(/__URL_(\d+)__/g, (_, index) => {
        const url = urlTokens[Number(index)];
        return `<a href="${escapeHtml(url)}">${escapeHtml(url)}</a>`;
    });

    return working;
}

function getIndentLevel(rawLine) {
    const leadingWhitespace = rawLine.match(/^[\t ]*/)?.[0] ?? "";
    const normalized = leadingWhitespace.replaceAll("\t", "  ");
    return Math.floor(normalized.length / 2);
}

function tokenize(input) {
    return input
        .replace(/\r\n?/g, "\n")
        .split("\n")
        .map((rawLine) => {
            const trimmed = rawLine.trim();
            const level = getIndentLevel(rawLine);

            if (trimmed === "") {
                return {type: "blank", level, content: ""};
            }

            const headingMatch = trimmed.match(/^#{1,6}\s+(.+)$/);
            if (headingMatch) {
                return {type: "heading", level, content: headingMatch[1]};
            }

            const bulletMatch = rawLine.trimStart().match(/^[-*•]\s+(.*)$/);
            if (bulletMatch) {
                return {type: "bullet", level, content: bulletMatch[1]};
            }

            return {type: "text", level, content: trimmed};
        });
}

function parseList(tokens, startIndex, level) {
    const items = [];
    let index = startIndex;

    while (index < tokens.length) {
        const token = tokens[index];

        if (token.type === "blank") {
            index += 1;
            break;
        }

        if (token.type !== "bullet" || token.level < level) {
            break;
        }

        if (token.level > level) {
            if (items.length === 0) {
                break;
            }

            const [childList, nextIndex] = parseList(tokens, index, token.level);
            items[items.length - 1].children.push(childList);
            index = nextIndex;
            continue;
        }

        const item = {
            html: formatInline(token.content),
            children: [],
        };
        index += 1;

        while (index < tokens.length) {
            const nextToken = tokens[index];

            if (nextToken.type === "blank") {
                break;
            }

            if (nextToken.type === "text" && nextToken.level > level) {
                item.html += `<br/>${formatInline(nextToken.content)}`;
                index += 1;
                continue;
            }

            if (nextToken.type === "bullet" && nextToken.level > level) {
                const [childList, nextIndex] = parseList(tokens, index, nextToken.level);
                item.children.push(childList);
                index = nextIndex;
                continue;
            }

            break;
        }

        items.push(item);
    }

    return [
        {
            type: "list",
            items,
        },
        index,
    ];
}

function parseBlocks(tokens) {
    const blocks = [];
    let index = 0;

    while (index < tokens.length) {
        const token = tokens[index];

        if (token.type === "blank") {
            index += 1;
            continue;
        }

        if (token.type === "bullet") {
            const [listBlock, nextIndex] = parseList(tokens, index, token.level);
            blocks.push(listBlock);
            index = nextIndex;
            continue;
        }

        if (token.type === "heading") {
            blocks.push({
                type: "paragraph",
                html: `<strong>${formatInline(token.content)}</strong>`,
            });
            index += 1;
            continue;
        }

        if (SECTION_LABELS.has(token.content)) {
            blocks.push({
                type: "paragraph",
                html: `<strong>${formatInline(token.content)}</strong>`,
            });
            index += 1;
            continue;
        }

        blocks.push({
            type: "paragraph",
            html: formatInline(token.content),
        });
        index += 1;
    }

    return blocks;
}

function renderBlock(block) {
    if (block.type === "paragraph") {
        return `<p>${block.html}</p>`;
    }

    if (block.type === "list") {
        const itemsHtml = block.items
            .map((item) => {
                const childrenHtml = item.children.map(renderBlock).join("");
                return `<li>${item.html}${childrenHtml}</li>`;
            })
            .join("");

        return `<ul>${itemsHtml}</ul>`;
    }

    return "";
}

function toHtml(input) {
    const blocks = parseBlocks(tokenize(input));
    return `<!doctype html><html><body>${blocks.map(renderBlock).join("")}</body></html>`;
}

function copyRichTextToClipboard(plainText, html) {
    const tempDir = mkdtempSync(join(tmpdir(), "raycast-slack-rich-text-"));
    const payloadPath = join(tempDir, "payload.json");

    try {
        writeFileSync(payloadPath, JSON.stringify({plainText, html}), "utf8");

        execFileSync(
            "/usr/bin/osascript",
            ["-l", "JavaScript", "-"],
            {
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
            },
        );
    } finally {
        rmSync(tempDir, {recursive: true, force: true});
    }
}

function main() {
    const plainText = readClipboardText().trim();
    if (plainText === "") {
        throw new Error("Clipboard is empty");
    }

    copyRichTextToClipboard(plainText, toHtml(plainText));
    console.log("Copied clipboard text as Slack rich text");
}

main();
