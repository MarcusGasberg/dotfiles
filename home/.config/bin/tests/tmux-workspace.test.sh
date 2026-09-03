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
assert_eq "$(tmx display-message -t my_app:main -p '#{pane_index}')" "1" "focus lands on editor (first) pane"

# --- idempotent: rerun does not duplicate ---
run "$proj"
assert_eq "$(tmx list-sessions 2>/dev/null | wc -l | tr -d ' ')" "1" "idempotent: single session"
assert_eq "$(tmx list-panes -t my_app:main 2>/dev/null | wc -l | tr -d ' ')" "3" "idempotent: still 3 panes"

# --- per-repo layout file drives panes ---
proj2="$(mktemp -d)/web"; mkdir -p "$proj2"
cat > "$proj2/.tmux-workspace.json" <<'JSON'
{ "layout": "even-horizontal", "panes": [ { "name": "a", "cmd": "cat" }, { "name": "b", "cmd": "cat" } ] }
JSON
run "$proj2"
assert_eq "$(tmx list-panes -t web:main 2>/dev/null | wc -l | tr -d ' ')" "2" "layout file yields 2 panes"

tmx kill-server 2>/dev/null
rm -rf "$TMUX_TMPDIR"
exit $fail
