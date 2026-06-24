# nvim ↔ Claude Code ↔ tmux Integration

**Date:** 2026-06-24
**Status:** Approved design, pending implementation plan

## Goal

Close the disconnect between nvim, the Claude Code agent, and tmux. Today Claude
Code runs in a separate terminal, disconnected from what is being edited in nvim,
forcing manual copy-paste of context. This design makes nvim and Claude Code
communicate (inbound) and lets Claude orchestrate tmux layouts and processes
(outbound), built around the existing dotfiles conventions.

## Existing conventions (to extend, not replace)

- Repos live under `~/source/repos`.
- tmux session name = directory basename with `.` → `_` (see `bin/tmux-sessionizer.sh`).
- tmux prefix is `C-a`; lazygit popup on `prefix + g` (`tmux/utility.conf`).
- `jq` and `fzf` already available; `snacks.nvim` already installed in nvim.
- Claude Code config is shared with opencode via the `~/.config/.claude → opencode`
  symlink.

## Architecture

Two directions, three phases.

```
        inbound (context)                outbound (orchestration)
 nvim ───────────────────▶ Claude Code ───────────────────▶ tmux
  (claudecode.nvim,         (external                        (tmux-workspace.sh,
   WebSocket/MCP)            tmux pane)                        skill, layout file)
```

---

## Phase 1 — Inbound: nvim → Claude Code

**Plugin:** `coder/claudecode.nvim` with `folke/snacks.nvim` dependency (already
installed). New file: `nvim/lua/plugins/claudecode.lua`.

**Config:** `terminal.provider = "external"`. nvim starts the WebSocket server and
writes the IDE lockfile; it does not manage a terminal split. Claude runs in a
tmux pane and auto-connects.

**Keybindings** (`<leader>a*`, grouped in which-key as "AI/agent"):

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>as` | visual | Send selection to Claude as context (`:ClaudeCodeSend`) |
| `<leader>ab` | normal | Add current buffer as `@`-mention (`:ClaudeCodeAdd`) |
| `<leader>af` | normal | Fix-this-diagnostic (see below) |
| `<leader>aa` | normal | Accept proposed diff (`:ClaudeCodeDiffAccept`) |
| `<leader>ad` | normal | Deny proposed diff (`:ClaudeCodeDiffDeny`) |

**Fix-this-diagnostic helper:** a small Lua function collects
`vim.diagnostic.get()` for the cursor line, formats the message plus the offending
lines, and sends it to Claude with a "fix this" prompt. Claude may additionally
call the MCP `getDiagnostics` tool for more context.

**Diff review:** Claude's edits surface as native nvim diffs accepted/rejected via
the keys above. Included as the natural counterpart to sending context.

**Risk to resolve in this phase:** confirm the IDE lockfile path. nvim
(claudecode.nvim) and `claude` must agree on `~/.claude/ide/` given the
`.claude → opencode` symlink. If they diverge, set `CLAUDE_CONFIG_DIR` or adjust
the symlink. This is the gating check for Phase 1.

---

## Phase 2 — Outbound: Claude → tmux orchestration

### (a) `~/.config/bin/tmux-workspace.sh`

Thin layout applier. Signature: `tmux-workspace.sh <dir> [layout-file]`.

- Resolves session name from dir basename using the same `tr . _` convention.
- Idempotent: if the session exists, switch/attach — never duplicate.
- Default layout (no per-repo file): pane 0 = `nvim`, split right = `claude`,
  split below the claude pane = shell; uses `main-vertical`.
- If a per-repo layout file is present, it drives panes/commands instead.
- Leaves existing tmux conventions (lazygit popup, prefix) untouched.

### (b) Per-repo layout file — `.tmux-workspace.json` (optional, committed)

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

JSON parsed with `jq` — no new dependency.

### (c) Claude skill — `tmux-workspace`

Lives in the skills dir (`opencode/skills/`, shared with Claude via the symlink).
Teaches Claude:

- Conventions: repo locations, session naming, prefix, the `tmux-workspace.sh`
  script, and the `.tmux-workspace.json` format.
- **Worktree workflow:** `git worktree add` → call `tmux-workspace.sh` for the new
  worktree dir → it gets its own session/window with the standard or per-repo
  layout and relevant processes running.
- **Hybrid rule:** honor `.tmux-workspace.json` if present; otherwise infer
  sensible processes from the project (`package.json` scripts, `Procfile`,
  `Makefile`, etc.).
- **Safety rails:** Claude only creates/manages panes and windows it owns (named
  with an `agent:`/clear prefix), never kills panes it did not create, names
  windows clearly.

---

## Phase 3 — Background tasks + tmux glue

**Background agent tasks:** handled by the `tmux-workspace` skill, no extra
machinery. Since Claude lives in an external tmux pane, "background" means Claude
spawns a **named** tmux window (e.g. `agent:test-watch`, `agent:build`) running a
long task — a headless `claude -p "…"`, a test watcher, a build — then reports
back and continues. The `agent:` prefix ties into the safety rails.

**tmux glue** (additions to `tmux/tmux.conf`):

- `bind a split-window -h -c "#{pane_current_path}" claude` — open a Claude pane in
  the current session on `prefix + a`.
- `bind C-w run-shell "~/.config/bin/tmux-workspace.sh #{pane_current_path}"` —
  apply the workspace layout to the current dir on `prefix + C-w`.
- Optional: a binding to jump to the next `agent:`-prefixed window.

---

## Out of scope (YAGNI)

- opencode nvim integration.
- Copilot configuration changes.
- Rotating the committed `CLOUDFLARE_API_TOKEN` in `.zshrc` (separate task —
  still recommended).
- tmuxp/smug adoption (the thin script + JSON file covers the need).

## Testing / verification

- **Phase 1:** with `claude` running in a tmux pane, `<leader>as` on a visual
  selection shows the context arriving in Claude; a proposed edit appears as an
  nvim diff and `<leader>aa` applies it. Lockfile path verified.
- **Phase 2:** `tmux-workspace.sh <dir>` on a repo with and without
  `.tmux-workspace.json` produces the expected panes; re-running does not
  duplicate the session. Claude, via the skill, sets up a worktree workspace.
- **Phase 3:** `prefix + a` and `prefix + C-w` behave as specified; a Claude-spawned
  `agent:` window runs a background task and is reachable.
