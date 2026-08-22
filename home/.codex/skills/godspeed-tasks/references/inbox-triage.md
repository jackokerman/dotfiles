# Inbox Triage

Use the normalized Inbox snapshot and recommend exactly one outcome per task:

- `candidate_for_completion`
- `move_to_next_actions`
- `move_to_someday`
- `stay_in_inbox`

Use `candidate_for_completion` only with strong evidence that the task is done, superseded, or no longer actionable. Gather local evidence only when `localEvidenceEligible` is true. Keep checks narrow and non-mutating with tools such as `rg`, file-existence checks, and scoped Git status or history. Do not do broad web research; if evidence is inconclusive, use a normal non-completion outcome.
