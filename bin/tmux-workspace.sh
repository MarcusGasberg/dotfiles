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
  first_pane="$(tmux display-message -t "$session:main" -p '#{pane_id}')"
  [[ -n "${cmds[0]:-}" ]] && tmux send-keys -t "$first_pane" "${cmds[0]}" Enter
  for ((i = 1; i < ${#cmds[@]}; i++)); do
    tmux split-window -t "$session:main" -c "$dir"
    cur_pane="$(tmux display-message -t "$session:main" -p '#{pane_id}')"
    [[ -n "${cmds[i]:-}" ]] && tmux send-keys -t "$cur_pane" "${cmds[i]}" Enter
  done
  tmux select-layout -t "$session:main" "$layout"
  tmux select-pane -t "$first_pane"
fi

if [[ -n "${TMUX:-}" ]]; then
  tmux switch-client -t "$session"
elif [[ -t 1 ]]; then
  tmux attach -t "$session"
fi
