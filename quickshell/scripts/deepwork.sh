#!/usr/bin/env bash
# Tracks deep-work seconds per day in ~/.local/share/monoland/deepwork.json
# Usage:
#   deepwork.sh list             print the {"YYYY-MM-DD": seconds} map
#   deepwork.sh add <seconds>    add seconds to today's total, print the map

FILE="$HOME/.local/share/monoland/deepwork.json"

ensure_file() {
    [[ -f "$FILE" ]] && return
    mkdir -p "$(dirname "$FILE")"
    echo "{}" > "$FILE"
}

case "$1" in
    list)
        ensure_file
        cat "$FILE"
        ;;
    add)
        ensure_file
        secs="${2:-0}"
        today=$(date +%F)
        jq --arg d "$today" --argjson s "$secs" \
            '.[$d] = ((.[$d] // 0) + $s)' "$FILE" > "$FILE.tmp" \
            && mv "$FILE.tmp" "$FILE"
        cat "$FILE"
        ;;
    *)
        echo "Usage: $0 {list|add <seconds>}" >&2
        exit 1
        ;;
esac
