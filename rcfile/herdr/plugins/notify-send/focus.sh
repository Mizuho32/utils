#!/usr/bin/env bash
# jump to a herdr pane: herdr pane -> tmux window -> kitty tab -> KWin window
# usage: focus.sh <pane_id>
pane=$1
herdr=${HERDR_BIN_PATH:-herdr}

"$herdr" agent focus "$pane" > /dev/null 2>&1
tmux select-window -t claudes:herdr 2> /dev/null

# kitty started by autostart.sh listens on $XDG_RUNTIME_DIR/kitty-autostart
sock=${XDG_RUNTIME_DIR:-/run/user/$UID}/kitty-autostart
pid=$(pgrep -o -f -- "--listen-on unix:$sock")
[[ -S $sock && -n $pid ]] || exit 0
kitten @ --to "unix:$sock" focus-tab --match title:claudes > /dev/null 2>&1

# raise the kitty window with a one-shot KWin script (Wayland blocks self-activation)
js=$(mktemp --suffix=.js)
cat > "$js" << JS
for (const w of workspace.windowList())
  if (w.pid == $pid && w.normalWindow) { w.minimized = false; workspace.activeWindow = w; break; }
JS
name=herdr-focus-$$
id=$(qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript "$js" "$name") &&
  qdbus6 org.kde.KWin "/Scripting/Script$id" org.kde.kwin.Script.run > /dev/null
sleep 0.5
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript "$name" > /dev/null
rm -f "$js"
