#!/usr/bin/env bash
# Manages TODO items stored in ~/.local/share/monoland/calendar/todos.json
# Each item: {id, text, done, priority (0-3), due ("YYYY-MM-DD" or "")}
# Usage:
#   todo-manager.sh list
#   todo-manager.sh add <text>
#   todo-manager.sh toggle <id>
#   todo-manager.sh edit <id> <new text>
#   todo-manager.sh remove <id>
#   todo-manager.sh priority <id> <0-3>
#   todo-manager.sh due <id> <YYYY-MM-DD|"">
#   todo-manager.sh clear-done
#   todo-manager.sh reorder <id> <id> ...

TODOS_FILE="$HOME/.local/share/monoland/calendar/todos.json"

ensure_file() {
    [[ -f "$TODOS_FILE" ]] && return
    mkdir -p "$(dirname "$TODOS_FILE")"
    echo "[]" > "$TODOS_FILE"
}

# Backfill any legacy items that predate priority/due, then print.
normalize_and_print() {
    jq 'map({id, text, done, priority: (.priority // 0), due: (.due // "")})' "$TODOS_FILE"
}

write() {
    jq "$@" "$TODOS_FILE" > "$TODOS_FILE.tmp" && mv "$TODOS_FILE.tmp" "$TODOS_FILE"
}

next_id() {
    jq '[.[].id] | if length == 0 then 0 else max end + 1' "$TODOS_FILE"
}

cmd="$1"
shift

ensure_file

case "$cmd" in
    list)
        normalize_and_print
        ;;
    add)
        id=$(next_id)
        write --argjson id "$id" --arg text "$*" \
            '. + [{"id": $id, "text": $text, "done": false, "priority": 0, "due": ""}]'
        normalize_and_print
        ;;
    toggle)
        write --argjson id "$1" 'map(if .id == $id then .done = (.done | not) else . end)'
        normalize_and_print
        ;;
    edit)
        id="$1"; shift
        write --argjson id "$id" --arg text "$*" 'map(if .id == $id then .text = $text else . end)'
        normalize_and_print
        ;;
    remove)
        write --argjson id "$1" 'map(select(.id != $id))'
        normalize_and_print
        ;;
    priority)
        write --argjson id "$1" --argjson p "$2" 'map(if .id == $id then .priority = $p else . end)'
        normalize_and_print
        ;;
    due)
        write --argjson id "$1" --arg d "$2" 'map(if .id == $id then .due = $d else . end)'
        normalize_and_print
        ;;
    clear-done)
        write 'map(select(.done | not))'
        normalize_and_print
        ;;
    reorder)
        order=$(printf '%s\n' "$@" | jq -R 'tonumber' | jq -s '.')
        write --argjson ord "$order" 'sort_by(.id as $i | ($ord | index($i)) // 999)'
        normalize_and_print
        ;;
    *)
        echo "Usage: $0 {list|add|toggle|edit|remove|priority|due|clear-done|reorder} [args...]" >&2
        exit 1
        ;;
esac
