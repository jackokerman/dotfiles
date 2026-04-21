# Git Prompt Status

The custom Powerlevel10k git segment in [home/.config/zsh/.p10k.zsh](/Users/jackokerman/dotfiles/home/.config/zsh/.p10k.zsh) uses a compact Spaceship-style status block. It only renders when there is something worth noticing.

If you want the legend in a shell, run:

```bash
git-prompt-help
```

That prints the symbol meanings and, when you are inside a repo, also shows the underlying `git status --short --branch` output and recent stashes.

## Legend

- `⇕`: your branch is both ahead of and behind its upstream. Usually fix with `git pull --rebase` and/or `git push` after reconciling history.
- `⇡`: your branch is ahead of its upstream. Usually this just means you have local commits to push.
- `⇣`: your branch is behind its upstream. Usually fix with `git pull --rebase` or whatever sync flow the repo expects.
- `=`: you have merge conflicts. This should usually be temporary while resolving a merge or rebase.
- `$`: you have one or more stash entries. This can persist, but if you do not remember why the stash exists, inspect it with `git stash list` and either apply, drop, or clear it.
- `!`: you have unstaged tracked-file changes. Inspect with `git diff`.
- `+`: you have staged changes. Inspect with `git diff --cached`.
- `?`: you have untracked files. Inspect with `git ls-files --others --exclude-standard`.
- `rebase`, `merge`, `cherry-pick`, `bisect`, etc.: Git has an in-progress action. Finish or abort it before assuming the repo is clean.

## What Should Persist

- `⇡` can persist normally if you just have local commits you have not pushed yet.
- `⇣` or `⇕` can persist if you have intentionally not synced with upstream yet, but they usually indicate pending repo maintenance rather than a stable steady state.
- `$` should usually be deliberate. Long-lived forgotten stashes are a smell because they hide work you are not actively managing.
- `!`, `+`, and `?` are normal during active work. They should disappear when you have either committed, stashed deliberately, or cleaned the worktree.
- `=` and action states such as `rebase` or `merge` should usually be short-lived.

## Quick Cleanup Checks

```bash
git status --short --branch
git diff
git diff --cached
git stash list
git clean -nd
```

Use `git clean -nd` before deleting untracked files so you can see what would be removed.
