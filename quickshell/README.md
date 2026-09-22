# Quickshell config for Hyprland

A full bar + tabbed dashboard + settings app for Hyprland, built with Quickshell (QML), styled after DankMaterialShell.

## Latest round of fixes/features

- **The whole center bar area is now the hover trigger**, not just the small clock pill — hover anywhere in the free space between the left and right icon groups to open the dashboard, much easier to hit than the pill alone.

- **Weather tab expanded**: sunrise/sunset times, UV index, precipitation chance on each hourly forecast slot, and a "last updated" timestamp next to the Refresh button.
- **Audio tab now has a real media player**: auto-picks Spotify if it's among your active MPRIS players (checked by identity/desktop entry), otherwise the first available one. If more than one player is active, chips appear above it so you can switch manually — the Media tab uses the same pick, so they stay in sync.

- **Fixed a real regression from click-outside-to-close**: when I removed each panel's input mask to catch outside clicks, blank space *inside* the card (margins, gaps between cards, the tab bar background) had no `MouseArea` of its own, so clicks there fell through to the background catcher and closed the whole panel — including hovering/clicking empty space in the Overview tab, exactly as reported. Fixed by giving every panel's card its own click-absorbing `MouseArea` so blank space inside the card consumes its own clicks instead of leaking through, while all the actual buttons/sliders/tabs still work normally since they sit on top of it. Applied to all seven panels: dashboard, Wi-Fi, Bluetooth, notifications, power menu, app launcher, and the tray context menu.

- **Click-outside-to-close** — every popup (dashboard, Wi-Fi, Bluetooth, notifications, power menu, app launcher) now closes when you click anywhere outside its card. The click is consumed (standard dropdown behavior), it doesn't also pass through to whatever's underneath.
- **System tray right-click, done properly** — if an app provides its own context menu (most do, via `hasMenu`), we now show *that* (usually already has Quit/Exit from the app itself) instead of guessing. Only apps without one get a small fallback menu (Open / End Task). Honest caveat: "End Task" is best-effort `pkill` by app name — the tray protocol doesn't expose a PID, so there's no fully reliable way to map a tray icon to a process.
- **Notifications, richer**: toasts and the history panel now show the app's icon and name, a color-coded urgency stripe (critical/normal/low), and clickable action buttons pulled from the notification itself. Critical notifications no longer auto-dismiss after 6s — they stay until you dismiss them.
- **SDDM/login picture detection broadened** — now also checks `/usr/share/sddm/faces/`, not just `.face`/AccountsService.
- **Two new optional features**, each with its own on/off switch in Settings → Clock & Bar:
  - **Battery indicator** — auto-hides entirely on desktops with no battery.
  - **Idle inhibitor** — a bar toggle that holds a `systemd-inhibit` lock to keep the screen from sleeping, for presentations/movies/etc.
- Recreated `PowerMenuPanel.qml`, which had been deleted in an earlier pass while the wlogout-fallback code in `Bar.qml` still pointed at it — that fallback path was silently broken until now.

- **Wallpapers now use `awww` exclusively** (not swww) — I'd wrongly assumed "awww" was a typo for swww in an earlier round; it's actually a real, separate tool (a Rust successor to swww: `codeberg.org/LGFae/awww`). Every wallpaper command now calls `awww img`/`awww-daemon` specifically.
- **Wallpaper tab auto-discovers a folder** if the one in Settings is empty or unset — checks `~/Pictures/Wallpapers`, `~/Wallpapers`, `~/.config/wallpapers`, `/usr/share/backgrounds` and uses the first one with images, telling you clearly when it's doing that. An empty/wrong folder was the most likely reason this tab looked broken.
- **Power button now opens `wlogout`** instead of this shell's own power menu, with a fallback to the built-in panel if `wlogout` isn't installed.
- **Bar icons are now toggleable** — Settings → Clock & Bar has a show/hide switch for every bar module (launcher, workspaces, media controls, tray, volume, Wi-Fi, Bluetooth, notifications, power, settings). (If you meant swapping which *glyph* each icon uses rather than show/hide, tell me and I'll add that instead/also.)

- **Bar centering, fixed properly**: the clock now reserves the *same* margin on both sides (whichever of the left/right icon groups is wider), so it's truly screen-centered and mathematically cannot overlap either group, on any screen size.
- **Animated waveform**: the accent-colored icon beside the clock now bounces like an equalizer while a media player is active, and sits still when nothing's playing.
- **Icons are bundled** — a real Material Symbols Rounded font ships in `modules/fonts/` and loads via `FontLoader`, so icons render correctly with zero setup, regardless of what's installed on your system. No more "install this font" step.
- **Volume shows a %** — next to the mute icon in the bar, and under each vertical slider in the new Audio tab.
- **New dedicated Audio tab** in the dashboard — bigger volume/mic/brightness sliders, output/input device names. The Overview tab no longer crams sliders in, so it has room to breathe.
- **Wallpapers tab rebuilt** — the old version's height math didn't match its own header, so content could clip; it's now anchor-based and can't drift out of sync. Applying now also makes sure `awww-daemon` is actually running first (this is why `awww img` silently does nothing if you'd hit that), with a visible error if `awww` isn't installed.
- **Weather tab expanded** — feels-like temp, humidity, wind, a 6-hour forecast strip, and auto-refresh every 15 minutes once you've fetched it once (still starts as "No Weather" + a manual Refresh button on first load, same as the DMS reference).
- **App launcher shows real app icons** now (resolved from each `.desktop` file's `Icon=`, checked against the usual icon-theme locations), not a generic glyph for every entry.
- **Profile picture**: auto-detects your system login picture (`~/.face`, `~/.face.icon`, or AccountsService) for the Overview tab's profile card, with a manual override field in Settings if you'd rather point it somewhere else.
- **More customization in Settings**: a custom accent-color hex field (in addition to the swatches), and a **UI scale slider** (0.8x–1.5x) that resizes the whole shell's fonts/spacing/bar height together — useful for matching how big other apps look on your screen.
- **Notification troubleshooting**: a "Send test notification" button in Settings, plus clearer guidance — if it doesn't show up as a toast here, another daemon (mako/dunst/swaync) already owns the notification service; only one app can hold it at a time, and this shell can't override that from its side.

## Known, still-open issue

Settings has grown a lot — the Appearance tab is now long enough that it scrolls (wrapped in a `Flickable`) rather than clipping. Other tabs are shorter and haven't needed this yet, but if you keep adding things and a tab looks cut off at the bottom, that's the fix: wrap its `Column` in a `Flickable` the same way.

## Earlier fixes (still true)

- `Bar.qml[76]: Unable to assign [undefined] to int` — `trackedNotifications.count` isn't a real property on Quickshell's `ObjectModel`; every `.count` use is `.values.length` now.
- "Could not register notification server... already registered" — another daemon (mako/dunst/swaync) already owns `org.freedesktop.Notifications`. Only one app can hold that name; remove the other one from your Hyprland autostart if you want this shell's notifications to work.
- **`hl.dispatch` / Lua errors are not a bug in this config.** Hyprland 0.55 introduced a Lua-based config system; if your config file is `.lua`, external `hyprctl dispatch` calls (from Quickshell, Waybar, anything) get routed through Lua and old plain-string dispatch is rejected. `Workspaces.qml` sends the newer `hl.dsp.focus({ workspace = N })` syntax as a best effort — if it still errors, switch back to a plain `hyprland.conf`, or check the exact `hl.dsp.*` name your Hyprland version expects.

## What's included

- **Bar**: app launcher + workspace pills (left); animated waveform + clock (true center); inline mini media controls, system tray, volume % + mute, Wi-Fi, Bluetooth, notifications (badge + DND indicator), power, settings (right)
- **App launcher** (apps icon, top-left): search-as-you-type over installed apps, with icons, Enter launches the top match, Esc closes it
- **Tabbed hover dashboard** (hover the center clock): Overview, **Audio**, Media, Wallpapers, Weather, Settings
- **Settings app** (gear icon, or the Settings tab — same shared component either way): Appearance (accent color + custom hex, UI scale, profile picture, bar opacity, weather location, wallpaper folder), Clock & Bar, Notifications (incl. test button), Connectivity, Power, System (hostname/kernel/uptime), Shortcuts, About
- **Volume/brightness OSD**, **Wi-Fi/Bluetooth popups**, **notification history + toasts**, **power menu**

Every popup/dashboard uses an input mask so only the visible card blocks clicks — the rest passes straight through to your desktop. The dashboard and the click-panels (Wi-Fi/Bluetooth/notifications/power/launcher) are mutually exclusive, so they can't collide on narrower screens either.

## Dependencies

- Quickshell (recent build; this uses `PwObjectTracker`, `NotificationServer`, `Mpris`, `SystemTray`, `FileView`/`JsonAdapter`, `FloatingWindow`)
- Hyprland
- `nmcli` (NetworkManager) — Wi-Fi popup
- `bluetoothctl` (BlueZ) — Bluetooth popup
- `brightnessctl` — brightness slider/OSD (optional, no-ops if missing)
- `pipewire` + `wireplumber` — volume control + OSD
- `wlogout` — the power icon in the bar launches this directly. Settings > Power has manual fallback buttons (lock/suspend/restart/shutdown/logout) that don't need it, in case you'd rather not install it.
- `awww` (+ `awww-daemon`) — applying wallpapers from the Wallpapers tab. This is the only wallpaper tool this config uses; if it's not installed, the tab tells you so instead of silently doing nothing.
- Internet access — the Weather tab/card calls the free `api.open-meteo.com` API directly (no key needed); it fails quietly to "Couldn't fetch weather" if you're offline
- `paplay` — notification sound (optional)
- No daemon already bound to `org.freedesktop.Notifications` (see fix above)

None of these being missing will crash the shell — the specific feature tied to a missing binary just won't do anything.

## Install

```bash
mkdir -p ~/.config/quickshell
cp -r quickshell-config/* ~/.config/quickshell/
```

Hyprland autostart:

```
exec-once = qs -c quickshell
```

Test without restarting Hyprland (and see live logs):

```bash
qs -c quickshell
```

Quickshell live-reloads on file changes, so you can leave it running while tweaking `modules/Theme.qml`.

## Customizing

- **Colors / spacing / icon font / UI scale** → `modules/Theme.qml` (or the UI scale slider in Settings)
- **Bar layout** → `modules/Bar.qml`
- **Dashboard tabs/layout** → `modules/Dashboard.qml`
- **Settings sections** → `modules/SettingsPage.qml` (shared by both the standalone app and the dashboard's Settings tab — edit once, applies everywhere)
- **Default settings** → `settings.json` (or change them once from the Settings app — it writes back automatically)

## Known limits / honest caveats

- Multi-monitor: this targets your focused/primary monitor only. Ask if you want the bar duplicated per-screen via `Variants { model: Quickshell.screens }`.
- Wi-Fi only connects to already-known/open networks (no password prompt), to avoid building an insecure plaintext-password dialog. Use `nmtui` for new networks.
- I can't run Hyprland/Quickshell in the environment I write this in, so this is checked against current Quickshell docs and syntax-balanced, not live-tested. If something errors on your machine, paste me the exact log line and I'll fix it directly.
