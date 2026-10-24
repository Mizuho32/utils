#!/usr/bin/env bash
# herdr event hook: pane.agent_status_changed -> notify-send (KDE Plasma)
# link: herdr plugin link ~/utils/rcfile/herdr/plugins/notify-send

state_dir=${HERDR_PLUGIN_STATE_DIR:-/tmp}
herdr=${HERDR_BIN_PATH:-herdr}

# keep last raw events for debugging payload shape
log=$state_dir/events.log
echo "$HERDR_PLUGIN_EVENT_JSON" >> "$log"
tail -n 100 "$log" > "$log.tmp" && mv "$log.tmp" "$log"

# payload may be the envelope {event, data} or data itself
data=$(jq -c '.data // .' <<< "$HERDR_PLUGIN_EVENT_JSON") || exit 0
status=$(jq -r '.agent_status' <<< "$data")
case $status in
  blocked) urgency=critical; label='入力待ち' ;;
  done)    urgency=normal;   label='完了' ;;
  *) exit 0 ;;
esac

pane=$(jq -r '.pane_id' <<< "$data")
ws_id=$(jq -r '.workspace_id' <<< "$data")
agent=$(jq -r '.display_agent // .agent // "agent"' <<< "$data")
title=$(jq -r '.title // ""' <<< "$data")
ws=$("$herdr" workspace list 2>/dev/null | jq -r --arg id "$ws_id" '.result.workspaces[] | select(.workspace_id == $id) | .label' 2>/dev/null)

# one notification per pane: replace the previous one instead of stacking
id_file=$state_dir/notify-id.${pane//[^A-Za-z0-9]/_}
replace=()
[[ -s $id_file ]] && replace=(-r "$(<"$id_file")")

notify-send -p -a herdr -h string:desktop-entry:kitty -u "$urgency" "${replace[@]}" \
  "$agent: $label" "${ws:-$ws_id} › $title ($pane)" > "$id_file"

# TODO: action button to jump to the pane (not implemented yet)
#   notify-send blocks with -A until clicked, so run it in background, e.g.
#   ( act=$(notify-send ... -A focus=開く); [[ $act == focus ]] && {
#       "$herdr" agent focus "$pane"
#       # kitty @ = control kitty windows/tabs (herdr itself is controlled by herdr CLI).
#       # needs kitty.conf: allow_remote_control yes / listen_on unix:@kitty
#       # kitty @ --to unix:@kitty focus-tab --match title:claudes
#   } ) &
