#!/usr/bin/env python3
# Claude Code SessionStart hook: tell herdr to resume this pane inside the same
# bwrap sandbox (ro-env --bwrap) instead of a bare `claude --resume <id>`.
#
# The bwrap argv (with this launch's writable binds) is read from an ancestor
# process now, while claude is running; herdr stores it in session.json and
# runs it after a server / PC restart.
#
# Runs beside herdr's own hook (herdr-agent-state.sh, same source), which
# reports the session without a resume command, so report after a delay to be
# the latest report.

import json
import os
import shlex
import socket
import sys
import time

DELAY = 1.5
SOURCE = "herdr:claude"
RESUME_FLAGS = {"--resume", "-r"}         # take a value
DROP_FLAGS = {"--continue", "-c"}         # no value


def find_bwrap_argv():
    pid = os.getppid()
    while pid > 1:
        try:
            with open(f"/proc/{pid}/cmdline", "rb") as f:
                argv = [a.decode() for a in f.read().split(b"\0")[:-1]]
            with open(f"/proc/{pid}/status") as f:
                ppid = int(next(l for l in f if l.startswith("PPid:")).split()[1])
        except (OSError, StopIteration, ValueError):
            return None
        if argv and os.path.basename(argv[0]) == "bwrap":
            return argv
        pid = ppid
    return None


def resume_argv(argv, session_id):
    # expect: bwrap ... -- [/usr/bin/env K=V...] /usr/bin/bash -lic 'claude [args]'
    argv = list(argv)
    argv[0] = "bwrap"  # herdr requires a plain command name on PATH
    try:
        i = len(argv) - 1 - argv[::-1].index("-lic")
    except ValueError:
        return None
    if i != len(argv) - 2:
        return None
    words = shlex.split(argv[-1])
    if not words or os.path.basename(words[0]) != "claude":
        return None
    out, skip = [], False
    for w in words[1:]:
        if skip:
            skip = False
        elif w in RESUME_FLAGS:
            skip = True
        elif w in DROP_FLAGS or w.startswith("--resume="):
            pass
        else:
            out.append(w)
    argv[-1] = shlex.join([words[0], *out, "--resume", session_id])
    if any("'" in a for a in argv):  # rejected by herdr
        return None
    return argv


def report(params):
    request = {
        "id": f"{SOURCE}:bwrap:{time.time_ns()}",
        "method": "pane.report_agent_session",
        "params": params,
    }
    c = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    c.settimeout(0.5)
    c.connect(os.environ["HERDR_SOCKET_PATH"])
    c.sendall((json.dumps(request) + "\n").encode())
    try:
        return c.recv(4096).decode()
    finally:
        c.close()


def main():
    if os.environ.get("HERDR_ENV") != "1":
        return
    pane_id = os.environ.get("HERDR_PANE_ID")
    if not pane_id or not os.environ.get("HERDR_SOCKET_PATH"):
        return
    try:
        hook = json.load(sys.stdin)
    except ValueError:
        return
    if hook.get("hook_event_name") != "SessionStart" or hook.get("agent_id"):
        return
    session_id = hook.get("session_id")
    if not isinstance(session_id, str) or not session_id:
        return
    bw = find_bwrap_argv()  # read before detaching (ppid changes after fork)
    argv = bw and resume_argv(bw, session_id)
    if not argv:
        return

    params = {
        "pane_id": pane_id,
        "source": SOURCE,
        "agent": "claude",
        "agent_session_id": session_id,
        "resume_argv": argv,
    }
    if isinstance(hook.get("transcript_path"), str):
        params["agent_session_path"] = hook["transcript_path"]
    if isinstance(hook.get("source"), str):
        params["session_start_source"] = hook["source"]

    if os.environ.get("HERDR_RESUME_BWRAP_DEBUG"):  # run in foreground, print reply
        params["seq"] = time.time_ns()
        print(json.dumps(argv))
        print(report(params))
        return

    if os.fork():  # let claude continue; report later from a detached child
        return
    os.setsid()
    null = os.open(os.devnull, os.O_RDWR)  # release the hook's pipes
    for fd in (0, 1, 2):
        os.dup2(null, fd)
    time.sleep(DELAY)
    params["seq"] = time.time_ns()
    try:
        report(params)
    except OSError:
        pass


if __name__ == "__main__":
    main()
