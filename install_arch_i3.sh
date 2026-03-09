#!/usr/bin/env bash
set -u

FAIL_LOG="$HOME/arch-i3-install-failures.txt"
YAY_BUILD_DIR="${HOME}/.cache/yay-bootstrap"
MODULES_LOAD_FILE="/etc/modules-load.d/nvidia.conf"
MKINITCPIO_FILE="/etc/mkinitcpio.conf"

# Requested package list normalized for Arch package names.
OFFICIAL_PACKAGES=(
  kitty
  thunar
  thunar-volman
  thunar-shares-plugin
  thunar-archive-plugin
  tumbler
  xdg-user-dirs
  xdg-user-dirs-gtk
  picom
  polybar
  rofi
  gnome-text-editor
  gnome-calculator
  gnome-calendar
  gnome-keyring
  polkit-gnome
  discord
  firefox
  thunderbird
  opencl-nvidia
  pianobar
  cmus
  python-pillow
  ntfs-3g
  gvfs-smb
  gvfs
  gvfs-mtp
  eog
  libreoffice-still
  nitrogen
  flameshot
  lxappearance
  htop
  screenfetch
  speedtest-cli
  fastfetch
  ttf-dejavu
  ttf-font-awesome
  ttf-liberation
  duf
  calibre
  nvidia-utils
  xorg-xrandr
  arandr
  libxml2-legacy
  python-pip
)

# Requested AUR packages, minus entries that actually belong in official repos or the base system.
AUR_PACKAGES=(
  hexchat
  mousam
  cndrvcups-lt
  minecraft-launcher
  visual-studio-code-bin
)

FAILED_PACKAGES=()
INSTALLED_PACKAGES=()
SKIPPED_PACKAGES=()

log() {
  printf '[%s] %s\n' "$(date '+%F %T')" "$*"
}

record_failure() {
  local pkg="$1"
  local reason="$2"
  FAILED_PACKAGES+=("$pkg :: $reason")
  printf '%s :: %s\n' "$pkg" "$reason" >> "$FAIL_LOG"
}

is_installed() {
  pacman -Q "$1" >/dev/null 2>&1
}

install_official_pkg() {
  local pkg="$1"

  if is_installed "$pkg"; then
    log "Already installed: $pkg"
    SKIPPED_PACKAGES+=("$pkg")
    return 0
  fi

  log "Installing official package: $pkg"
  if sudo pacman -S --needed --noconfirm "$pkg"; then
    if is_installed "$pkg"; then
      INSTALLED_PACKAGES+=("$pkg")
      return 0
    fi
    record_failure "$pkg" "pacman reported success but verification failed"
    return 1
  fi

  record_failure "$pkg" "pacman install failed"
  return 1
}

install_aur_pkg() {
  local pkg="$1"

  if is_installed "$pkg"; then
    log "Already installed: $pkg"
    SKIPPED_PACKAGES+=("$pkg")
    return 0
  fi

  log "Installing AUR package: $pkg"
  if yay -S --needed --noconfirm "$pkg"; then
    if is_installed "$pkg"; then
      INSTALLED_PACKAGES+=("$pkg")
      return 0
    fi
    record_failure "$pkg" "yay reported success but verification failed"
    return 1
  fi

  record_failure "$pkg" "yay install failed"
  return 1
}

setup_failure_log() {
  : > "$FAIL_LOG"
  printf 'Arch i3 install failure log\nGenerated: %s\n\n' "$(date)" > "$FAIL_LOG"
}

bootstrap_sudo() {
  log "Requesting sudo credentials (one prompt expected)."
  sudo -v || {
    echo "Unable to obtain sudo credentials." >&2
    exit 1
  }

  while true; do
    sudo -n true
    sleep 50
    kill -0 "$$" || exit
  done 2>/dev/null &
  SUDO_KEEPALIVE_PID=$!
}

cleanup() {
  if [[ -n "${SUDO_KEEPALIVE_PID:-}" ]]; then
    kill "$SUDO_KEEPALIVE_PID" >/dev/null 2>&1 || true
  fi
}

trap cleanup EXIT

bootstrap_yay() {
  if command -v yay >/dev/null 2>&1; then
    log "yay already installed."
    return 0
  fi

  log "Installing prerequisites for yay."
  sudo pacman -S --needed --noconfirm git base-devel || {
    record_failure "yay prerequisites" "failed to install git/base-devel"
    return 1
  }

  rm -rf "$YAY_BUILD_DIR"
  mkdir -p "$YAY_BUILD_DIR"

  log "Cloning yay from AUR."
  if ! git clone https://aur.archlinux.org/yay.git "$YAY_BUILD_DIR/yay"; then
    record_failure "yay" "failed to clone AUR repository"
    return 1
  fi

  pushd "$YAY_BUILD_DIR/yay" >/dev/null || return 1
  log "Building and installing yay."
  if ! makepkg -si --noconfirm; then
    popd >/dev/null || true
    record_failure "yay" "makepkg failed"
    return 1
  fi
  popd >/dev/null || true

  if ! command -v yay >/dev/null 2>&1; then
    record_failure "yay" "installation completed but binary not found"
    return 1
  fi

  log "yay installed successfully."
}

install_nvidia_kernel_driver() {
  local driver_pkg="nvidia-dkms"

  if ! is_installed dkms; then
    install_official_pkg dkms || true
  fi

  for kernel in linux linux-lts linux-zen linux-hardened; do
    if is_installed "$kernel"; then
      install_official_pkg "${kernel}-headers" || true
    fi
  done

  install_official_pkg "$driver_pkg" || true
}

configure_nvidia_modules() {
  local desired_modules=(nvidia nvidia_modeset nvidia_drm nvidia_uvm)

  log "Writing ${MODULES_LOAD_FILE}."
  sudo install -d /etc/modules-load.d
  {
    printf '%s\n' "nvidia"
    printf '%s\n' "nvidia_modeset"
    printf '%s\n' "nvidia_drm"
    printf '%s\n' "nvidia_uvm"
  } | sudo tee "$MODULES_LOAD_FILE" >/dev/null || {
    record_failure "nvidia modules-load" "failed to write ${MODULES_LOAD_FILE}"
    return 1
  }

  if [[ -f "$MKINITCPIO_FILE" ]]; then
    log "Ensuring NVIDIA modules are present in ${MKINITCPIO_FILE}."
    sudo cp "$MKINITCPIO_FILE" "${MKINITCPIO_FILE}.bak.$(date +%s)"

    if grep -q '^MODULES=(' "$MKINITCPIO_FILE"; then
      local existing new_line
      existing="$(grep '^MODULES=(' "$MKINITCPIO_FILE" | head -n1)"
      new_line='MODULES=(nvidia nvidia_modeset nvidia_drm nvidia_uvm)'
      sudo sed -i "0,/^MODULES=(/s|^MODULES=(.*)|${new_line}|" "$MKINITCPIO_FILE" || {
        record_failure "mkinitcpio.conf" "failed to update MODULES line"
        return 1
      }
    else
      printf '\nMODULES=(nvidia nvidia_modeset nvidia_drm nvidia_uvm)\n' | sudo tee -a "$MKINITCPIO_FILE" >/dev/null || {
        record_failure "mkinitcpio.conf" "failed to append MODULES line"
        return 1
      }
    fi

    log "Rebuilding initramfs with mkinitcpio -P."
    if ! sudo mkinitcpio -P; then
      record_failure "mkinitcpio -P" "initramfs rebuild failed"
      return 1
    fi
  else
    record_failure "mkinitcpio.conf" "${MKINITCPIO_FILE} not found"
    return 1
  fi
}


configure_picom() {
  local picom_dir="$HOME/.config/picom"
  local picom_file="$picom_dir/picom.conf"

  log "Writing Picom config to ${picom_file}."
  mkdir -p "$picom_dir" || {
    record_failure "picom config" "failed to create ${picom_dir}"
    return 1
  }

  cat > "$picom_file" <<'EOF'
backend = "glx";
vsync = true;

corner-radius = 2;
rounded-corners-exclude = [
  "window_type = 'dock'",
  "window_type = 'desktop'"
];

fading = true;
shadow = true;

active-opacity = 1.0;
inactive-opacity = 1.0;
frame-opacity = 1.0;

opacity-rule = [
  "90:class_g = 'kitty'",
  "90:class_g = 'Kitty'"
];

blur-method = "none";
EOF
}

print_summary() {
  echo
  echo "================ SUMMARY ================"
  echo "Installed: ${#INSTALLED_PACKAGES[@]}"
  echo "Skipped already present: ${#SKIPPED_PACKAGES[@]}"
  echo "Failures: ${#FAILED_PACKAGES[@]}"
  echo "Failure log: $FAIL_LOG"

  if (( ${#FAILED_PACKAGES[@]} > 0 )); then
    echo
    echo "Failed items:"
    printf '  - %s\n' "${FAILED_PACKAGES[@]}"
  fi
}

main() {
  setup_failure_log
  bootstrap_sudo

  log "Refreshing package databases."
  sudo pacman -Sy --noconfirm || {
    record_failure "pacman sync" "failed to refresh package databases"
  }

  install_nvidia_kernel_driver

  for pkg in "${OFFICIAL_PACKAGES[@]}"; do
    install_official_pkg "$pkg" || true
  done

  bootstrap_yay

  if command -v yay >/dev/null 2>&1; then
    for pkg in "${AUR_PACKAGES[@]}"; do
      install_aur_pkg "$pkg" || true
    done
  else
    for pkg in "${AUR_PACKAGES[@]}"; do
      record_failure "$pkg" "yay unavailable, AUR packages not attempted"
    done
  fi

  if command -v yay >/dev/null 2>&1; then
    log "Updating user package database metadata via yay."
    yay -Y --gendb >/dev/null 2>&1 || true
  fi

  configure_nvidia_modules || true
  configure_picom || true

  if command -v xdg-user-dirs-update >/dev/null 2>&1; then
    log "Updating XDG user directories."
    xdg-user-dirs-update || true
  fi

  print_summary

  if (( ${#FAILED_PACKAGES[@]} == 0 )); then
    log "All requested tasks completed successfully. Reboot is recommended."
    exit 0
  else
    log "Completed with some failures. Review $FAIL_LOG before rebooting."
    exit 1
  fi
}

main "$@"
