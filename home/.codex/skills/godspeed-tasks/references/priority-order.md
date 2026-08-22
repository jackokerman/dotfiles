# Priority Order

Resolve the category label and matching active top-level smart list dynamically. Read incomplete Next Actions and Someday tasks through `godspeed` so wire-level `list_ordinals` remain available, then filter to top-level tasks carrying the label.

If any matching root has an ordinal for the smart-list ID, roots with explicit ordinals rank first by that ordinal and implicit roots follow by creation time. Compare ordinals as base-62 numbers using Godspeed's digit order `0-9`, `a-z`, then `A-Z`; ordinary locale or ASCII string ordering is incorrect. If none has an ordinal, rank all matching roots by creation time. Nested descendants stay attached to their root and never outrank it. Do not infer priority from title, due date, source-list order, or task recency when smart-list order exists.
