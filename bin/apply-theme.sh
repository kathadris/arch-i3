#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PALETTE_FILE="$BASE_DIR/theme.palette"
TEMPLATES_DIR="$BASE_DIR/templates"

if [[ ! -f "$PALETTE_FILE" ]]; then
  echo "Missing palette file: $PALETTE_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$PALETTE_FILE"

OUT_BASE="${HOME}/.config/midnight-theme"
ROFI_DIR="${HOME}/.config/rofi"
ROFI_THEME_DIR="${ROFI_DIR}/themes"
ROFI_SCRIPT_DIR="${ROFI_DIR}/scripts"
POLYBAR_DIR="${HOME}/.config/polybar"

mkdir -p "$OUT_BASE" "$ROFI_THEME_DIR" "$ROFI_SCRIPT_DIR" "$POLYBAR_DIR"

render() {
  local input="$1"
  local output="$2"
  cp "$input" "$output"

  local vars=(
    FONT_MAIN FONT_SIZE_ROFI FONT_SIZE_POLYBAR
    BG0 BG1 BG2 BG3
    FG0 FG1 FG2
    ACCENT ACCENT_ALT SECONDARY URGENT BORDER SELECTED ACTIVE
    ROFI_DRUN_WIDTH ROFI_DRUN_HEIGHT ROFI_POWER_WIDTH ROFI_POWER_HEIGHT
    POLYBAR_HEIGHT POLYBAR_RADIUS
  )

  local v value escaped
  for v in "${vars[@]}"; do
    value="${!v}"
    escaped=$(printf '%s' "$value" | sed 's/[\/&]/\\&/g')
    sed -i "s|__${v}__|${escaped}|g" "$output"
  done
}

render "$TEMPLATES_DIR/midnight-drun.rasi.template" "$ROFI_THEME_DIR/midnight-drun.rasi"
render "$TEMPLATES_DIR/midnight-power.rasi.template" "$ROFI_THEME_DIR/midnight-power.rasi"
render "$TEMPLATES_DIR/polybar.ini.template" "$POLYBAR_DIR/config.ini"
render "$TEMPLATES_DIR/powermenu.sh.template" "$ROFI_SCRIPT_DIR/powermenu.sh"
chmod +x "$ROFI_SCRIPT_DIR/powermenu.sh"

cp "$PALETTE_FILE" "$OUT_BASE/theme.palette"
cp "$SCRIPT_DIR/apply-theme.sh" "$OUT_BASE/apply-theme.sh"
chmod +x "$OUT_BASE/apply-theme.sh"

cat > "$ROFI_DIR/config.rasi" <<'ROFI_EOF'
@theme "~/.config/rofi/themes/midnight-drun.rasi"
ROFI_EOF

cat > "$OUT_BASE/launch-drun.sh" <<'LAUNCH_EOF'
#!/usr/bin/env bash
rofi -show drun -theme ~/.config/rofi/themes/midnight-drun.rasi
LAUNCH_EOF
chmod +x "$OUT_BASE/launch-drun.sh"

cat > "$OUT_BASE/reload-polybar.sh" <<'RELOAD_EOF'
#!/usr/bin/env bash
polybar-msg cmd restart >/dev/null 2>&1 || {
  pkill polybar || true
  polybar example &
}
RELOAD_EOF
chmod +x "$OUT_BASE/reload-polybar.sh"

echo "Applied theme files:"
echo "  Rofi drun:   $ROFI_THEME_DIR/midnight-drun.rasi"
echo "  Rofi power:  $ROFI_THEME_DIR/midnight-power.rasi"
echo "  Powermenu:   $ROFI_SCRIPT_DIR/powermenu.sh"
echo "  Polybar:     $POLYBAR_DIR/config.ini"
echo
echo "To change the theme in one place, edit:"
echo "  $OUT_BASE/theme.palette"
echo "Then run:"
echo "  $OUT_BASE/apply-theme.sh"
