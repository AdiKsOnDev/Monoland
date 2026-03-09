#!/usr/bin/env bash

set -e

BOLD="\033[1m"
DIM="\033[2m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

echo -e "${BOLD}"
cat << 'EOF'
  __  __                   _                 _ 
 |  \/  | ___  _ __   ___ | | __ _ _ __   __| |
 | |\/| |/ _ \| '_ \ / _ \| |/ _` | '_ \ / _` |
 | |  | | (_) | | | | (_) | | (_| | | | | (_| |
 |_|  |_|\___/|_| |_|\___/|_|\__,_|_| |_|\__,_|

EOF
echo -e "${RESET}${DIM}  A Monochromatic Hyprland rice with Quickshell widgets${RESET}"
echo ""

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info()    { echo -e "  ${BOLD}${GREEN}✓${RESET}  $1"; }
warn()    { echo -e "  ${BOLD}${YELLOW}!${RESET}  $1"; }
section() { echo -e "\n  ${BOLD}$1${RESET}"; }
die()     { echo -e "  ${BOLD}${RED}✗${RESET}  $1"; exit 1; }

section "Checking for existing AUR helper..."

AUR_HELPER=""

if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
    info "paru found"
elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
    info "yay found"
else
    warn "No AUR helper found — installing paru..."
    sudo pacman -S --needed --noconfirm base-devel git
    local_paru_dir="$(mktemp -d)"
    git clone https://aur.archlinux.org/paru.git "$local_paru_dir"
    (cd "$local_paru_dir" && makepkg -si --noconfirm)
    rm -rf "$local_paru_dir"
    AUR_HELPER="paru"
    info "paru installed"
fi

section "Checking dependencies..."

# Map: <command to check>: <package name to install>
declare -A DEP_PACKAGES=(
    [quickshell]="quickshell-git"
    [grimblast]="grimblast-git"
    [swappy]="swappy"
    [brightnessctl]="brightnessctl"
    [hyprpaper]="hyprpaper"
    [wal]="python-pywal"
    [kitty]="kitty"
)

MISSING=()

for cmd in "${!DEP_PACKAGES[@]}"; do
    if command -v "$cmd" &>/dev/null; then
        info "$cmd"
    else
        warn "$cmd ${DIM}(not found)${RESET}"
        MISSING+=("${DEP_PACKAGES[$cmd]}")
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    echo ""
    warn "Installing missing packages: ${MISSING[*]}"
    "$AUR_HELPER" -S --needed --noconfirm "${MISSING[@]}"
    info "All dependencies installed"
fi

section "Checking fonts..."

MISSING_FONTS=()

check_font() {
    local name="$1"
    local pkg="$2"
    if fc-list | grep -qi "$name"; then
        info "$name"
    else
        warn "$name ${DIM}(not found)${RESET}"
        MISSING_FONTS+=("$pkg")
    fi
}

check_font "Poppins"   "ttf-poppins"
check_font "JetBrains" "ttf-jetbrains-mono-nerd"

if [ ${#MISSING_FONTS[@]} -gt 0 ]; then
    echo ""
    warn "Installing missing fonts: ${MISSING_FONTS[*]}"
    "$AUR_HELPER" -S --needed --noconfirm "${MISSING_FONTS[@]}"
    fc-cache -f
    info "Fonts installed"
fi

section "Installing wallpapers..."

mkdir -p "$HOME/Pictures/Wallpapers"
cp -n "$REPO_DIR/Wallpapers/"* "$HOME/Pictures/Wallpapers/" 2>/dev/null && \
    info "Copied wallpapers to ~/Pictures/Wallpapers" || \
    info "Wallpapers already present, skipping"

section "Setting up initial wallpaper..."

MONOLAND_DIR="$HOME/.local/share/monoland"
mkdir -p "$MONOLAND_DIR"

FIRST_WALL="$(ls "$HOME/Pictures/Wallpapers/" | head -1)"
if [ -n "$FIRST_WALL" ] && [ ! -f "$MONOLAND_DIR/current" ]; then
    cp "$HOME/Pictures/Wallpapers/$FIRST_WALL" "$MONOLAND_DIR/current"
    info "Set $FIRST_WALL as initial wallpaper"
    wal -i "$MONOLAND_DIR/current" -q && info "Generated initial pywal colors" || warn "wal failed, please run it manually"
else
    info "Initial wallpaper already set, skipping"
fi

cp -r "$REPO_DIR/icons" "$MONOLAND_DIR/"

section "Installing config files..."

install_config() {
    local src="$1"
    local dest="$HOME/.config/$(basename "$src")"
    if [ -d "$dest" ]; then
        warn "~/.config/$(basename "$src") already exists, backing up to ${dest}.bak"
        mv "$dest" "${dest}.bak"
    fi
    cp -r "$src" "$dest"
    info "$(basename "$src") → ~/.config/"
}

install_config "$REPO_DIR/hypr"
install_config "$REPO_DIR/kitty"
install_config "$REPO_DIR/quickshell"

section "Installing scripts..."

mkdir -p "$HOME/.local/share/bin"
cp "$REPO_DIR/.local/share/bin/"* "$HOME/.local/share/bin/"
chmod +x "$HOME/.local/share/bin/"*
info "Scripts → ~/.local/share/bin/"

if [[ ":$PATH:" != *":$HOME/.local/share/bin:"* ]]; then
    warn "~/.local/share/bin is not in your PATH, consider adding it to your shell profile"
fi

echo ""
echo -e "  ${BOLD}${GREEN}All done!${RESET}"
echo -e "  ${DIM}Run ${RESET}${BOLD}qs${RESET}${DIM} to start the shell.${RESET}"
echo ""
