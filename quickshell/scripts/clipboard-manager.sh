#!/usr/bin/env bash

set -euo pipefail

case "${1:-}" in
    list)
        cliphist list | while IFS= read -r entry; do
            preview="${entry#*$'\t'}"
            [[ "$preview" == "[[ binary data"* ]] && continue
            printf '%s\n' "$entry"
        done
        ;;
    copy)
        [[ $# -eq 2 ]] || exit 2
        cliphist decode "$2" | wl-copy
        ;;
    delete)
        [[ $# -eq 3 ]] || exit 2
        printf '%s\t%s\n' "$2" "$3" | cliphist delete
        ;;
    clear)
        cliphist wipe
        ;;
    *)
        printf 'Usage: %s {list|copy <id>|delete <id> <preview>|clear}\n' "$0" >&2
        exit 2
        ;;
esac
