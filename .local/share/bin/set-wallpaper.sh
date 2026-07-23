#!/usr/bin/env bash

# Applies a wallpaper: copies it into place, regenerates the pywal palette,
# tells the running quickshell to recolor, and reloads hyprpaper.
#
# NOTE: this script is spawned BY quickshell (the wallpaper picker). It must
# never kill quickshell — doing so tears down this very script mid-run, which
# is why wallpaper changes used to be inconsistent. The shell recolors in
# place via IPC instead.

WALLPAPER_PATH="$1"
MODE="${2:-dark}"
CURRENT_DIR="$HOME/.local/share/monoland"

if [ -z "$WALLPAPER_PATH" ] || [ ! -f "$WALLPAPER_PATH" ]; then
    echo "set-wallpaper: missing or invalid image: '$WALLPAPER_PATH'" >&2
    exit 1
fi

mkdir -p "$CURRENT_DIR"
cp -f "$WALLPAPER_PATH" "$CURRENT_DIR/current"

# wal caches a scheme per image; without clearing it, re-applying the same
# image in a different light/dark mode returns the previously cached palette.
rm -rf "$HOME/.cache/wal/schemes"

if [ "$MODE" = "light" ]; then
    wal -i "$CURRENT_DIR/current" -l -q
else
    wal -i "$CURRENT_DIR/current" -q
fi

# Keep GTK/GNOME apps in step with the chosen theme
if [ "$MODE" = "light" ]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' 2>/dev/null || true
else
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
fi

# Push the new palette to open terminals
cat "$HOME/.cache/wal/sequences" 2>/dev/null | tee /dev/pts/* > /dev/null 2>&1 || true

# Recolor the shell in place (colors.json is fully written by now)
qs ipc call colors reload > /dev/null 2>&1 || true

# hyprpaper caches by path and our path ('current') never changes, so restart
# it to re-read the new image. setsid detaches it into its own session so it
# outlives this script.
killall hyprpaper 2>/dev/null || true
sleep 0.2
setsid hyprpaper > /dev/null 2>&1 &
