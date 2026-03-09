#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$HOME/.config/midnight-theme"
cp "$BASE_DIR/theme.palette" "$HOME/.config/midnight-theme/theme.palette"
cp -r "$BASE_DIR/templates" "$HOME/.config/midnight-theme/"
cp "$BASE_DIR/bin/apply-theme.sh" "$HOME/.config/midnight-theme/apply-theme.sh"
chmod +x "$HOME/.config/midnight-theme/apply-theme.sh"

"$HOME/.config/midnight-theme/apply-theme.sh"

echo
echo "Install complete."
echo "Launch app menu with: rofi -show drun"
echo "Launch power menu with: ~/.config/rofi/scripts/powermenu.sh"
echo "Reload polybar with: ~/.config/midnight-theme/reload-polybar.sh"
