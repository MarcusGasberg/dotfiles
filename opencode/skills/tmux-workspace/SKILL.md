---
name: tmux-workspace
description: Use when setting up a tmux workspace for a project or git worktree, or when launching background processes in tmux. Teaches the dotfiles conventions and the worktree workflow.
---

# tmux-workspace

Set up and manage tmux workspaces for this user's machine.

## Conventions

- Repos live under `~/source/repos`.
- A tmux session is named after the directory basename with `.` replaced by `_`.
- tmux prefix is `C-a`. Do not rebind it.
- Apply a workspace layout by running: `~/.config/bin/tmux-workspace.sh <dir> [layout-file]`.
  It is idempotent — safe to re-run; it never duplicates a session.

## Layout: hybrid rule

1. If `<dir>/.tmux-workspace.json` exists, `tmux-workspace.sh` uses it. Prefer this.
2. Otherwise the script applies the default layout: panes `nvim`, `claude`, and a shell.
3. When neither fits the task, infer relevant processes from the project and either
   write a `.tmux-workspace.json` or issue `tmux` commands directly. Infer from
   `package.json` scripts (`dev`, `start`, `test`), `Procfile`, `Makefile`, etc.

`.tmux-workspace.json` format:

```json
{
  "layout": "main-vertical",
  "panes": [
    { "name": "editor", "cmd": "nvim" },
    { "name": "server", "cmd": "npm run dev" },
    { "name": "agent",  "cmd": "claude" }
  ]
}
```

## Worktree workflow

To start work on a new branch in an isolated worktree:

1. `git worktree add ../<repo>-<branch> <branch>` (or create the branch).
2. `~/.config/bin/tmux-workspace.sh <path-to-new-worktree>` — the worktree gets its
   own session with the standard or per-repo layout and its processes running.
3. Report the session name so the user can switch to it (`prefix` then `s`, or
   `tmux switch-client -t <session>`).

## Background tasks

For a long-running task (test watcher, build, headless `claude -p "..."`):

- Create a **named** window prefixed with `agent:`, e.g.
  `tmux new-window -n agent:test-watch -c <dir> 'npm test -- --watch'`.
- Report the window name; the user reaches it with `prefix` + window number or `prefix` + `w`.

## Safety rails

- Only create or manage windows/panes you created. Name them clearly; use the
  `agent:` prefix for background-task windows.
- Never kill, resize, or send keys to panes/windows you did not create.
- Never rebind keys or change `tmux.conf` as part of a workspace setup.
