import {
  buildSlackRichTextPayload,
  buildQueuedPasteScript,
  renderSlackRichTextHtml,
  selectPlainTextInput,
  trimSurroundingBlankLines,
} from "../../home/.local/lib/slack-rich-text";

type Command = "paste-script" | "payload" | "render" | "select" | "trim";

function main() {
  const [command, payloadJson] = process.argv.slice(2) as [Command | undefined, string | undefined];
  if (!command || !payloadJson) {
    throw new Error("Usage: run-helper.ts <paste-script|payload|render|select|trim> <payload-json>");
  }

  const payload = JSON.parse(payloadJson) as Record<string, string | null>;

  switch (command) {
    case "render":
      console.log(JSON.stringify(renderSlackRichTextHtml(String(payload.input ?? ""))));
      return;
    case "payload":
      console.log(JSON.stringify(buildSlackRichTextPayload(String(payload.input ?? ""))));
      return;
    case "select":
      console.log(
        JSON.stringify(
          selectPlainTextInput({
            clipboardText: String(payload.clipboardText ?? ""),
            stdinText: typeof payload.stdinText === "string" ? payload.stdinText : null,
          }),
        ),
      );
      return;
    case "trim":
      console.log(JSON.stringify(trimSurroundingBlankLines(String(payload.input ?? ""))));
      return;
    case "paste-script":
      console.log(JSON.stringify(buildQueuedPasteScript()));
      return;
    default:
      throw new Error(`Unknown command: ${String(command)}`);
  }
}

main();
