#!/usr/bin/env bash
# notify-send with a jump button, waiting for the click (started by notify.sh via setsid)
# usage: popup.sh <urgency> <state prefix> <pane> <summary> <body>
urgency=$1 state=$2 pane=$3 summary=$4 body=$5

# one notification per pane: replace the previous one and stop its waiter
[[ -s $state.pid ]] && kill -- -"$(<"$state.pid")" 2>/dev/null
echo $$ > "$state.pid"
replace=()
[[ -s $state.id ]] && replace=(-r "$(<"$state.id")")

# -p prints the id first, then the invoked action (empty when closed/expired)
{
  read -r id && echo "$id" > "$state.id"
  read -r action
} < <(notify-send -p -a herdr -h string:desktop-entry:kitty -u "$urgency" "${replace[@]}" \
        -A default=表示 -A focus=表示 "$summary" "$body")

[[ $(<"$state.pid") == $$ ]] && rm -f "$state.pid"
[[ $action == default || $action == focus ]] && exec bash ./focus.sh "$pane"
