import { describe, expect, it } from "bun:test";

import {
  entryRole,
  entryText,
  latestTokenUsage,
  parseArgs,
  shouldSearch,
  textFromContent,
  truncate,
} from "../../home/.local/lib/codex-session-snippets";

describe("parseArgs", () => {
  it("parses latest lookup options", () => {
    expect(parseArgs(["--latest", "--query", "prefer", "--limit", "3"])).toEqual({
      latest: true,
      limit: 3,
      query: "prefer",
      threadId: "",
      usage: false,
    });
  });

  it("parses thread lookup options", () => {
    expect(parseArgs(["--thread", "thread-123"])).toEqual({
      latest: false,
      limit: 8,
      query: "",
      threadId: "thread-123",
      usage: false,
    });
  });

  it("parses usage lookup options", () => {
    expect(parseArgs(["--latest", "--usage"])).toEqual({
      latest: true,
      limit: 8,
      query: "",
      threadId: "",
      usage: true,
    });
  });
});

describe("token usage", () => {
  it("returns the latest complete token count event", () => {
    expect(
      latestTokenUsage([
        {
          payload: {
            info: {
              total_token_usage: {
                cache_write_input_tokens: 20,
                cached_input_tokens: 80,
                input_tokens: 100,
                output_tokens: 10,
                reasoning_output_tokens: 3,
                total_tokens: 110,
              },
            },
            type: "token_count",
          },
          type: "event_msg",
        },
      ]),
    ).toEqual({
      cacheWriteInputTokens: 20,
      cachedInputTokens: 80,
      inputTokens: 100,
      outputTokens: 10,
      reasoningOutputTokens: 3,
      totalTokens: 110,
    });
  });

  it("ignores malformed and incomplete token events", () => {
    expect(
      latestTokenUsage([
        { payload: { type: "token_count" }, type: "event_msg" },
        { payload: { info: { total_token_usage: { input_tokens: 10 } } } },
      ]),
    ).toBeUndefined();
  });
});

describe("entry extraction", () => {
  it("joins text content blocks and ignores non-text items", () => {
    expect(textFromContent(["plain", { text: "object text" }, { image: "ignored" }])).toBe(
      "plain\nobject text",
    );
  });

  it("prefers event messages before content fields", () => {
    expect(
      entryText({
        payload: {
          content: "content text",
          message: "event text",
        },
        type: "event_msg",
      }),
    ).toBe("event text");
  });

  it("falls back to summary text when content is unavailable", () => {
    expect(
      entryText({
        payload: {
          summary: [{ text: "summary text" }],
        },
      }),
    ).toBe("summary text");
  });

  it("returns explicit role or event type", () => {
    expect(entryRole({ payload: { role: "assistant" }, type: "response" })).toBe("assistant");
    expect(entryRole({ payload: {}, type: "event_msg" })).toBe("event_msg");
  });
});

describe("snippet filtering", () => {
  it("searches user turns by default and assistant turns only for explicit queries", () => {
    expect(shouldSearch("user", "next time, use the other tool", false)).toBe(true);
    expect(shouldSearch("assistant", "next time, use the other tool", false)).toBe(false);
    expect(shouldSearch("assistant", "next time, use the other tool", true)).toBe(true);
  });

  it("skips injected AGENTS instructions", () => {
    expect(shouldSearch("user", "# AGENTS.md instructions for /repo", false)).toBe(false);
  });

  it("normalizes whitespace before truncating", () => {
    expect(truncate("  one\n\n two\tthree  ")).toBe("one two three");
  });
});
