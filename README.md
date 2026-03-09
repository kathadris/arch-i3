# Midnight Theme Installer

This package installs a matching theme for:
- Rofi drun
- Rofi power menu
- Polybar

It also gives you **one shared palette file** so you can change the whole look in one place.

## What gets installed

- `~/.config/midnight-theme/theme.palette` — single source of truth for colors, font, and sizes
- `~/.config/midnight-theme/apply-theme.sh` — regenerates all configs after you edit the palette
- `~/.config/rofi/themes/midnight-drun.rasi`
- `~/.config/rofi/themes/midnight-power.rasi`
- `~/.config/rofi/scripts/powermenu.sh`
- `~/.config/polybar/config.ini`
- `~/.config/rofi/config.rasi` — points rofi at the drun theme by default

## Install

From inside the extracted folder:

```bash
chmod +x install.sh
./install.sh
```

## Run

### Rofi app launcher

```bash
rofi -show drun
```

### Rofi power menu

```bash
~/.config/rofi/scripts/powermenu.sh
```

### Polybar reload

```bash
~/.config/midnight-theme/reload-polybar.sh
```

If your Polybar launcher uses a different config path, point it to:

```bash
~/.config/polybar/config.ini
```

Example:

```bash
polybar example -c ~/.config/polybar/config.ini
```

## Change the theme in one place

Edit:

```bash
~/.config/midnight-theme/theme.palette
```

Then apply it everywhere:

```bash
~/.config/midnight-theme/apply-theme.sh
```

That regenerates the rofi and polybar configs from the same palette.

## Most useful values to edit

```bash
ACCENT="#8d2a48"
ACCENT_ALT="#b64563"
SECONDARY="#7aa2c8"
BG0="#05070c"
BG2="#131b2a"
FG0="#d7deea"
BORDER="#243247"
```

### Sizes

```bash
ROFI_DRUN_WIDTH="450px"
ROFI_DRUN_HEIGHT="500px"
ROFI_POWER_WIDTH="450px"
ROFI_POWER_HEIGHT="260px"
POLYBAR_HEIGHT="28pt"
```

## Notes

### Fonts

The configs look best with a Nerd Font such as:
- JetBrainsMono Nerd Font
- Hack Nerd Font
- FiraCode Nerd Font

If icons look wrong, install a Nerd Font or change `FONT_MAIN` in `theme.palette`.

### Power menu commands

The power menu script currently uses:
- `i3lock`
- `pkill -KILL -u "$USER"`
- `systemctl suspend`
- `systemctl reboot`
- `systemctl poweroff`
- `systemctl hibernate`

If you use a different lock screen or logout method, edit:

```bash
~/.config/rofi/scripts/powermenu.sh
```

Then rerun:

```bash
~/.config/midnight-theme/apply-theme.sh
```

### Existing configs

This installer writes directly to:
- `~/.config/rofi/config.rasi`
- `~/.config/polybar/config.ini`

If you already have custom configs there, back them up first.
