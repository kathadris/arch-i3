#!/usr/bin/env bash
set -euo pipefail

THEME_DIR="$HOME/.config/midnight-theme"
ROFI_DIR="$HOME/.config/rofi"
ROFI_THEME_DIR="$ROFI_DIR/themes"
ROFI_SCRIPT_DIR="$ROFI_DIR/scripts"
POLYBAR_DIR="$HOME/.config/polybar"

PALETTE_FILE="$THEME_DIR/theme.palette"
APPLY_SCRIPT="$THEME_DIR/apply-theme.sh"
RELOAD_SCRIPT="$THEME_DIR/reload-polybar.sh"
POWER_SCRIPT="$ROFI_SCRIPT_DIR/powermenu.sh"
ROFI_CONFIG="$ROFI_DIR/config.rasi"
POLYBAR_CONFIG="$POLYBAR_DIR/config.ini"

timestamp() {
  date +"%Y%m%d-%H%M%S"
}

backup_file() {
  local f="$1"
  if [ -f "$f" ]; then
    cp -f "$f" "${f}.bak.$(timestamp)"
    echo "Backed up: $f"
  fi
}

ensure_dirs() {
  mkdir -p "$THEME_DIR" "$ROFI_DIR" "$ROFI_THEME_DIR" "$ROFI_SCRIPT_DIR" "$POLYBAR_DIR"
}

write_default_palette() {
  cat > "$PALETTE_FILE" <<'EOF'
# Enchanted forest / gilded mask palette

FONT_MAIN="JetBrainsMono Nerd Font"
FONT_SIZE_ROFI="11"
FONT_SIZE_POLYBAR="11"

BG0="#060b08"
BG1="#0d1511"
BG2="#15201b"
BG3="#223129"

FG0="#dbe2d3"
FG1="#b8c2ae"
FG2="#7d8a79"

ACCENT="#b59a52"
ACCENT_ALT="#d2b96f"
SECONDARY="#6f8f7d"
URGENT="#c6a15b"
BORDER="#2a3a31"
SELECTED="#1b2a22"
ACTIVE="#24372d"

ROFI_MODE="run"
ROFI_DRUN_WIDTH="450px"
ROFI_DRUN_HEIGHT="500px"
ROFI_POWER_WIDTH="450px"
ROFI_POWER_HEIGHT="260px"

POLYBAR_HEIGHT="28pt"
POLYBAR_RADIUS="10"
EOF
}

write_apply_script() {
  cat > "$APPLY_SCRIPT" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

THEME_DIR="$HOME/.config/midnight-theme"
ROFI_DIR="$HOME/.config/rofi"
ROFI_THEME_DIR="$ROFI_DIR/themes"
ROFI_SCRIPT_DIR="$ROFI_DIR/scripts"
POLYBAR_DIR="$HOME/.config/polybar"

PALETTE_FILE="$THEME_DIR/theme.palette"
ROFI_CONFIG="$ROFI_DIR/config.rasi"
POLYBAR_CONFIG="$POLYBAR_DIR/config.ini"
POWER_SCRIPT="$ROFI_SCRIPT_DIR/powermenu.sh"

if [ ! -f "$PALETTE_FILE" ]; then
  echo "Missing palette: $PALETTE_FILE"
  exit 1
fi

# shellcheck disable=SC1090
source "$PALETTE_FILE"

mkdir -p "$THEME_DIR" "$ROFI_DIR" "$ROFI_THEME_DIR" "$ROFI_SCRIPT_DIR" "$POLYBAR_DIR"

cat > "$ROFI_THEME_DIR/enchanted-run.rasi" <<EOF2
* {
    bg0:            ${BG0};
    bg1:            ${BG1};
    bg2:            ${BG2};
    bg3:            ${BG3};

    fg0:            ${FG0};
    fg1:            ${FG1};
    fg2:            ${FG2};

    accent:         ${ACCENT};
    accent-alt:     ${ACCENT_ALT};
    urgent:         ${URGENT};

    border:         ${BORDER};
    selected:       ${SELECTED};
    active:         ${ACTIVE};

    background-color: transparent;
    text-color:       @fg0;
    font:             "${FONT_MAIN} ${FONT_SIZE_ROFI}";
}

configuration {
    modi:                       "run";
    show-icons:                 false;
    disable-history:            false;
    hover-select:               false;
    me-select-entry:            "";
    me-accept-entry:            "MousePrimary";
}

window {
    width:                      ${ROFI_DRUN_WIDTH};
    height:                     ${ROFI_DRUN_HEIGHT};
    location:                   center;
    anchor:                     center;
    fullscreen:                 false;
    transparency:               "real";
    background-color:           rgba(6, 11, 8, 0.92);
    border:                     2px;
    border-color:               @border;
    border-radius:              14px;
    padding:                    18px;
}

mainbox {
    spacing:                    12px;
    children:                   [ "inputbar", "listview" ];
    background-color:           transparent;
}

inputbar {
    spacing:                    10px;
    padding:                    10px 12px;
    border:                     1px;
    border-radius:              10px;
    border-color:               @border;
    background-color:           @bg2;
    children:                   [ "prompt", "entry" ];
}

prompt {
    enabled:                    true;
    text-color:                 @accent-alt;
    background-color:           transparent;
    str:                        "❯";
}

entry {
    placeholder:                "Run command";
    placeholder-color:          @fg2;
    text-color:                 @fg0;
    background-color:           transparent;
}

listview {
    lines:                      8;
    columns:                    1;
    cycle:                      false;
    dynamic:                    false;
    scrollbar:                  true;
    layout:                     vertical;
    spacing:                    8px;
    background-color:           transparent;
    padding:                    4px 0px 0px;
}

scrollbar {
    width:                      4px;
    border:                     0;
    handle-width:               8px;
    handle-color:               @accent;
    background-color:           @bg2;
}

element {
    padding:                    10px;
    border:                     1px;
    border-radius:              10px;
    border-color:               transparent;
    background-color:           transparent;
    text-color:                 @fg0;
}

element normal.normal {
    background-color:           transparent;
    text-color:                 @fg1;
}

element selected.normal {
    background-color:           @selected;
    border-color:               @accent;
    text-color:                 @fg0;
}

element selected.active {
    background-color:           @active;
    border-color:               @accent-alt;
    text-color:                 @fg0;
}

element selected.urgent {
    background-color:           @selected;
    border-color:               @urgent;
    text-color:                 @fg0;
}

element-text {
    background-color:           transparent;
    text-color:                 inherit;
    vertical-align:             0.5;
    margin:                     0px 0px 0px 6px;
}
EOF2

cat > "$ROFI_THEME_DIR/enchanted-power.rasi" <<EOF2
* {
    bg0:            ${BG0};
    bg1:            ${BG1};
    bg2:            ${BG2};
    bg3:            ${BG3};

    fg0:            ${FG0};
    fg1:            ${FG1};
    fg2:            ${FG2};

    accent:         ${ACCENT};
    accent-alt:     ${ACCENT_ALT};
    border:         ${BORDER};
    selected:       ${SELECTED};

    background-color: transparent;
    text-color:       @fg0;
    font:             "${FONT_MAIN} 12";
}

configuration {
    modi:           "run";
    show-icons:     false;
}

window {
    width:                      ${ROFI_POWER_WIDTH};
    height:                     ${ROFI_POWER_HEIGHT};
    location:                   center;
    anchor:                     center;
    fullscreen:                 false;
    transparency:               "real";
    background-color:           rgba(6, 11, 8, 0.94);
    border:                     2px;
    border-color:               @border;
    border-radius:              14px;
    padding:                    18px;
}

mainbox {
    spacing:                    14px;
    children:                   [ "inputbar", "listview" ];
    background-color:           transparent;
}

inputbar {
    padding:                    10px 12px;
    border:                     1px;
    border-radius:              10px;
    border-color:               @border;
    background-color:           @bg2;
    children:                   [ "prompt" ];
}

prompt {
    enabled:                    true;
    str:                        "Power";
    text-color:                 @accent-alt;
    background-color:           transparent;
}

entry {
    enabled:                    false;
}

listview {
    lines:                      2;
    columns:                    3;
    spacing:                    10px;
    cycle:                      false;
    dynamic:                    false;
    scrollbar:                  false;
    layout:                     vertical;
    background-color:           transparent;
}

element {
    padding:                    16px 10px;
    border:                     1px;
    border-radius:              12px;
    border-color:               @border;
    background-color:           @bg1;
    text-color:                 @fg1;
    orientation:                vertical;
}

element selected.normal {
    background-color:           @selected;
    border-color:               @accent;
    text-color:                 @fg0;
}

element-text {
    horizontal-align:           0.5;
    vertical-align:             0.5;
    text-color:                 inherit;
    background-color:           transparent;
}
EOF2

cat > "$POWER_SCRIPT" <<'EOF2'
#!/usr/bin/env bash

theme="$HOME/.config/rofi/themes/enchanted-power.rasi"
options="Lock\nLogout\nSuspend\nReboot\nShutdown\nHibernate"

chosen="$(printf "%b" "$options" | rofi -dmenu -i -p "" -theme "$theme")"

case "$chosen" in
    "Lock")
        if command -v i3lock >/dev/null 2>&1; then
            i3lock
        elif command -v betterlockscreen >/dev/null 2>&1; then
            betterlockscreen -l
        else
            echo "No lock command found."
        fi
        ;;
    "Logout")
        if command -v i3-msg >/dev/null 2>&1; then
            i3-msg exit
        elif command -v bspc >/dev/null 2>&1; then
            bspc quit
        else
            pkill -KILL -u "$USER"
        fi
        ;;
    "Suspend")
        systemctl suspend
        ;;
    "Reboot")
        systemctl reboot
        ;;
    "Shutdown")
        systemctl poweroff
        ;;
    "Hibernate")
        systemctl hibernate
        ;;
esac
EOF2
chmod +x "$POWER_SCRIPT"

cat > "$ROFI_CONFIG" <<EOF2
@theme "~/.config/rofi/themes/enchanted-run.rasi"

configuration {
    modi: "run,drun,window";
    show-icons: false;
}
EOF2

cat > "$POLYBAR_CONFIG" <<EOF2
[colors]
background = ${BG0}
background-alt = ${BG2}
foreground = ${FG0}
primary = ${ACCENT_ALT}
secondary = ${SECONDARY}
alert = ${URGENT}
disabled = ${FG2}
border = ${BORDER}
highlight = ${FG1}

[bar/example]
width = 100%
height = ${POLYBAR_HEIGHT}
radius = ${POLYBAR_RADIUS}

background = \${colors.background}
foreground = \${colors.foreground}

line-size = 3pt
border-size = 4pt
border-color = #00000000

padding-left = 1
padding-right = 1
module-margin = 1

separator = |
separator-foreground = \${colors.disabled}

font-0 = ${FONT_MAIN}:size=${FONT_SIZE_POLYBAR};2
font-1 = monospace:size=${FONT_SIZE_POLYBAR};2

modules-left = xworkspaces xwindow
modules-center = date
modules-right = pulseaudio filesystem memory cpu

cursor-click = pointer
cursor-scroll = ns-resize
enable-ipc = true

[module/systray]
type = internal/tray
format-margin = 8pt
tray-spacing = 12pt

[module/xworkspaces]
type = internal/xworkspaces

label-active = %name%
label-active-background = \${colors.background-alt}
label-active-underline = \${colors.primary}
label-active-foreground = \${colors.foreground}
label-active-padding = 1

label-occupied = %name%
label-occupied-foreground = \${colors.highlight}
label-occupied-padding = 1

label-urgent = %name%
label-urgent-background = \${colors.alert}
label-urgent-foreground = \${colors.foreground}
label-urgent-padding = 1

label-empty = %name%
label-empty-foreground = \${colors.disabled}
label-empty-padding = 1

[module/xwindow]
type = internal/xwindow
label = %title:0:60:...%
label-foreground = \${colors.highlight}

[module/filesystem]
type = internal/fs
interval = 25
mount-0 = /
format-mounted-prefix = "DISK "
format-mounted-prefix-foreground = \${colors.primary}
label-mounted = %mountpoint% %percentage_used%%
label-unmounted = %mountpoint% not mounted
label-unmounted-foreground = \${colors.disabled}

[module/pulseaudio]
type = internal/pulseaudio
format-volume-prefix = "VOL "
format-volume-prefix-foreground = \${colors.primary}
format-volume = <label-volume>
label-volume = %percentage%%
label-volume-foreground = \${colors.foreground}
label-muted = muted
label-muted-foreground = \${colors.disabled}

[module/xkeyboard]
type = internal/xkeyboard
blacklist-0 = num lock
label-layout = %layout%
label-layout-foreground = \${colors.primary}
label-indicator-padding = 2
label-indicator-margin = 1
label-indicator-foreground = \${colors.background}
label-indicator-background = \${colors.secondary}

[module/memory]
type = internal/memory
interval = 2
format-prefix = "RAM "
format-prefix-foreground = \${colors.primary}
label = %percentage_used:2%%
label-foreground = \${colors.foreground}

[module/cpu]
type = internal/cpu
interval = 2
format-prefix = "CPU "
format-prefix-foreground = \${colors.primary}
label = %percentage:2%%
label-foreground = \${colors.foreground}

[module/date]
type = internal/date
interval = 1
date = %Y-%m-%d %l:%M %p
label = %date%
label-foreground = \${colors.primary}

[settings]
screenchange-reload = true
pseudo-transparency = true
EOF2

echo "Applied theme files."
EOF
  chmod +x "$APPLY_SCRIPT"
}

write_reload_script() {
  cat > "$RELOAD_SCRIPT" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if command -v polybar-msg >/dev/null 2>&1; then
  polybar-msg cmd restart >/dev/null 2>&1 && {
    echo "Polybar restarted with polybar-msg."
    exit 0
  }
fi

pkill -x polybar >/dev/null 2>&1 || true
sleep 1

if [ -f "$HOME/.config/polybar/launch.sh" ]; then
  "$HOME/.config/polybar/launch.sh" >/dev/null 2>&1 &
  echo "Polybar relaunched with launch.sh."
  exit 0
fi

if command -v polybar >/dev/null 2>&1; then
  polybar example >/dev/null 2>&1 &
  echo "Polybar launched with bar 'example'."
  exit 0
fi

echo "Polybar not found."
exit 1
EOF
  chmod +x "$RELOAD_SCRIPT"
}

main() {
  ensure_dirs

  backup_file "$ROFI_CONFIG"
  backup_file "$POLYBAR_CONFIG"
  backup_file "$APPLY_SCRIPT"
  backup_file "$RELOAD_SCRIPT"
  backup_file "$POWER_SCRIPT"
  backup_file "$ROFI_THEME_DIR/enchanted-run.rasi"
  backup_file "$ROFI_THEME_DIR/enchanted-power.rasi"
  backup_file "$PALETTE_FILE"

  if [ -f "./theme.palette" ]; then
    cp -f "./theme.palette" "$PALETTE_FILE"
    echo "Using local theme.palette"
  else
    write_default_palette
    echo "Wrote default palette"
  fi

  write_apply_script
  write_reload_script

  "$APPLY_SCRIPT"
  "$RELOAD_SCRIPT" || true

  cat <<EOF

Done.

Files created/updated:
  $PALETTE_FILE
  $APPLY_SCRIPT
  $RELOAD_SCRIPT
  $ROFI_CONFIG
  $ROFI_THEME_DIR/enchanted-run.rasi
  $ROFI_THEME_DIR/enchanted-power.rasi
  $POWER_SCRIPT
  $POLYBAR_CONFIG

To change the theme later:
  edit:  $PALETTE_FILE
  apply: $APPLY_SCRIPT
  reload: $RELOAD_SCRIPT

Launcher commands:
  rofi -show run
  $POWER_SCRIPT
EOF
}

main "$@"
