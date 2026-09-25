# quickshell-emoji

Standalone emoji picker — its **own quickshell config**, separate from the bar
in `~/.config/quickshell`. Deliberately different from the bar:

- fixed violet palette (the bar follows the wallpaper; this doesn't)
- centered overlay-layer card instead of an edge bar
- own fonts: bundled Twemoji (color emoji) + Adwaita Sans

## Use

- `SUPER + .` or `SUPER + SHIFT + E` toggles the picker
- type to search, click a category chip, arrow keys move, `Enter` inserts
- selecting an emoji closes the picker immediately and inserts it into the focused text field
- works with Discord, Instagram, browsers, terminals, and other Wayland/XWayland apps
- native apps and terminals use fast direct `wtype` input; Discord/Instagram/browser clients use a temporary paste hand-off
- `Esc` clears the query first, then closes; clicking outside closes
- the temporary emoji is not left as the active clipboard content; the previous clipboard is restored or cleared
- compact picker: 520×500 by default; adjust `pickerWidth`/`pickerHeight` in `shell.qml`
- needs `wl-clipboard` and `hyprctl`; `wtype` provides the fast direct path for native apps/terminals and a fallback for other clients
- Arch install: `sudo pacman -S wtype wl-clipboard`
- optional newer glyph coverage: `sudo pacman -S noto-fonts-emoji`

## Files

| file | purpose |
|---|---|
| `shell.qml` | the picker (ShellRoot + overlay PanelWindow) |
| `emojis.json` | emoji data — **edit this one** (613 entries, 8 categories) |
| `gen_js.py` | regenerates `emojis.js` from the JSON |
| `emojis.js` | generated QML module, imported by `shell.qml` |
| `toggle.sh` | start-if-needed + toggle via `~/.cache/emoji-shell/cmd` |
| `insert-emoji.sh` | inserts into the focused Hyprland client and restores/clears the clipboard |
| `fonts/TwemojiMozilla.ttf` | bundled color emoji font (from Firefox) |

## Run manually

```sh
qs -p ~/.config/quickshell-emoji
```

This instance intentionally registers **no notification server** — the bar
owns it — so both configs run side by side without conflicts.
