---
name: slack-clipboard
description: Use when Slack message wording is already drafted and the goal is to copy or paste it as Slack-preserved rich text from macOS, using the shared `slack-rich-text` helper instead of hand-fixing formatting after paste. Prefer authenticated Slack delivery tools when the user wants the message actually sent or delivered.
---

# Slack Clipboard

Use this skill after the message content is already approved. Its job is the clipboard and paste workflow, not the drafting.

## When To Use It

- The user wants a Slack-ready message copied to the macOS clipboard with rich-text formatting preserved on paste.
- The user explicitly wants you to trigger the paste into the already-focused composer.
- The message should stay local and manual rather than being sent through a Slack API tool.

## Prefer Delivery Tools When Appropriate

- If the user wants the message sent, scheduled, or delivered to themselves in Slack, prefer authenticated Slack tools instead of this skill.
- Use this skill for clipboard-oriented workflows, especially when the user is about to paste into Slack manually.

## Commands

- Pipe approved markdown straight into the helper:

```bash
printf '%s' "$MESSAGE" | ~/.local/bin/slack-rich-text
```

- If the message is already in the clipboard, run the helper with no stdin:

```bash
~/.local/bin/slack-rich-text
```

- Only when the user explicitly asks to paste and the target composer is already focused:

```bash
printf '%s' "$MESSAGE" | ~/.local/bin/slack-rich-text --paste
```

## Defaults

- Treat the helper as generic markdown-to-Slack conversion. Do not add standup-specific parsing or rewrite the content during copy.
- Trim only surrounding blank lines before copying.
- Do not mutate the clipboard or trigger a paste unless the user clearly asked for that side effect.
- For Slack-facing links, use plain semantic link labels instead of code-formatted labels. Prefer `[useGetMerchantId](...)` over ``[`useGetMerchantId`](...)`` because Slack, especially on mobile, already distinguishes links and nested code styling adds noise.
