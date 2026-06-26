---
id: 2026-06-26-explore-leaner-dotty-run-file-structure
title: Explore leaner dotty run file structure
state: complete
createdAt: 2026-06-26T15:53:34.972Z
updatedAt: 2026-06-26T16:17:03.524Z
---

Explored the current dotty run-file structure. Most `.dotty/commands/*` files are already thin wrappers into `scripts/`; `.dotty/run.sh` is the main mixed-concern file, and `setup_tuicr` is the strongest extraction candidate because it is a full managed-checkout workflow with existing tests. Revised the plan with a concrete recommendation and captured `2026-06-26-extract-tuicr-setup-from-dotty-run-hook` as the first implementation follow-up.
