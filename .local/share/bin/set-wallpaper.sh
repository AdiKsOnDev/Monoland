#!/usr/bin/env bash

WALLPAPER_PATH="$1"
MODE="${2:-dark}"
CURRENT_DIR="$HOME/.local/share/monoland"

mkdir -p "$CURRENT_DIR"

rm -f "$CURRENT_DIR/current"
cp "$WALLPAPER_PATH" "$CURRENT_DIR/current"

rm -rf "$HOME/.cache/wal"

if [ "$MODE" = "light" ]; then
    wal -i "$CURRENT_DIR/current" -l -q
else
    wal -i "$CURRENT_DIR/current" -q
fi

# Push new colors to all open terminals
cat "$HOME/.cache/wal/sequences" 2>/dev/null | tee /dev/pts/* > /dev/null 2>&1 || true

# Restart Quickshell to pick up new colors
qs kill
nohup qs > /dev/null 2>&1 &

killall hyprpaper 2>/dev/null || true
nohup hyprpaper > /dev/null 2>&1 &
