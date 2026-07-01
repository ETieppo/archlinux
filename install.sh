#!/usr/bin/env bash
set -euo pipefail

GITHUB_USER="etieppo"
NVIM_REPO="nvim"
USER_NAME="$USER"
USER_HOME="$HOME"
BOOT_LOADER_DIR="/boot/loader/entries"
BOOT_LOADER_FILE="arch.conf"
ZSH_BIN="/usr/bin/zsh"
ROOT_UUID=$(findmnt -no UUID /)

if [ "$EUID" -eq 0 ]; then
  echo "Rode como seu usuário comum, sem sudo. O script chama sudo internamente."
  exit 1
fi

cd "$(dirname "$(readlink -f "$0")")"

sudo mkdir -p "$BOOT_LOADER_DIR"
sudo tee "$BOOT_LOADER_DIR/$BOOT_LOADER_FILE" > /dev/null <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=UUID=$ROOT_UUID rw quiet splash
EOF

sudo -v

echo "== Reparando ownership dos diretórios de sistema =="
for d in / /etc /usr /var /boot /opt /srv /mnt /media /root /home /tmp; do
  [ -d "$d" ] && sudo chown root:root "$d"
done
sudo chmod 1777 /tmp

echo "== Updating system =="
sudo pacman -Syu --noconfirm

echo "== Installing nvidia / dkms =="
sudo pacman -S --needed --noconfirm \
  dkms linux-headers nvidia-dkms nvidia-utils \
  libglvnd vulkan-icd-loader

echo "== Installing base packages =="
sudo pacman -S --needed --noconfirm \
  zsh git base-devel unzip bluez bluez-utils lua \ 
  hyprland thunar ghostty postgresql waybar rsync \
  pavucontrol rofi greetd adwaita-icon-theme \
  ttf-jetbrains-mono-nerd minio-client darkman \
  xdg-desktop-portal-hyprland gvfs file-roller \
  gammastep grim pulseaudio pulseaudio-alsa \
  xfconf libxfce4ui xfce4-settings openssh \
  sddm btop brightnessctl plymouth hyprpicker \
  ffmpegthumbnailer tumbler wl-clipboard \
  qt5-declarative qt5-graphicaleffects qt5-quickcontrols \
  qt5-quickcontrols2 geoclue2 pipewire-pulse wireplumber

echo "== Installing yay (AUR helper) =="
if ! command -v yay >/dev/null 2>&1; then
  TMP_DIR="$(mktemp -d)"
  (
    git clone https://aur.archlinux.org/yay.git "$TMP_DIR/yay"
    cd "$TMP_DIR/yay"
    makepkg -si --noconfirm
  )
  rm -rf "$TMP_DIR"
fi

echo "== Setting zsh as default shell =="
grep -qxF "$ZSH_BIN" /etc/shells || echo "$ZSH_BIN" | sudo tee -a /etc/shells >/dev/null
sudo chsh -s "$ZSH_BIN" "$USER_NAME"

echo "== Installing AUR packages =="
yay -S --needed --noconfirm \
  minio steam elecwhat-bin apidog-bin \
  beekeeper-studio-bin plymouth-theme-arch-logo-symbol \
  ant-theme-git pixterm-git hyprpaper glide-browser-bin

echo "== Installing oh-my-zsh =="
if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  zstyle ':omz:update' mode auto
  zstyle ':omz:update' frequency 7
fi

echo "== Installing nvm =="
if [ ! -d "$USER_HOME/.nvm" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi

echo "== Installing rustup =="
if [ ! -d "$USER_HOME/.cargo" ]; then
  curl -fsSL https://sh.rustup.rs | sh -s -- -y
fi

echo "== Installing bun =="
if [ ! -d "$USER_HOME/.bun" ]; then
  curl -fsSL https://bun.sh/install | bash
fi

echo "== Merging system configs =="
if [ -d "./etc" ]; then
  sudo rsync -av --no-owner --no-group --chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r etc/ /etc/
fi
if [ -d "./tieppo" ]; then
  rsync -av --checksum tieppo/ "$USER_HOME/"
fi
if [ -d "./usr" ]; then
  sudo rsync -av --no-owner --no-group --chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r usr/ /usr/
fi

echo "== Plymouth themes cleanup =="
sudo find /usr/share/plymouth/themes -mindepth 1 -maxdepth 1 ! -name arch-logo-symbol -exec rm -rf {} +

echo "== Services, configs e permissões =="
sudo groupadd --system -f uinput
sudo usermod -aG input,uinput "$USER_NAME"
sudo modprobe uinput
sudo tee /etc/udev/rules.d/99-input.rules > /dev/null <<EOF
KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
EOF
sudo udevadm control --reload-rules
sudo udevadm trigger

systemctl --user daemon-reload || true
systemctl --user start darkman || true

sudo dkms autoinstall
sudo mkinitcpio -P
sudo plymouth-set-default-theme -R arch-logo-symbol

xfsettingsd >/dev/null 2>&1 &
gsettings set org.gnome.desktop.interface gtk-theme 'Ant' || true
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
gsettings set org.gnome.desktop.interface icon-theme "Ant" || true
gdbus call --session \
 --dest org.freedesktop.portal.Desktop \
 --object-path /org/freedesktop/portal/desktop \
 --method org.freedesktop.portal.Settings.ReadOne \
 org.freedesktop.appearance color-scheme || true

echo "== PostgreSQL =="
if ! sudo test -d /var/lib/postgres/data/base; then
  sudo -iu postgres initdb \
    --locale=C.UTF-8 \
    --encoding=UTF8 \
    -D /var/lib/postgres/data
fi
sudo systemctl enable postgresql
sudo systemctl enable sddm
sudo systemctl enable bluetooth
sudo systemctl enable NetworkManager
systemctl --user enable --now gammastep.service

echo "== Neovim config =="
if [ ! -d "$USER_HOME/.config/nvim" ]; then
  git clone "https://github.com/$GITHUB_USER/$NVIM_REPO" "$USER_HOME/.config/nvim"
fi

echo "==> END <=="
reboot
