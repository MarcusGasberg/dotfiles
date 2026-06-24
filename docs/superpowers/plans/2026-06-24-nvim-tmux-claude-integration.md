# nvim ↔ Claude Code ↔ tmux Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make nvim and Claude Code communicate (send context, fix diagnostics, review diffs) and let Claude orchestrate tmux layouts/processes for worktree-based workflows.

**Architecture:** Inbound (nvim → Claude) uses the `coder/claudecode.nvim` plugin with `terminal.provider = "external"` so Claude runs in its own tmux pane and connects to nvim over the WebSocket/MCP IDE protocol. Outbound (Claude → tmux) uses a thin `tmux-workspace.sh` script driven by an optional per-repo `.tmux-workspace.json`, plus a Claude skill that teaches the conventions and the worktree workflow. tmux keybindings glue the two together.

**Tech Stack:** Neovim (Lua, lazy.nvim, snacks.nvim), `claudecode.nvim`, Bash, tmux, jq, Claude Code skills.

## Global Constraints

- Repos live under `~/source/repos`; tmux session name = directory basename with `.` → `_` (copied from `bin/tmux-sessionizer.sh`).
- tmux prefix is `C-a`; existing bindings (lazygit popup `prefix + g`, pane nav, resize) must remain untouched.
- nvim config has **no automated test harness** — nvim-side tasks use explicit manual verification steps. Bash-side tasks have automated tests run against an **isolated tmux server** (`TMUX_TMPDIR`) so the user's live session is never touched.
- New nvim keymaps live under `<leader>a*` and follow the existing pattern: `require("utils.keymap")` + `require("utils.icons").fmt`.
- Per-repo layout files are JSON (parsed with `jq`) — no new dependency, no YAML.
- Claude must only create/manage tmux windows/panes it owns (clear naming, `agent:` prefix for background tasks); never kill panes it did not create.
- Commit after every task. Branch is `arch`; do not touch unrelated working-tree changes.

---

## File Structure

| File | Responsibility |
| --- | --- |
| `nvim/lua/plugins/claudecode.lua` | Plugin spec + keybindings (inbound) — **create** |
| `nvim/lua/utils/claude_diagnostic.lua` | Fix-this-diagnostic helper — **create** |
| `bin/tmux-workspace.sh` | tmux layout applier (outbound) — **create** |
| `bin/tests/tmux-workspace.test.sh` | Automated test for the script — **create** |
| `opencode/skills/tmux-workspace/SKILL.md` | Claude skill teaching conventions + worktree workflow — **create** |
| `tmux/tmux.conf` | tmux glue keybindings — **modify** |
| `docs/superpowers/specs/2026-06-24-nvim-tmux-claude-integration-design.md` | Source spec (reference) |

---

## Phase 1 — Inbound: nvim → Claude Code

### Task 1: Install claudecode.nvim and verify the IDE lockfile path

This task is **gating** — the `.claude → opencode` symlink means nvim and `claude` could write/read the IDE lockfile in different places. Resolve this before building keybindings.

**Files:**
- Create: `nvim/lua/plugins/claudecode.lua`

**Interfaces:**
- Produces: a working `claudecode.nvim` setup with `terminal.provider = "external"`; the user-commands `ClaudeCodeSend`, `ClaudeCodeAdd`, `ClaudeCodeDiffAccept`, `ClaudeCodeDiffDeny` available; an active IDE lockfile that `claude` connects to.

- [ ] **Step 1: Create the minimal plugin spec (no keymaps yet)**

```lua
-- nvim/lua/plugins/claudecode.lua
return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  cond = not vim.g.vscode,
  opts = {
    terminal = { provider = "external" },
  },
  cmd = {
    "ClaudeCode",
    "ClaudeCodeSend",
    "ClaudeCodeAdd",
    "ClaudeCodeDiffAccept",
    "ClaudeCodeDiffDeny",
  },
  config = function(_, opts)
    require("claudecode").setup(opts)
  end,
}
```

- [ ] **Step 2: Install the plugin**

Run: `nvim --headless "+Lazy! sync" +qa`
Expected: completes without error; `grep claudecode nvim/lazy-lock.json` shows a pinned commit.

- [ ] **Step 3: Verify nvim writes a lockfile and find where**

Open nvim (`nvim README.md`), then in another shell run:
`ls -la ~/.claude/ide/ ~/.config/.claude/ide/ ~/.config/opencode/ide/ 2>/dev/null`
Expected: a `*.lock` file (JSON containing a `port`) appears in exactly one of these. Note which directory — call it `IDE_DIR`.

- [ ] **Step 4: Verify `claude` connects from a tmux pane**

In a tmux pane sitting in the same project dir as the open nvim, run `claude`, then inside Claude run `/ide`. Expected: Claude lists/auto-selects the running Neovim instance and reports "Connected". If it cannot find nvim, the lockfile dirs diverged — fix by either pointing `CLAUDE_CONFIG_DIR` at the dir nvim used, or aligning the `.claude` symlink. Re-run until `/ide` connects.

- [ ] **Step 5: Commit**

```bash
git add nvim/lua/plugins/claudecode.lua nvim/lazy-lock.json
git commit -m "feat(nvim): add claudecode.nvim with external tmux terminal provider"
```

---

### Task 2: Inbound keybindings (send selection, add buffer, diff accept/deny)

**Files:**
- Modify: `nvim/lua/plugins/claudecode.lua`

**Interfaces:**
- Consumes: `require("utils.keymap").{normal_map,visual_map}`, `require("utils.icons").fmt` (signature: `fmt(icon_key, text)` → string; `"Copilot"` is a valid icon key).
- Consumes: user-commands from Task 1.
- Produces: keymaps `<leader>as` (v), `<leader>ab`, `<leader>aa`, `<leader>ad` (n).

- [ ] **Step 1: Add keymaps to the `config` function**

Replace the `config` function body in `nvim/lua/plugins/claudecode.lua`:

```lua
  config = function(_, opts)
    require("claudecode").setup(opts)

    local keymap = require("utils.keymap")
    local fmt = require("utils.icons").fmt

    keymap.visual_map("<leader>as", "<cmd>ClaudeCodeSend<cr>", fmt("Copilot", "Send selection to Claude"))
    keymap.normal_map("<leader>ab", function()
      vim.cmd("ClaudeCodeAdd " .. vim.fn.expand("%:p"))
    end, fmt("Copilot", "Add buffer to Claude"))
    keymap.normal_map("<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", fmt("Copilot", "Accept Claude diff"))
    keymap.normal_map("<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", fmt("Copilot", "Deny Claude diff"))
  end,
```

- [ ] **Step 2: Reload and check the maps are registered**

Run: `nvim --headless "+lua vim.cmd('runtime! plugin/**/*.lua')" "+verbose nmap <leader>aa" +qa 2>&1 | head`
Expected: output references `ClaudeCodeDiffAccept`. (If headless lazy-loading hides it, instead verify interactively: open nvim, `:nmap <leader>aa` shows the mapping.)

- [ ] **Step 3: Manual verification — send a selection**

With `claude` connected in a tmux pane (from Task 1): open a file in nvim, visually select a few lines, press `<leader>as`. Expected: the selection appears in Claude as an `@`-mention referencing the file and line range.

- [ ] **Step 4: Manual verification — diff round-trip**

Ask Claude (in its pane) to make a small edit to the open file. Expected: the change surfaces as a diff in nvim; `<leader>aa` applies it, `<leader>ad` rejects it.

- [ ] **Step 5: Commit**

```bash
git add nvim/lua/plugins/claudecode.lua
git commit -m "feat(nvim): add Claude send/add/diff keymaps under <leader>a"
```

---

### Task 3: Fix-this-diagnostic helper

**Files:**
- Create: `nvim/lua/utils/claude_diagnostic.lua`
- Modify: `nvim/lua/plugins/claudecode.lua`

**Interfaces:**
- Consumes: `vim.diagnostic.get`, the `ClaudeCodeSend` range command.
- Produces: `require("utils.claude_diagnostic").send_current_line()` — collects diagnostics on the cursor line, sends the line to Claude as context, and notifies with the diagnostic messages. No-ops with an info notification when the line has no diagnostics.

- [ ] **Step 1: Create the helper module**

```lua
-- nvim/lua/utils/claude_diagnostic.lua
local M = {}

-- Send the current line (with its diagnostics summarized) to Claude as context.
function M.send_current_line()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local diags = vim.diagnostic.get(0, { lnum = lnum - 1 })
  if vim.tbl_isempty(diags) then
    vim.notify("No diagnostics on this line", vim.log.levels.INFO)
    return
  end

  -- Set the '< '> marks to the current line, then run the range-aware send command.
  vim.cmd("normal! V")
  vim.cmd("normal! \27") -- <Esc> commits the visual marks
  vim.cmd("'<,'>ClaudeCodeSend")

  local msgs = {}
  for _, d in ipairs(diags) do
    table.insert(msgs, d.message)
  end
  vim.notify("Sent line to Claude. Fix: " .. table.concat(msgs, " | "), vim.log.levels.INFO)
end

return M
```

- [ ] **Step 2: Wire the keymap in the plugin config**

Add to the `config` function in `nvim/lua/plugins/claudecode.lua`, after the existing keymaps:

```lua
    keymap.normal_map("<leader>af", function()
      require("utils.claude_diagnostic").send_current_line()
    end, fmt("Copilot", "Fix diagnostic with Claude"))
```

- [ ] **Step 3: Manual verification — no diagnostics**

Open a clean file, put the cursor on a line with no diagnostics, press `<leader>af`.
Expected: notification "No diagnostics on this line"; nothing sent to Claude.

- [ ] **Step 4: Manual verification — with a diagnostic**

Introduce an LSP error (e.g. an undefined variable), put the cursor on that line, press `<leader>af`.
Expected: the line is sent to Claude as context, and a notification shows the diagnostic message(s). In the Claude pane, typing "fix this" acts on the referenced line. (Note: auto-submitting the prompt into the external pane is intentionally out of scope here — see Phase 3 for the `prefix + a` named Claude pane that a future enhancement could `tmux send-keys` to.)

- [ ] **Step 5: Commit**

```bash
git add nvim/lua/utils/claude_diagnostic.lua nvim/lua/plugins/claudecode.lua
git commit -m "feat(nvim): add fix-this-diagnostic helper on <leader>af"
```

---

## Phase 2 — Outbound: Claude → tmux orchestration

### Task 4: tmux-workspace.sh with default layout + idempotency (TDD)

**Files:**
- Create: `bin/tmux-workspace.sh`
- Create: `bin/tests/tmux-workspace.test.sh`

**Interfaces:**
- Produces: `tmux-workspace.sh <dir> [layout-file]`. Session name = `basename "$dir" | tr . _`. Idempotent (re-running does not duplicate the session or panes). Default layout = 3 panes (`nvim`, `claude`, shell) in window `main` with `main-vertical`. Attaches/switches only when interactive (`$TMUX` set → `switch-client`; else a tty → `attach`); silent otherwise so it is testable.

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
# bin/tests/tmux-workspace.test.sh — run: bash bin/tests/tmux-workspace.test.sh
set -uo pipefail
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/tmux-workspace.sh"
fail=0
assert_eq() { if [[ "$1" == "$2" ]]; then echo "ok: $3"; else echo "FAIL: $3 (got '$1' want '$2')"; fail=1; fi; }

export TMUX_TMPDIR="$(mktemp -d)"
run() { env -u TMUX TMUX_TMPDIR="$TMUX_TMPDIR" bash "$SCRIPT" "$@" </dev/null >/dev/null 2>&1; }
tmx() { env -u TMUX TMUX_TMPDIR="$TMUX_TMPDIR" tmux "$@"; }

# --- default layout: session + 3 panes ---
proj="$(mktemp -d)/my.app"; mkdir -p "$proj"
run "$proj"
assert_eq "$(tmx has-session -t=my_app 2>/dev/null && echo yes)" "yes" "session created (dot->underscore)"
assert_eq "$(tmx list-panes -t my_app:main 2>/dev/null | wc -l | tr -d ' ')" "3" "default layout has 3 panes"

# --- idempotent: rerun does not duplicate ---
run "$proj"
assert_eq "$(tmx list-sessions 2>/dev/null | wc -l | tr -d ' ')" "1" "idempotent: single session"
assert_eq "$(tmx list-panes -t my_app:main 2>/dev/null | wc -l | tr -d ' ')" "3" "idempotent: still 3 panes"

tmx kill-server 2>/dev/null
rm -rf "$TMUX_TMPDIR"
exit $fail
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash bin/tests/tmux-workspace.test.sh`
Expected: FAIL — script does not exist yet (`run` errors, assertions fail).

- [ ] **Step 3: Write the script (default layout only)**

```bash
#!/usr/bin/env bash
# tmux-workspace.sh <dir> [layout-file]
# Idempotently create a tmux session for <dir> with a standard or per-repo layout.
set -euo pipefail

dir="${1:?usage: tmux-workspace.sh <dir> [layout-file]}"
dir="$(cd "$dir" && pwd)"
layout_file="${2:-$dir/.tmux-workspace.json}"
session="$(basename "$dir" | tr . _)"

if ! tmux has-session -t="$session" 2>/dev/null; then
  layout="main-vertical"
  cmds=("nvim" "claude" "")

  tmux new-session -ds "$session" -c "$dir" -n main
  [[ -n "${cmds[0]:-}" ]] && tmux send-keys -t "$session:main.0" "${cmds[0]}" Enter
  for ((i = 1; i < ${#cmds[@]}; i++)); do
    tmux split-window -t "$session:main" -c "$dir"
    [[ -n "${cmds[i]:-}" ]] && tmux send-keys -t "$session:main.$i" "${cmds[i]}" Enter
  done
  tmux select-layout -t "$session:main" "$layout"
  tmux select-pane -t "$session:main.0"
fi

if [[ -n "${TMUX:-}" ]]; then
  tmux switch-client -t "$session"
elif [[ -t 1 ]]; then
  tmux attach -t "$session"
fi
```

Then: `chmod +x bin/tmux-workspace.sh`

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash bin/tests/tmux-workspace.test.sh`
Expected: all `ok:` lines, exit 0.

- [ ] **Step 5: Commit**

```bash
git add bin/tmux-workspace.sh bin/tests/tmux-workspace.test.sh
git commit -m "feat(tmux): add tmux-workspace.sh with default 3-pane layout"
```

---

### Task 5: Per-repo `.tmux-workspace.json` support (TDD)

**Files:**
- Modify: `bin/tmux-workspace.sh`
- Modify: `bin/tests/tmux-workspace.test.sh`

**Interfaces:**
- Consumes: `jq`; reads `.layout` (default `"main-vertical"`) and `.panes[].cmd` from the layout file.
- Produces: when `<dir>/.tmux-workspace.json` exists, panes/commands/layout come from it instead of the default.

- [ ] **Step 1: Add a failing test for the layout-file path**

Insert before the `tmx kill-server` line in `bin/tests/tmux-workspace.test.sh`:

```bash
# --- per-repo layout file drives panes ---
proj2="$(mktemp -d)/web"; mkdir -p "$proj2"
cat > "$proj2/.tmux-workspace.json" <<'JSON'
{ "layout": "even-horizontal", "panes": [ { "name": "a", "cmd": "cat" }, { "name": "b", "cmd": "cat" } ] }
JSON
run "$proj2"
assert_eq "$(tmx list-panes -t web:main 2>/dev/null | wc -l | tr -d ' ')" "2" "layout file yields 2 panes"
```

- [ ] **Step 2: Run the test to verify the new assertion fails**

Run: `bash bin/tests/tmux-workspace.test.sh`
Expected: the new "layout file yields 2 panes" assertion FAILS (script still creates 3 default panes), exit 1.

- [ ] **Step 3: Read the layout file in the script**

In `bin/tmux-workspace.sh`, replace the two lines that set `layout` and `cmds` (`layout="main-vertical"` and `cmds=("nvim" "claude" "")`) with:

```bash
  if [[ -f "$layout_file" ]]; then
    layout="$(jq -r '.layout // "main-vertical"' "$layout_file")"
    mapfile -t cmds < <(jq -r '.panes[].cmd' "$layout_file")
  else
    layout="main-vertical"
    cmds=("nvim" "claude" "")
  fi
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash bin/tests/tmux-workspace.test.sh`
Expected: all `ok:` lines including the new assertion, exit 0.

- [ ] **Step 5: Commit**

```bash
git add bin/tmux-workspace.sh bin/tests/tmux-workspace.test.sh
git commit -m "feat(tmux): honor per-repo .tmux-workspace.json in tmux-workspace.sh"
```

---

### Task 6: Claude `tmux-workspace` skill

**Files:**
- Create: `opencode/skills/tmux-workspace/SKILL.md`

**Interfaces:**
- Consumes: `bin/tmux-workspace.sh`, `.tmux-workspace.json` format (from Tasks 4–5).
- Produces: a skill that teaches Claude the conventions, the worktree workflow, the hybrid layout rule, and the safety rails.

- [ ] **Step 1: Write the skill file**

```markdown
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
```

- [ ] **Step 2: Verify the skill is discoverable**

Run: `ls opencode/skills/tmux-workspace/SKILL.md && head -3 opencode/skills/tmux-workspace/SKILL.md`
Expected: file exists; frontmatter `name`/`description` present.

- [ ] **Step 3: Manual verification — dry run**

In a Claude session inside a test repo, ask: "Set up a tmux workspace for this project using the tmux-workspace skill." Expected: Claude invokes the skill, runs `tmux-workspace.sh` (or writes a `.tmux-workspace.json`), and reports the session name without touching unrelated panes.

- [ ] **Step 4: Commit**

```bash
git add opencode/skills/tmux-workspace/SKILL.md
git commit -m "feat(skills): add tmux-workspace skill for Claude tmux orchestration"
```

---

## Phase 3 — Glue: tmux keybindings

### Task 7: tmux.conf keybindings for Claude pane + workspace

**Files:**
- Modify: `tmux/tmux.conf`

**Interfaces:**
- Consumes: `bin/tmux-workspace.sh` (Task 4–5).
- Produces: `prefix + a` opens a Claude pane in the current dir; `prefix + C-w` applies the workspace layout to the current dir; `prefix + A` jumps to the next `agent:`-prefixed window.

- [ ] **Step 1: Add the bindings**

Add to `tmux/tmux.conf` immediately after the `bind-key -r f run-shell ...` sessionizer line (keep all existing bindings intact):

```tmux
# AI / Claude workflow
bind a split-window -h -c "#{pane_current_path}" claude
bind C-w run-shell "~/.config/bin/tmux-workspace.sh #{pane_current_path}"
bind A next-window -a -t "agent:"
```

- [ ] **Step 2: Verify the config parses**

Run: `tmux -f tmux/tmux.conf -L cfgcheck new-session -d 2>&1 && tmux -L cfgcheck list-keys 2>/dev/null | grep -E '(\ba\b|C-w)' | head; tmux -L cfgcheck kill-server 2>/dev/null`
Expected: no parse error; the `a` and `C-w` bindings are listed.

- [ ] **Step 3: Manual verification**

In a live tmux session: reload config (`prefix + r`), then `prefix + a`. Expected: a horizontal split opens running `claude` in the current dir. Then `prefix + C-w`. Expected: the current dir's workspace layout is applied/switched to.

- [ ] **Step 4: Commit**

```bash
git add tmux/tmux.conf
git commit -m "feat(tmux): add prefix+a Claude pane, prefix+C-w workspace, prefix+A agent jump"
```

---

## Self-Review

**Spec coverage:**
- Phase 1 inbound (claudecode.nvim, external provider, send selection, add buffer, fix-diagnostic, diff review): Tasks 1–3. ✓
- Lockfile-path risk: Task 1 (gating). ✓
- Phase 2 outbound (`tmux-workspace.sh`, `.tmux-workspace.json`, skill, hybrid rule, worktree workflow, safety rails): Tasks 4–6. ✓
- Phase 3 (background tasks via `agent:` windows, tmux glue bindings): skill in Task 6 + bindings in Task 7. ✓
- Out-of-scope items (opencode integration, Copilot changes, token rotation, tmuxp) — correctly excluded. ✓

**Placeholder scan:** No TBD/TODO; every code step shows full content; commands have expected output. ✓

**Type/name consistency:** `tmux-workspace.sh <dir> [layout-file]`, session naming `basename | tr . _`, window `main`, `.tmux-workspace.json` keys `layout`/`panes[].cmd`, helper `require("utils.claude_diagnostic").send_current_line()`, `fmt(icon_key, text)` with `"Copilot"` icon — consistent across tasks. ✓
