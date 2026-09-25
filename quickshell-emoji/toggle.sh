#!/usr/bin/env bash
# Toggle the quickshell emoji picker (a separate config instance, see
# ~/.config/quickshell-emoji).
#
#   toggle.sh          start the picker instance if needed, then toggle it
#   toggle.sh start    just make sure the instance is running (login autostart)
#
# The instance watches ~/.cache/emoji-shell/cmd; writing a fresh timestamp to
# it flips the palette open/closed. The file is created BEFORE the instance
# starts so its FileView can attach its watch right away.
set -u

DIR="$HOME/.config/quickshell-emoji"
CACHE="$HOME/.cache/emoji-shell"
CMD="$CACHE/cmd"

mkdir -p "$CACHE"
[ -f "$CMD" ] || : > "$CMD"

# Identifies the emoji instance by scanning /proc directly. The match is
# anchored to the START of the cmdline (qs … or /usr/bin/qs …), so a caller
# shell whose command line merely *mentions* this folder can never
# self-match — which pgrep -f would.
qs_pid() {
    local pid cmd
    for pid in /proc/[0-9]*; do
        pid=${pid#/proc/}
        [ "$pid" = "$$" ] && continue
        # Processes can exit between the glob and the read; ignore that race.
        cmd=$(cat "/proc/$pid/cmdline" 2>/dev/null | tr '\0' ' ')
        case "$cmd" in
            qs*quickshell-emoji*|*/qs\ *quickshell-emoji*)
                echo "$pid"
                return 0 ;;
        esac
    done
    return 1
}

running() {
    qs_pid >/dev/null
}

if ! running; then
    nohup qs -n -d -p "$DIR" >>"$CACHE/qs.log" 2>&1 &
    # give quickshell time to boot and attach its file watch
    for _ in $(seq 1 50); do
        running && break
        sleep 0.1
    done
    sleep 1.0
fi

[ "${1:-}" = "start" ] && exit 0

printf '%s\n' "$(date +%s%N)" > "$CMD"
