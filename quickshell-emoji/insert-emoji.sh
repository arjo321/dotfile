#!/usr/bin/env bash
# Insert an emoji into the currently focused Hyprland client.
#
# Fast path: wtype sends the Unicode character directly, without touching the
# clipboard. Electron-style clients (Discord/Instagram and browsers) use a
# short-lived clipboard plus a Hyprland-dispatched Ctrl+V; terminals use
# Ctrl+Shift+V. The old clipboard is restored (or the temporary selection is
# cleared) before this helper exits.
set -u

if [[ $# -ne 1 || -z "${1:-}" ]]; then
    echo "usage: $0 EMOJI" >&2
    exit 2
fi

emoji=$1
has_wtype=0
command -v wtype >/dev/null 2>&1 && has_wtype=1
has_wl_clipboard=0
command -v wl-copy >/dev/null 2>&1 && command -v wl-paste >/dev/null 2>&1 && has_wl_clipboard=1

if [[ $has_wtype -eq 0 && $has_wl_clipboard -eq 0 ]]; then
    echo "insert-emoji.sh: install wtype (recommended) or wl-clipboard" >&2
    exit 127
fi

# If Hyprland is unavailable, wtype is the only safe direct-input path.
if ! command -v hyprctl >/dev/null 2>&1; then
    if [[ $has_wtype -eq 1 ]]; then
        exec wtype -- "$emoji"
    fi
    echo "insert-emoji.sh: hyprctl is required for automatic paste" >&2
    exit 127
fi

# Give the layer-shell a moment to return focus to the previous client. This
# is deliberately short: the picker itself has already closed immediately.
initial_wait=${EMOJI_FOCUS_DELAY:-0.15}
sleep "$initial_wait"

active_json=$(hyprctl --quiet activewindow -j 2>/dev/null || true)
active_class=$(printf '%s' "$active_json" \
    | sed -n 's/.*"class"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n 1)
active_title=$(printf '%s' "$active_json" \
    | sed -n 's/.*"title"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n 1)
active_address=$(printf '%s' "$active_json" \
    | sed -n 's/.*"address"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n 1)
active_class_lc=$(printf '%s' "$active_class" | tr '[:upper:]' '[:lower:]')
target_lc=$(printf '%s %s' "$active_class" "$active_title" | tr '[:upper:]' '[:lower:]')

is_terminal=0
case "$active_class_lc" in
    kitty|foot|alacritty|wezterm|ghostty|konsole|org.kde.konsole|gnome-terminal|org.gnome.terminal|xterm|uxterm|ptyxis|tilix|terminator|termite|tabby|hyper|warp|rio|st|com.googlecode.iterm2)
        is_terminal=1 ;;
esac

# Ctrl+V is the standard paste shortcut in Discord, Instagram, and browsers.
# Terminals use their separate Ctrl+Shift+V path below.
needs_clipboard=0
if [[ -z "$active_class_lc" ]]; then
    needs_clipboard=1
else
    case "$target_lc" in
        *discord*|*legcord*|*vesktop*|*instagram*|*electron*|*chromium*|*chrome*|*brave*|*vivaldi*|*opera*|*firefox*|*helium*|*zen*)
            needs_clipboard=1 ;;
    esac
fi

if [[ $has_wtype -eq 1 && $needs_clipboard -eq 0 ]]; then
    # Direct Unicode input is the fast path for terminals, Qt/GTK apps, and
    # other native clients. It also avoids clipboard history entirely.
    exec wtype -- "$emoji"
fi

if [[ $has_wl_clipboard -eq 0 ]]; then
    if [[ $has_wtype -eq 1 ]]; then
        exec wtype -- "$emoji"
    fi
    echo "insert-emoji.sh: wl-clipboard is required for browser/Electron paste" >&2
    exit 127
fi

runtime_dir=${XDG_RUNTIME_DIR:-/tmp}
if command -v flock >/dev/null 2>&1; then
    exec 9>"$runtime_dir/quickshell-emoji.lock"
    flock -x 9
fi
if ! old_clipboard=$(mktemp "$runtime_dir/quickshell-emoji.XXXXXX"); then
    echo "insert-emoji.sh: could not create a temporary clipboard file" >&2
    exit 1
fi

had_old_clipboard=0
old_mime=""
copy_pid=""

read_clipboard() {
    if command -v timeout >/dev/null 2>&1; then
        timeout 0.25s "$@"
    else
        "$@"
    fi
}

restore_clipboard() {
    local current=""
    if command -v wl-paste >/dev/null 2>&1; then
        current=$(read_clipboard wl-paste --no-newline 2>/dev/null || true)
    fi

    if [[ -n "$copy_pid" ]] && kill -0 "$copy_pid" 2>/dev/null; then
        kill "$copy_pid" 2>/dev/null || true
        wait "$copy_pid" 2>/dev/null || true
    fi

    if [[ "$current" == "$emoji" ]]; then
        if [[ $had_old_clipboard -eq 1 && -s "$old_clipboard" && -n "$old_mime" ]]; then
            wl-copy --type "$old_mime" <"$old_clipboard" >/dev/null 2>&1 \
                || wl-copy --clear >/dev/null 2>&1 || true
        else
            wl-copy --clear >/dev/null 2>&1 || true
        fi
    fi
    rm -f "$old_clipboard"
}
trap restore_clipboard EXIT INT TERM

# Preserve the previous selection when possible, including image clipboards.
clipboard_types=$(read_clipboard wl-paste --list-types 2>/dev/null || true)
old_mime=$(printf '%s\n' "$clipboard_types" | awk '
    /^image\/png$/ { print; found = 1; exit }
    /^text\/plain/ && !found { print; found = 1 }
')
if [[ -n "$old_mime" ]]; then
    if [[ "$old_mime" == text/* ]]; then
        if read_clipboard wl-paste --type "$old_mime" --no-newline >"$old_clipboard" 2>/dev/null \
            && [[ -s "$old_clipboard" ]]; then
            had_old_clipboard=1
        fi
    else
        if read_clipboard wl-paste --type "$old_mime" >"$old_clipboard" 2>/dev/null \
            && [[ -s "$old_clipboard" ]]; then
            had_old_clipboard=1
        fi
    fi
fi

# Keep the temporary owner alive long enough for the paste request.
wl-copy --foreground --type text/plain "$emoji" >/dev/null 2>&1 &
copy_pid=$!
sleep 0.04
if ! kill -0 "$copy_pid" 2>/dev/null; then
    echo "insert-emoji.sh: could not set the temporary clipboard" >&2
    exit 1
fi

# Do not send a paste key until the new selection is actually readable. Without
# this readiness check, an Electron client can receive the key while it still
# has the previous clipboard cached and paste the user's last copied text.
clipboard_ready=0
for _ in 1 2 3 4 5 6 7 8 9 10; do
    current=$(read_clipboard wl-paste --no-newline 2>/dev/null || true)
    if [[ "$current" == "$emoji" ]]; then
        clipboard_ready=1
        break
    fi
    sleep 0.03
done
if [[ $clipboard_ready -ne 1 ]]; then
    echo "insert-emoji.sh: temporary clipboard did not become ready" >&2
    exit 1
fi

# Electron/browser focus restoration can lag slightly behind the layer-shell;
# give it a little extra time without making the picker itself feel slow.
if [[ $needs_clipboard -eq 1 ]]; then
    sleep ${EMOJI_ELECTRON_WAIT:-0.20}
fi

pasted=0
if [[ $is_terminal -eq 1 ]]; then
    # Kitty and most terminal emulators use Ctrl+Shift+V.
    if [[ $has_wtype -eq 1 ]]; then
        wtype -M ctrl -M shift -k v -m shift -m ctrl && pasted=1
    fi
else
    # Electron/browser clients must receive a compositor-dispatched shortcut.
    # wtype's virtual keyboard events are accepted by many native apps but are
    # ignored by some Discord/Chromium builds, so use Hyprland first here.
    mods="CTRL"
    key="V"
    if [[ -n "$active_address" ]]; then
        dispatch="hl.dsp.send_shortcut({ mods = \"$mods\", key = \"$key\", window = \"address:$active_address\" })"
    else
        dispatch="hl.dsp.send_shortcut({ mods = \"$mods\", key = \"$key\" })"
    fi
    if hyprctl --quiet dispatch "$dispatch" >/dev/null 2>&1; then
        pasted=1
    elif [[ $has_wtype -eq 1 ]]; then
        # Last-resort fallback for a compositor that rejects send_shortcut.
        wtype -M ctrl -k v -m ctrl && pasted=1
    fi
fi

if [[ $pasted -eq 0 ]]; then
    if [[ $is_terminal -eq 1 ]]; then
        mods="CTRL + SHIFT"
        key="V"
    else
        mods="CTRL"
        key="V"
    fi
    if [[ -n "$active_address" ]]; then
        dispatch="hl.dsp.send_shortcut({ mods = \"$mods\", key = \"$key\", window = \"address:$active_address\" })"
    else
        dispatch="hl.dsp.send_shortcut({ mods = \"$mods\", key = \"$key\" })"
    fi
    if ! hyprctl --quiet dispatch "$dispatch" >/dev/null 2>&1; then
        echo "insert-emoji.sh: could not dispatch paste" >&2
        exit 1
    fi
fi

# The temporary selection is restored/cleared by the EXIT trap.
if [[ $has_wtype -eq 0 || $needs_clipboard -eq 1 ]]; then
    sleep ${EMOJI_PASTE_HOLD:-0.65}
else
    sleep ${EMOJI_PASTE_HOLD:-0.20}
fi
