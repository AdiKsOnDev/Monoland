#!/usr/bin/env bash
# Manages TODO items stored in ~/.local/share/monoland/calendar/todos.json
# Usage:
#   todo-manager.sh list
#   todo-manager.sh add <text>
#   todo-manager.sh toggle <id>
#   todo-manager.sh edit <id> <new text>
#   todo-manager.sh remove <id>

TODOS_FILE="$HOME/.local/share/monoland/calendar/todos.json"

ensure_file() {
    [[ -f "$TODOS_FILE" ]] && return
    mkdir -p "$(dirname "$TODOS_FILE")"
    echo "[]" > "$TODOS_FILE"
}

next_id() {
    jq '[.[].id] | if length == 0 then 0 else max end + 1' "$TODOS_FILE"
}

cmd="$1"
shift

case "$cmd" in
    list)
        ensure_file
        cat "$TODOS_FILE"
        ;;
    add)
        ensure_file
        text="$*"
        id=$(next_id)
        jq --argjson id "$id" --arg text "$text" \
            '. + [{"id": $id, "text": $text, "done": false}]' \
            "$TODOS_FILE" > "$TODOS_FILE.tmp" && mv "$TODOS_FILE.tmp" "$TODOS_FILE"
        cat "$TODOS_FILE"
        ;;
    toggle)
        ensure_file
        id="$1"
        jq --argjson id "$id" \
            'map(if .id == $id then .done = (.done | not) else . end)' \
            "$TODOS_FILE" > "$TODOS_FILE.tmp" && mv "$TODOS_FILE.tmp" "$TODOS_FILE"
        cat "$TODOS_FILE"
        ;;
    edit)
        ensure_file
        id="$1"
        shift
        text="$*"
        jq --argjson id "$id" --arg text "$text" \
            'map(if .id == $id then .text = $text else . end)' \
            "$TODOS_FILE" > "$TODOS_FILE.tmp" && mv "$TODOS_FILE.tmp" "$TODOS_FILE"
        cat "$TODOS_FILE"
        ;;
    remove)
        ensure_file
        id="$1"
        jq --argjson id "$id" 'map(select(.id != $id))' \
            "$TODOS_FILE" > "$TODOS_FILE.tmp" && mv "$TODOS_FILE.tmp" "$TODOS_FILE"
        cat "$TODOS_FILE"
        ;;
    *)
        echo "Usage: $0 {list|add|toggle|edit|remove} [args...]" >&2
        exit 1
        ;;
esac
