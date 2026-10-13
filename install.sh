#!/usr/bin/env bash
#
# install.sh — end-to-end Arch Linux + Hyprland setup. Idempotent: safe to run again.
#
#   New machine:  bash <(curl -fsSL https://raw.githubusercontent.com/etieppo/archlinux/main/install.sh)
#   Re-run:       ~/install.sh
#   System only:  ~/install.sh --sync      (re-apply ~/.system after editing a system file)
#
# How configs are managed:
#   • Home: a bare repository (~/.archlinux) whose work tree is $HOME — the `dot` alias.
#     Files live exactly where programs look for them; no symlinks involved.
#   • System: ~/.system mirrors the filesystem root (~/.system/etc/pacman.conf → /etc/pacman.conf)
#     and is COPIED as root:root. Symlinking /etc into $HOME breaks in three ways:
#       - udev, modprobe and the locale are read before /home is mounted;
#       - services sandboxed with ProtectHome=yes (systemd-logind, systemd-localed) cannot see /home;
#       - pacman hooks, udev rules and mkinitcpio.conf run as root, so a file your user can edit
#         becomes a privilege escalation.
#   • Everything hardware-specific (GPU driver, microcode, kernel headers, TUXEDO drivers, audio
#     firmware, kernel command line) is detected and generated here, never versioned.

# Re-exec under bash when started by sh or zsh (e.g. `zsh install.sh` after switching shells).
if [ -z "${BASH_VERSION:-}" ]; then
  if [ -f "$0" ]; then exec bash "$0" "$@"; fi
  echo "Run it with bash: bash install.sh" >&2
  exit 1
fi
set +o posix                   # `sh install.sh` lands here as bash in POSIX mode
set -Eeuo pipefail
shopt -s nullglob
umask 022

# ══ Configuration ═════════════════════════════════════════════════════════════

# ── Repositories ──────────────────────────────────────────────────────────────
GITHUB_USER="etieppo"
DOTFILES_REPO="archlinux"
DOTFILES_URL="https://github.com/$GITHUB_USER/$DOTFILES_REPO.git"    # HTTPS: no SSH key needed
DOTFILES_PUSH_URL="git@github.com:$GITHUB_USER/$DOTFILES_REPO.git"
NVIM_URL="https://github.com/$GITHUB_USER/nvim.git"
NVIM_PUSH_URL="git@github.com:$GITHUB_USER/nvim.git"
OMZ_URL="https://github.com/ohmyzsh/ohmyzsh.git"
YAY_URL="https://aur.archlinux.org/yay.git"

# ── Paths ─────────────────────────────────────────────────────────────────────
DOTFILES_DIR="$HOME/.archlinux"                   # bare repo; must match the `dot` alias
SYSTEM_DIR="$HOME/.system"                       # mirrors /: .system/etc/x → /etc/x
NVIM_DIR="$HOME/.config/nvim"
OMZ_DIR="$HOME/.oh-my-zsh"
GREETER_INSTALLER="$HOME/.config/quickshell/greeter/install.sh"
HYPR_GPU_CONF="$HOME/.config/hypr/gpu.lua"       # generated; hyprland.lua loads it with require("gpu")
BACKUP_DIR="$HOME/.archlinux-backup/$(date +%Y%m%d-%H%M%S)"

# ── Preferences ───────────────────────────────────────────────────────────────
LOGIN_SHELL="/usr/bin/zsh"
PLYMOUTH_THEME="arch-logo-symbol"
KERNEL_PARAMS=(quiet splash)                     # appended to the boot entries when missing
GTK_THEME="Ant"
ICON_THEME="Ant"
COLOR_SCHEME="prefer-dark"
REBOOT_AFTER_INSTALL=true                        # first install only, never on re-runs

# ── Official packages ─────────────────────────────────────────────────────────
PKGS_BASE=(
  base-devel git openssh zsh unzip tree lua pacman-contrib
  networkmanager bluez bluez-utils avahi nss-mdns power-profiles-daemon
)
PKGS_AUDIO=(pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber pavucontrol)
PKGS_DESKTOP=(
  hyprland hyprpaper hyprpicker xdg-desktop-portal-hyprland quickshell greetd plymouth
  ghostty thunar gvfs tumbler ffmpegthumbnailer file-roller
  grim wl-clipboard cliphist wtype brightnessctl gammastep geoclue darkman
  adwaita-icon-theme gsettings-desktop-schemas
)
PKGS_FONTS=(noto-fonts ttf-jetbrains-mono-nerd)  # noto-fonts: chosen provider of ttf-font
PKGS_APPS=(chromium btop yazi steam)
PKGS_DEV=(neovim rustup bun postgresql)

# Removed when present: they conflict with the packages above, and a conflict
# prompt makes `pacman --noconfirm` abort.
PKGS_REPLACED=(
  pulseaudio pulseaudio-alsa pulseaudio-bluetooth pulseaudio-jack jack2 pipewire-media-session rust
)

# ── AUR (a failure here is reported at the end instead of aborting) ──────────
AUR_PKGS=(
  ant-theme-git plymouth-theme-arch-logo-symbol
  glide-browser-bin elecwhat-bin apidog-bin beekeeper-studio-bin pixterm-git
  minio minio-client          # upstream unmaintained, minio already left [extra]; yay finds them
)

# ── Hardware (installed according to detection) ───────────────────────────────
PKGS_GPU_AMD=(mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon)
PKGS_GPU_INTEL=(mesa lib32-mesa vulkan-intel lib32-vulkan-intel intel-media-driver)
PKGS_GPU_NVIDIA=(nvidia-utils lib32-nvidia-utils libva-nvidia-driver)  # + nvidia-open-dkms
PKGS_GPU_NVIDIA_CURRENT=(                                              # removed on 580xx cards
  nvidia nvidia-dkms nvidia-lts nvidia-open nvidia-open-dkms nvidia-open-lts
  nvidia-utils lib32-nvidia-utils
)
AUR_GPU_NVIDIA_580XX=(nvidia-580xx-dkms nvidia-580xx-utils lib32-nvidia-580xx-utils)
PKGS_GPU_NOUVEAU=(mesa lib32-mesa vulkan-nouveau lib32-vulkan-nouveau)
PKGS_GPU_FALLBACK=(mesa lib32-mesa vulkan-swrast lib32-vulkan-swrast)  # VM / unknown GPU
PKGS_GPU_HYBRID=(nvidia-prime)
AUR_TUXEDO=(tuxedo-drivers-dkms)
TUXEDO_MODULES=(uniwill_wmi tuxedo_keyboard)
NVIDIA_TURING_ID=0x1e00     # PCI device IDs from Turing on use the current (open) driver
NVIDIA_MAXWELL_ID=0x1340    # Maxwell–Volta need the 580xx branch; older chips only run nouveau

# ── Services ──────────────────────────────────────────────────────────────────
SYSTEM_SERVICES=(NetworkManager bluetooth avahi-daemon power-profiles-daemon postgresql)
USER_SERVICES=(gammastep darkman)
DISPLAY_MANAGER="greetd"
NETWORK_CONFLICTS=(          # disabled: NetworkManager owns the network
  systemd-networkd.service systemd-networkd.socket systemd-networkd-wait-online.service
  iwd.service dhcpcd.service
)

# Per-machine files (written by the Arch installer or generated here): never taken from $SYSTEM_DIR.
MACHINE_FILES=(
  /etc/fstab /etc/hostname /etc/machine-id /etc/vconsole.conf
  /etc/default/grub /etc/kernel/cmdline /etc/mkinitcpio.conf /etc/locale.gen
  /etc/nsswitch.conf /etc/plymouth/plymouthd.conf
  /etc/udev/rules.d/99-input.rules /etc/udev/rules.d/99-kbd-backlight.rules
  /etc/modules-load.d/tuxedo.conf
)

# ══ Runtime state ═════════════════════════════════════════════════════════════

USER_NAME=$(id -un)
CPU_VENDOR=""
HAS_AMD=0 HAS_INTEL=0 IS_TUXEDO=0 NEEDS_SOF=0
NVIDIA_DRIVER=""            # open | 580xx | nouveau | empty when there is no NVIDIA GPU
FIRST_INSTALL=0
FAILED_AUR=()
TMP_DIR=""
KEEPALIVE_PID=""
YAY_FLAGS=(--needed --noconfirm --answerdiff None --answerclean None --removemake)

# ══ Helpers ═══════════════════════════════════════════════════════════════════

if [[ -t 1 ]]; then
  C_STEP=$'\e[1;34m' C_WARN=$'\e[33m' C_ERR=$'\e[31m' C_RST=$'\e[0m'
else
  C_STEP='' C_WARN='' C_ERR='' C_RST=''
fi

step() { printf '\n%s==> %s%s\n' "$C_STEP" "$*" "$C_RST"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '%s  ! %s%s\n' "$C_WARN" "$*" "$C_RST" >&2; }
die()  { printf '%s  ✗ %s%s\n' "$C_ERR" "$*" "$C_RST" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# shellcheck disable=SC2329  # on_error and cleanup are called by traps
on_error() {
  local status=$?
  printf '%s  ✗ failed (status %d) at line %d: %s%s\n' \
    "$C_ERR" "$status" "$1" "$BASH_COMMAND" "$C_RST" >&2
}

# shellcheck disable=SC2329
cleanup() {
  if [[ -n $KEEPALIVE_PID ]]; then kill "$KEEPALIVE_PID" 2>/dev/null || :; fi
  if [[ -n $TMP_DIR ]]; then rm -rf "$TMP_DIR" 2>/dev/null || :; fi
}

# Keeps the sudo timestamp fresh during long AUR builds (no temporary NOPASSWD).
start_sudo_keepalive() {
  sudo -v || die "sudo is required"
  ( trap - ERR; while kill -0 "$$" 2>/dev/null && sudo -n -v 2>/dev/null; do sleep 50; done ) &
  KEEPALIVE_PID=$!
}

dot() { git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" "$@"; }

# Installs only what is missing. `pacman -T` also accepts an installed alternative
# (neovim-nightly-bin satisfies neovim, nvidia-580xx-utils satisfies nvidia-utils)
# that would otherwise turn into a conflict prompt. -T exits 127 when anything is missing.
pacman_install() {
  local missing=()
  mapfile -t missing < <(pacman -T "$@" || true)
  (( ${#missing[@]} )) || return 0
  sudo pacman -S --needed --noconfirm "${missing[@]}"
  hash -r                    # drop cached command paths after installing
}

# One package at a time: a broken AUR package must not abort the whole install.
yay_install_each() {
  local pkg
  for pkg in "$@"; do
    pacman -T "$pkg" >/dev/null && continue
    yay -S "${YAY_FLAGS[@]}" "$pkg" || FAILED_AUR+=("$pkg")
  done
  hash -r
}

# Prints which of the given packages are installed under that exact name
# (`pacman -Q name` also matches providers: it would answer pipewire-pulse for pulseaudio).
installed_of() {
  local wanted=" $* " pkg
  while IFS= read -r pkg; do
    if [[ $wanted == *" $pkg "* ]]; then echo "$pkg"; fi
  done < <(pacman -Qq)
}

# -dd skips dependency checks: the replacements are installed right after.
remove_installed() {
  local pkgs=()
  mapfile -t pkgs < <(installed_of "$@")
  (( ${#pkgs[@]} )) || return 0
  sudo pacman -Rdd --noconfirm "${pkgs[@]}"
}

# Keeps the current version of a system file before it is overwritten or removed.
backup_root_file() {
  sudo test -e "$1" || return 0
  mkdir -p "$BACKUP_DIR/system$(dirname "$1")"
  # shellcheck disable=SC2024  # the redirect runs as the user on purpose: the backup is theirs
  sudo cat "$1" >"$BACKUP_DIR/system$1"
}

# Writes stdin to DEST as root:root, only when the content changes.
write_root_file() {
  local dest=$1 mode=${2:-644} tmp
  tmp=$(mktemp -p "$TMP_DIR")
  cat >"$tmp"
  if sudo cmp -s "$tmp" "$dest"; then return 0; fi
  backup_root_file "$dest"
  sudo install -D -m "$mode" -o root -g root "$tmp" "$dest"
  info "$dest"
}

remove_root_file() {
  sudo test -e "$1" || return 0
  backup_root_file "$1"
  sudo rm -f -- "$1"
  info "removed $1"
}

ensure_line() {   # ensure_line FILE LINE
  mkdir -p "$(dirname "$1")"
  grep -qxF -- "$2" "$1" 2>/dev/null || printf '%s\n' "$2" >>"$1"
}

is_machine_file() {
  local file
  for file in "${MACHINE_FILES[@]}"; do
    if [[ $1 == "$file" ]]; then return 0; fi
  done
  return 1
}

# Copies $SYSTEM_DIR/<path> → /<path> as root:root. With arguments, only those prefixes.
sync_system_files() {
  [[ -d $SYSTEM_DIR ]] || return 0
  local src dest prefix selected mode
  while IFS= read -r -d '' src; do
    dest=${src#"$SYSTEM_DIR"}
    if (( $# )); then
      selected=0
      for prefix in "$@"; do
        if [[ $dest == "$prefix" || $dest == "$prefix"/* ]]; then selected=1; fi
      done
      (( selected )) || continue
    fi
    if is_machine_file "$dest"; then
      warn "skipped $dest: it is per-machine, remove it from $SYSTEM_DIR"
      continue
    fi
    if sudo cmp -s "$src" "$dest"; then continue; fi
    if [[ -x $src ]]; then mode=755; else mode=644; fi
    backup_root_file "$dest"
    sudo install -D -m "$mode" -o root -g root "$src" "$dest"
    info "$dest"
  done < <(find "$SYSTEM_DIR" -type f -print0 | sort -z)
}

# ══ Hardware detection ════════════════════════════════════════════════════════

detect_hardware() {
  step "Detecting hardware"
  local dev id nvidia_id="" yn=(no yes)
  for dev in /sys/bus/pci/devices/*; do
    [[ $(<"$dev/class") == 0x03* ]] || continue            # display controllers only
    case $(<"$dev/vendor") in
      0x1002) HAS_AMD=1 ;;
      0x8086) HAS_INTEL=1 ;;
      0x10de)                                              # the oldest card decides the driver
        id=$(<"$dev/device")
        if [[ -z $nvidia_id ]] || (( id < nvidia_id )); then nvidia_id=$id; fi
        ;;
    esac
  done
  if [[ -n $nvidia_id ]]; then
    if (( nvidia_id >= NVIDIA_TURING_ID )); then NVIDIA_DRIVER=open
    elif (( nvidia_id >= NVIDIA_MAXWELL_ID )); then NVIDIA_DRIVER=580xx
    else NVIDIA_DRIVER=nouveau
    fi
  fi
  CPU_VENDOR=$(awk -F': ' '/^vendor_id/ { print $2; exit }' /proc/cpuinfo)
  if grep -qis tuxedo /sys/class/dmi/id/{sys_vendor,board_vendor,product_name}; then
    IS_TUXEDO=1
  fi
  if [[ -d /sys/module/snd_sof ]]; then NEEDS_SOF=1; fi    # SOF audio DSP: silent without firmware

  info "CPU:            ${CPU_VENDOR:-unknown}"
  info "GPU:            $(gpu_summary)"
  info "TUXEDO laptop:  ${yn[IS_TUXEDO]}"
  info "SOF audio:      ${yn[NEEDS_SOF]}"
}

gpu_summary() {
  local parts=() out="" part
  if (( HAS_INTEL )); then parts+=(Intel); fi
  if (( HAS_AMD )); then parts+=(AMD); fi
  if [[ -n $NVIDIA_DRIVER ]]; then parts+=("NVIDIA ($NVIDIA_DRIVER)"); fi
  for part in "${parts[@]}"; do out+="${out:+ + }$part"; done
  echo "${out:-none recognized (VM?)}"
}

# One headers package per installed kernel (linux, linux-lts, linux-zen...).
kernel_headers() {
  local file
  for file in /usr/lib/modules/*/pkgbase; do
    printf '%s-headers\n' "$(<"$file")"
  done | sort -u
}

# ══ Steps ═════════════════════════════════════════════════════════════════════

preflight() {
  (( EUID != 0 )) || die "run as your user; the script calls sudo when it needs to"
  [[ -f /etc/arch-release ]] || die "this script targets Arch Linux"
  have sudo || die "sudo is not installed"
  if [[ -e /var/lib/pacman/db.lck ]] &&
     ! pgrep -x 'pacman|yay|paru|makepkg|pamac-daemon|packagekitd' >/dev/null; then
    warn "removing a stale pacman lock (an earlier run was interrupted)"
    sudo rm -f /var/lib/pacman/db.lck
  fi
}

bootstrap() {
  step "Base system"
  sudo pacman -Sy --needed --noconfirm archlinux-keyring    # fresh keys before anything else
  sudo pacman -Su --needed --noconfirm git base-devel
  hash -r
}

setup_dotfiles() {
  step "Dotfiles ($DOTFILES_DIR → $HOME)"
  [[ -d $DOTFILES_DIR ]] || git clone --bare "$DOTFILES_URL" "$DOTFILES_DIR"
  dot config status.showUntrackedFiles no
  dot config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
  dot remote set-url --push origin "$DOTFILES_PUSH_URL"

  # First checkout: anything it would overwrite in $HOME goes to the backup.
  if [[ ! -f $DOTFILES_DIR/index ]]; then
    FIRST_INSTALL=1
    local path
    while IFS= read -r -d '' path; do
      [[ -e $HOME/$path || -L $HOME/$path ]] || continue
      mkdir -p "$BACKUP_DIR/home/$(dirname "$path")"
      mv "$HOME/$path" "$BACKUP_DIR/home/$path"
    done < <(dot ls-tree -r -z --name-only HEAD)
    dot checkout
  fi

  # A bare clone has no remote-tracking branch, so `dot pull` would not work.
  local branch
  branch=$(dot symbolic-ref --short HEAD)
  dot fetch --quiet origin
  dot branch --quiet --set-upstream-to="origin/$branch" "$branch"
}

multilib_enabled() { pacman-conf --repo-list | grep -x multilib >/dev/null; }

configure_pacman() {
  step "pacman"
  sync_system_files /etc/pacman.conf /etc/pacman.d
  if ! multilib_enabled; then
    if [[ -f $SYSTEM_DIR/etc/pacman.conf ]]; then
      die "[multilib] is disabled in $SYSTEM_DIR/etc/pacman.conf (steam and lib32 drivers need it)"
    fi
    sudo sed -i '/^#\[multilib\]$/,/^#Include/ s/^#//' /etc/pacman.conf
    multilib_enabled || die "could not enable [multilib] in /etc/pacman.conf"
  fi
  sudo pacman -Syu --noconfirm
}

install_yay() {
  have yay && return 0
  step "yay"
  git clone --depth=1 "$YAY_URL" "$TMP_DIR/yay"
  (cd "$TMP_DIR/yay" && makepkg -sri --noconfirm)
  hash -r
}

# Runs before the other packages: drivers already in place satisfy virtual dependencies
# such as steam's lib32-vulkan-driver, instead of --noconfirm picking a random provider.
install_hardware_packages() {
  step "Hardware packages"
  local pkgs=() aur=() headers=() pkg

  case $CPU_VENDOR in
    GenuineIntel) pkgs+=(intel-ucode) ;;
    AuthenticAMD) pkgs+=(amd-ucode) ;;
  esac
  if (( HAS_AMD )); then pkgs+=("${PKGS_GPU_AMD[@]}"); fi
  if (( HAS_INTEL )); then pkgs+=("${PKGS_GPU_INTEL[@]}"); fi
  case $NVIDIA_DRIVER in
    open)
      # Keeps a kernel module that is already installed (nvidia-open, -lts, 580xx by choice).
      pacman -T NVIDIA-MODULE >/dev/null || pkgs+=(nvidia-open-dkms)
      pkgs+=("${PKGS_GPU_NVIDIA[@]}")
      if (( HAS_AMD || HAS_INTEL )); then pkgs+=("${PKGS_GPU_HYBRID[@]}"); fi
      ;;
    580xx)
      remove_installed "${PKGS_GPU_NVIDIA_CURRENT[@]}"     # 590+ no longer drives these cards
      aur+=("${AUR_GPU_NVIDIA_580XX[@]}")
      if (( HAS_AMD || HAS_INTEL )); then aur+=("${PKGS_GPU_HYBRID[@]}"); fi  # after its utils
      ;;
    nouveau) pkgs+=("${PKGS_GPU_NOUVEAU[@]}") ;;
  esac
  if (( !HAS_AMD && !HAS_INTEL )) && [[ -z $NVIDIA_DRIVER ]]; then
    pkgs+=("${PKGS_GPU_FALLBACK[@]}")
  fi
  if (( NEEDS_SOF )); then pkgs+=(sof-firmware); fi
  if (( IS_TUXEDO )); then aur+=("${AUR_TUXEDO[@]}"); fi

  # DKMS modules only build against the headers of each installed kernel.
  for pkg in "${pkgs[@]}" "${aur[@]}"; do
    [[ $pkg == *-dkms ]] || continue
    mapfile -t headers < <(kernel_headers)
    (( ${#headers[@]} )) || warn "no kernel package found in /usr/lib/modules; DKMS cannot build"
    break
  done

  pacman_install "${headers[@]}" "${pkgs[@]}"
  yay_install_each "${aur[@]}"
}

install_packages() {
  step "Packages"
  remove_installed "${PKGS_REPLACED[@]}"
  pacman_install "${PKGS_BASE[@]}" "${PKGS_AUDIO[@]}" "${PKGS_FONTS[@]}" \
    "${PKGS_DESKTOP[@]}" "${PKGS_APPS[@]}" "${PKGS_DEV[@]}"
  yay_install_each "${AUR_PKGS[@]}"
}

deploy_system_files() {
  step "System files ($SYSTEM_DIR → /)"
  sync_system_files
}

# Per-machine Hyprland environment. On hybrid laptops the iGPU drives the display,
# so nothing is forced onto the NVIDIA card.
configure_gpu() {
  step "Hyprland GPU environment"
  local content
  content="-- Generated by install.sh for this machine: $(gpu_summary). Do not version it."
  if [[ $NVIDIA_DRIVER == open || $NVIDIA_DRIVER == 580xx ]] && (( !HAS_AMD && !HAS_INTEL )); then
    content+=$'\nhl.env("LIBVA_DRIVER_NAME", "nvidia")\nhl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")'
  fi
  if [[ ! -f $HYPR_GPU_CONF || $(<"$HYPR_GPU_CONF") != "$content" ]]; then
    mkdir -p "$(dirname "$HYPR_GPU_CONF")"
    printf '%s\n' "$content" >"$HYPR_GPU_CONF"
    info "$HYPR_GPU_CONF"
  fi
  ensure_line "$DOTFILES_DIR/info/exclude" "/${HYPR_GPU_CONF#"$HOME/"}"
}

configure_input() {
  step "Keyboard and input devices"
  sudo groupadd --system -f uinput
  sudo usermod -aG input,uinput "$USER_NAME"
  write_root_file /etc/udev/rules.d/99-input.rules <<'EOF'
KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
EOF
  # Keyboard backlight from any vendor: the input group may change brightness and color.
  write_root_file /etc/udev/rules.d/99-kbd-backlight.rules <<'EOF'
ACTION=="add", SUBSYSTEM=="leds", KERNEL=="*kbd_backlight*", RUN+="/usr/bin/chgrp wheel /sys/class/leds/%k/brightness", RUN+="/usr/bin/chmod g+w /sys/class/leds/%k/brightness"
ACTION=="add", SUBSYSTEM=="leds", KERNEL=="*kbd_backlight*", TEST=="multi_intensity", RUN+="/usr/bin/chgrp wheel /sys/class/leds/%k/multi_intensity", RUN+="/usr/bin/chmod g+w /sys/class/leds/%k/multi_intensity"
EOF
  if (( IS_TUXEDO )); then
    write_root_file /etc/modules-load.d/tuxedo.conf < <(printf '%s\n' "${TUXEDO_MODULES[@]}")
  else
    remove_root_file /etc/modules-load.d/tuxedo.conf
  fi
  # No modprobe: after a kernel upgrade the running kernel's modules are gone.
  # Everything loads on the next boot.
  sudo udevadm control --reload-rules
  sudo udevadm trigger --subsystem-match=leds --action=add
}

# Generates the locales that /etc/locale.conf asks for.
configure_locales() {
  [[ -f /etc/locale.conf ]] || return 0
  step "Locales"
  local locale escaped changed=0
  while IFS= read -r locale; do
    [[ $locale == C || $locale == C.* || $locale == POSIX ]] && continue
    escaped=${locale//./\\.}
    grep -Eq "^${escaped}[[:space:]]" /etc/locale.gen && continue
    if grep -Eq "^#[[:space:]]*${escaped}[[:space:]]" /etc/locale.gen; then
      sudo sed -Ei "s/^#[[:space:]]*(${escaped}[[:space:]])/\1/" /etc/locale.gen
      changed=1
    else
      warn "locale $locale is not listed in /etc/locale.gen"
    fi
  done < <(sed -nE 's/^(LANG|LC_[A-Z_]+)="?([^"]+)"?$/\2/p' /etc/locale.conf | sort -u)
  if (( changed )); then sudo locale-gen; fi
}

# Appends the missing parameters to a command line, comparing keys (the part before '=').
merge_params() {
  local cmdline=$1 param
  shift
  for param in "$@"; do
    [[ " $cmdline " =~ [[:space:]]"${param%%=*}"(=|[[:space:]]) ]] && continue
    cmdline+="${cmdline:+ }$param"
  done
  printf '%s' "$cmdline"
}

# Adds KERNEL_PARAMS to "options" lines (systemd-boot) and "cmdline:" lines (Limine).
# The ESP is FAT: copy + rename, no chmod/chown, and no half-written entry on power loss.
update_boot_entry() {
  local file=$1 line merged changed=0 tmp out=()
  while IFS= read -r line || [[ -n $line ]]; do
    if [[ $line =~ ^([[:space:]]*(options|cmdline:|kernel_cmdline:)[[:space:]]+)(.*)$ ]]; then
      merged=${BASH_REMATCH[1]}$(merge_params "${BASH_REMATCH[3]}" "${KERNEL_PARAMS[@]}")
      if [[ $merged != "$line" ]]; then line=$merged changed=1; fi
    fi
    out+=("$line")
  done < <(sudo cat "$file")
  (( changed )) || return 0
  tmp=$(mktemp -p "$TMP_DIR")
  printf '%s\n' "${out[@]}" >"$tmp"
  sudo cp "$tmp" "$file.new"
  sudo mv "$file.new" "$file"
  info "$file"
}

configure_kernel_cmdline() {
  local found=0 file current new
  if [[ -f /etc/kernel/cmdline ]]; then                          # UKI
    found=1
    current=$(</etc/kernel/cmdline)
    new=$(merge_params "$current" "${KERNEL_PARAMS[@]}")
    if [[ $new != "$current" ]]; then write_root_file /etc/kernel/cmdline <<<"$new"; fi
  fi
  while IFS= read -r -d '' file; do                              # systemd-boot, Limine
    found=1
    update_boot_entry "$file"
  done < <(sudo find /boot /efi -maxdepth 4 \
             \( -path '*/loader/entries/*.conf' -o -name limine.conf \) -print0 2>/dev/null || true)
  if [[ -f /etc/default/grub ]]; then                            # GRUB
    found=1
    current=$(sed -nE "s/^GRUB_CMDLINE_LINUX_DEFAULT=[\"']?([^\"']*)[\"']?.*/\1/p" /etc/default/grub)
    new=$(merge_params "$current" "${KERNEL_PARAMS[@]}")
    if [[ $new != "$current" ]]; then
      backup_root_file /etc/default/grub
      sudo sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$new\"|" /etc/default/grub
      info /etc/default/grub
      sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi
  fi
  (( found )) || warn "unknown bootloader; add to the kernel command line: ${KERNEL_PARAMS[*]}"
}

configure_boot() {
  step "Boot (Plymouth, kernel command line, initramfs)"
  if [[ -d /usr/share/plymouth/themes/$PLYMOUTH_THEME ]]; then
    sudo plymouth-set-default-theme "$PLYMOUTH_THEME"
  else
    warn "Plymouth theme '$PLYMOUTH_THEME' is not installed; keeping the default"
  fi
  # Hook right after systemd/udev (so before sd-encrypt/encrypt); the rest of HOOKS is untouched.
  if ! grep -Eq '^HOOKS=.*\bplymouth\b' /etc/mkinitcpio.conf; then
    sudo sed -Ei '/^HOOKS=/ s/\b(systemd|udev)\b/\1 plymouth/' /etc/mkinitcpio.conf
    grep -Eq '^HOOKS=.*\bplymouth\b' /etc/mkinitcpio.conf ||
      warn "no systemd/udev in HOOKS of /etc/mkinitcpio.conf; add 'plymouth' by hand"
  fi
  configure_kernel_cmdline
  sudo mkinitcpio -P
}

configure_shell() {
  step "Shell"
  if ! grep -qxF "$LOGIN_SHELL" /etc/shells; then
    printf '%s\n' "$LOGIN_SHELL" | sudo tee -a /etc/shells >/dev/null
  fi
  if [[ $(getent passwd "$USER_NAME" | cut -d: -f7) != "$LOGIN_SHELL" ]]; then
    sudo chsh -s "$LOGIN_SHELL" "$USER_NAME"
  fi
  # Plain clone instead of the remote installer, which rewrites .zshrc and switches shells.
  # The `zstyle ':omz:update' ...` lines belong in .zshrc: zstyle is a zsh builtin, bash has none.
  if [[ ! -f $OMZ_DIR/oh-my-zsh.sh ]]; then
    git clone --depth=1 -c oh-my-zsh.remote=origin -c oh-my-zsh.branch=master \
      "$OMZ_URL" "$TMP_DIR/ohmyzsh"
    mkdir -p "$OMZ_DIR"
    cp -a --update=none "$TMP_DIR/ohmyzsh/." "$OMZ_DIR/"   # keeps a custom/ that dot brought
  fi
}

configure_dev() {
  step "Development tools"
  rustup default >/dev/null 2>&1 || rustup default stable
  if ! sudo test -f /var/lib/postgres/data/PG_VERSION; then
    sudo install -d -o postgres -g postgres -m 700 /var/lib/postgres/data
    # Databases on btrfs should not be copy-on-write; it only applies to files created later.
    if [[ $(stat -f -c %T /var/lib/postgres) == btrfs ]]; then
      sudo chattr +C /var/lib/postgres/data
    fi
    sudo -iu postgres initdb --locale=C.UTF-8 --encoding=UTF8 -D /var/lib/postgres/data
  fi
  if [[ ! -e $NVIM_DIR ]]; then
    git clone "$NVIM_URL" "$NVIM_DIR"
    git -C "$NVIM_DIR" remote set-url --push origin "$NVIM_PUSH_URL"
  fi
}

configure_desktop() {
  step "Appearance and greeter"
  sudo fc-cache -s >/dev/null      # system fonts, also seen by the greeter user
  fc-cache >/dev/null              # ~/.local/share/fonts
  if [[ -S ${XDG_RUNTIME_DIR:-/nonexistent}/bus ]]; then
    gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"
    gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME"
    gsettings set org.gnome.desktop.interface color-scheme "$COLOR_SCHEME"
  else
    warn "no session D-Bus (log in on a TTY instead of using su); GTK theme not applied"
  fi
  if [[ -f $GREETER_INSTALLER ]]; then
    (cd "$(dirname "$GREETER_INSTALLER")" && bash "$GREETER_INSTALLER")
  else
    warn "greeter installer not found: $GREETER_INSTALLER"
  fi
}

configure_services() {
  step "Services"
  local unit current dm_link=/etc/systemd/system/display-manager.service

  for unit in "${NETWORK_CONFLICTS[@]}"; do
    if systemctl is-enabled --quiet "$unit" 2>/dev/null; then sudo systemctl disable "$unit"; fi
  done
  # Switches display managers (sddm, gdm, ly...) without the display-manager alias conflict.
  if [[ -L $dm_link ]]; then
    current=$(basename "$(readlink "$dm_link")")
    if [[ $current != "$DISPLAY_MANAGER.service" ]]; then sudo systemctl disable "$current"; fi
  fi
  sudo systemctl enable "${SYSTEM_SERVICES[@]}" "$DISPLAY_MANAGER.service"

  # nss-mdns only resolves .local names once it is listed in nsswitch.conf.
  if ! grep -Eq '^hosts:.*mdns' /etc/nsswitch.conf; then
    sudo sed -Ei '/^hosts:/ s/[[:space:]](resolve|dns)\b/ mdns_minimal [NOTFOUND=return] \1/' \
      /etc/nsswitch.conf
  fi

  if systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user enable "${USER_SERVICES[@]}"
  else
    warn "no user systemd (log in on a TTY instead of using su); later: systemctl --user enable ${USER_SERVICES[*]}"
  fi
}

summary() {
  step "Done"
  if (( ${#FAILED_AUR[@]} )); then
    warn "AUR packages that failed (re-run or install by hand): ${FAILED_AUR[*]}"
  fi
  if [[ -d $BACKUP_DIR ]]; then info "replaced files were backed up to $BACKUP_DIR"; fi
  if (( FIRST_INSTALL )) && [[ $REBOOT_AFTER_INSTALL == true ]]; then
    info "rebooting in 10 s (Ctrl+C cancels)"
    sleep 10
    sudo systemctl reboot
  else
    info "reboot if drivers, groups or boot settings changed"
  fi
}

usage() {
  cat <<'EOF'
Usage: install.sh [--sync]
  (no option)  full install; safe to re-run, it only applies what is missing
  --sync       only copy ~/.system to / (after editing a system file)
EOF
}

# ══ Main ══════════════════════════════════════════════════════════════════════

main() {
  local mode=full
  case ${1:-} in
    "") ;;
    --sync) mode=sync ;;
    -h | --help) usage; return 0 ;;
    *) usage >&2; return 2 ;;
  esac

  trap 'on_error $LINENO' ERR
  trap cleanup EXIT
  TMP_DIR=$(mktemp -d)
  preflight

  if [[ $mode == sync ]]; then
    [[ -d $SYSTEM_DIR ]] || die "$SYSTEM_DIR does not exist"
    step "System files ($SYSTEM_DIR → /)"
    sync_system_files
    configure_locales
    sudo systemctl daemon-reload
    sudo udevadm control --reload-rules
    info "boot, logind and greetd changes apply on the next boot"
    return 0
  fi

  detect_hardware
  start_sudo_keepalive
  bootstrap
  setup_dotfiles
  configure_pacman
  install_yay
  install_hardware_packages
  install_packages
  deploy_system_files
  configure_gpu
  configure_input
  configure_locales
  configure_boot
  configure_shell
  configure_dev
  configure_desktop
  configure_services
  summary
}

# Same line on purpose: bash parses the whole line before running it, so the file can be
# rewritten by the checkout (or arrive truncated through curl) without side effects.
main "$@"; exit
