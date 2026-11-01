#!/usr/bin/env bash
# herdr event hook: pane.agent_status_changed -> notify-send (KDE Plasma)
# overview: README.md
# link: herdr plugin link ~/utils/rcfile/herdr/plugins/notify-send

state_dir=${HERDR_PLUGIN_STATE_DIR:-/tmp}
herdr=${HERDR_BIN_PATH:-herdr}

# keep last raw events for debugging payload shape
log=$state_dir/events.log
echo "$HERDR_PLUGIN_EVENT_JSON" >> "$log"
tail -n 300 "$log" > "$log.tmp" && mv "$log.tmp" "$log"

# payload may be the envelope {event, data} or data itself
data=$(jq -c '.data // .' <<< "$HERDR_PLUGIN_EVENT_JSON") || exit 0
status=$(jq -r '.agent_status' <<< "$data")
pane=$(jq -r '.pane_id' <<< "$data")
key=${pane//[^A-Za-z0-9]/_}

# previous status of this pane
last_file=$state_dir/last-status.$key
prev=$(cat "$last_file" 2>/dev/null)
echo "$status" > "$last_file"

# true if the autostart kitty has focus and shows the claudes tab (true when unknown)
kitty_viewing() {
  local sock=${XDG_RUNTIME_DIR:-/run/user/$UID}/kitty-autostart ls
  [[ -S $sock ]] || return 0
  ls=$(kitten @ --to "unix:$sock" ls 2>/dev/null) || return 0
  [[ $(jq -r '.[] | select(.is_focused) | .tabs[] | select(.is_focused) | .title' <<< "$ls") == claudes ]]
}

case $status in
  # only blocked while working (skip prompts right after claude starts)
  blocked) [[ $prev == working ]] || exit 0
           urgency=critical; label='入力待ち' ;;
  done)    urgency=normal;   label='完了' ;;
  # herdr reports idle (not done) for the pane shown in herdr; notify anyway
  # unless that is really on screen (kitty focused and on the claudes tab)
  idle)    [[ $prev == working ]] && ! kitty_viewing || exit 0
           urgency=normal;   label='完了' ;;
  *) exit 0 ;;
esac

ws_id=$(jq -r '.workspace_id' <<< "$data")
agent=$(jq -r '.display_agent // .agent // "agent"' <<< "$data")
title=$(jq -r '.title // ""' <<< "$data")
ws=$("$herdr" workspace list 2>/dev/null | jq -r --arg id "$ws_id" '.result.workspaces[] | select(.workspace_id == $id) | .label' 2>/dev/null)

# notify in background: popup.sh waits for the button click, then focus.sh jumps to the pane
setsid -f bash ./popup.sh "$urgency" "$state_dir/notify.$key" "$pane" \
  "$agent: $label" "${ws:-$ws_id} › $title ($pane)" < /dev/null > /dev/null 2>&1
