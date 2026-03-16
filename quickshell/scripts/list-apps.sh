#!/usr/bin/env bash

# Reads the GTK icon theme from settings, falls back to hicolor
gtk_settings="$HOME/.config/gtk-3.0/settings.ini"
icon_theme=$(grep -m1 'gtk-icon-theme-name' "$gtk_settings" 2>/dev/null | sed 's/.*=\s*//' | tr -d '"')
[ -z "$icon_theme" ] && icon_theme="hicolor"

resolve_icon() {
    local name="$1"

    # Already an absolute path
    [ -f "$name" ] && echo "$name" && return

    # Search active theme, then hicolor, then pixmaps
    local search_dirs=(
        "/usr/share/icons/$icon_theme/apps/scalable"
        "/usr/share/icons/$icon_theme/apps/48"
        "/usr/share/icons/$icon_theme/apps/32"
        "/usr/share/icons/hicolor/scalable/apps"
        "/usr/share/icons/hicolor/48x48/apps"
        "$HOME/.local/share/icons/$icon_theme/apps/scalable"
        "$HOME/.local/share/icons/hicolor/scalable/apps"
    )

    for dir in "${search_dirs[@]}"; do
        for ext in svg png xpm; do
            [ -f "$dir/$name.$ext" ] && echo "$dir/$name.$ext" && return
        done
    done

    # Pixmaps fallback
    local f
    f=$(find /usr/share/pixmaps -name "${name}.*" 2>/dev/null | head -1)
    echo "$f"
}

find /usr/share/applications "$HOME/.local/share/applications" -name '*.desktop' 2>/dev/null \
| while IFS= read -r f; do
    type=$(grep -m1 '^Type=' "$f" | cut -d= -f2-)
    [ "$type" != 'Application' ] && continue
    grep -qm1 '^NoDisplay=true' "$f" && continue
    grep -qm1 '^Hidden=true'    "$f" && continue

    name=$(grep -m1 '^Name=' "$f" | cut -d= -f2-)
    icon=$(grep -m1 '^Icon=' "$f" | cut -d= -f2-)

    [ -z "$name" ] && continue

    resolved=$(resolve_icon "$icon")
    printf '%s\t%s\t%s\n' "$name" "$resolved" "$f"
done
