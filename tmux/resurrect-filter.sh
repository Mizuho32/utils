#!/usr/bin/env bash
# tmux-resurrect post-save-layout hook: $1 = saved file
# drop tmuxinator-managed sessions (they're recreated by tmuxinator) and
# the client "state" line (no client is attached at restore time)

file="$1"
names=$(sed -n 's/^name:[[:space:]]*//p' ~/.config/tmuxinator/*.yml 2>/dev/null)

awk -F '\t' -v names="$names" '
  BEGIN { n = split(names, a, "\n"); for (i = 1; i <= n; i++) skip[a[i]] = 1 }
  $1 == "state" { next }
  ($1 == "pane" || $1 == "window" || $1 == "grouped_session") && ($2 in skip) { next }
  { print }
' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
