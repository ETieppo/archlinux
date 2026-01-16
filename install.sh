#!/usr/bin/env bash
set -euo pipefail

USER_NAME="${SUDO_USER:-$USER}"
USER_HOME="/home/$USER_NAME"
BOOT_LOADER_DIR="/boot/loader/entries"
BOOT_LOADER_FILE="arch.conf"

echo "== Updating system =="
sudo pacman -Syu --noconfirm

echo "== Installing packages =="
sudo pacman -S --needed --noconfirm \
  dkms linux-headers nvidia-dkms nvidia-utils \
  libglvnd vulkan-icd-loader

sudo pacman -S --noconfirm \
  zsh git base-devel unzip bluez ruby lua \
  thunar wezterm postgresql zed waybar \
  pavucontrol rofi hyprpaper greetd adwaita-icon-theme \
  ttf-jetbrains-mono-nerd minio-client \
  rsync nano hyprland linux-headers darkman \
  xdg-desktop-portal-hyprland gvfs file-roller \
  gammastep grim pulseaudio pulseaudio-alsa \
  xfconf libxfce4ui xfce4-settings openssh \
  sddm btop brightnessctl fastfetch plymouth \
  hyprpicker swaync ffmpegthumbnailer tumbler

TMP_DIR="$(mktemp -d)"

(
  git clone https://aur.archlinux.org/yay.git "$TMP_DIR/yay"
  cd "$TMP_DIR/yay"
  sudo -u "$USER_NAME" makepkg -si --noconfirm
)

rm -rf "$TMP_DIR"

echo "== Setting zsh as default shell =="
grep -qxF "/bin/zsh" /etc/shells || echo "/bin/zsh" | sudo tee -a /etc/shells
sudo chsh -s /bin/zsh "$USER_NAME"

echo "== Installing AUR packages =="
yay -S --noconfirm \
  minio steam elecwhat-bin apidog-bin tuigreet \
  beekeeper-studio-bin plymouth-theme-arch-logo-symbol \
  candy-icons-git ant-theme-git
  # kanata nwg-look

echo "== Installing CLIs =="
RUNZSH=no CHSH=no KEEP_ZSHRC=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

sudo -u "$USER_NAME" bash -c "curl -fsSL https://sh.rustup.rs | sh -s -- -y"
sudo -u "$USER_NAME" bash -c "curl -fsSL https://bun.sh/install | bash"
sudo -u "$USER_NAME" bash -c "curl -fsS https://dl.brave.com/install.sh | sh"

echo "== Merging system configs =="
if [ -d "./etc" ]; then
  sudo rsync -av --no-owner --no-group --chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r etc/ /etc/
fi

if [ -d "./root" ]; then
  sudo rsync -av --checksum root/ "$USER_HOME/"
  sudo chown -R "$USER_NAME:$USER_NAME" "$USER_HOME"
fi

if [ -d "./usr" ]; then
  sudo rsync -av --no-owner --no-group --chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r usr/ /usr/
fi

sudo mv $BOOT_LOADER_DIR/* "$BOOT_LOADER_FILE"
sudo sed -i '$ s/$/ quiet splash/' "$BOOT_LOADER_DIR/$BOOT_LOADER_FILE"
sudo find /usr/share/plymouth/themes -mindepth 1 -maxdepth 1 ! -name arch-logo-symbol -exec rm -rf {} +

echo "== Enabling services - setting up configs & permissions =="

sudo groupadd --system uinput
sudo usermod -aG input,uinput $USER
sudo chmod +x ~/.local/bin/zed-sudoedit
sudo modprobe uinput
sudo tee /etc/udev/rules.d/99-input.rules > /dev/null <<EOF
KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
EOF

sudo udevadm control --reload-rules
sudo udevadm trigger

systemctl --user daemon-reload
# systemctl --user enable --now kanata.service
systemctl --user start darkman

sudo -u "$USER_NAME" systemctl --user enable --now kanata.service || true
sudo dkms build nvidia/590.48.01
sudo mkinitcpio -P
sudo plymouth-set-default-theme -R arch-logo-symbol
xfsettingsd &
gsettings set org.gnome.desktop.interface gtk-theme 'Ant' || true
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
gsettings set org.gnome.desktop.interface icon-theme "candy-icons" || true
gdbus call --session \
 --dest org.freedesktop.portal.Desktop \
 --object-path /org/freedesktop/portal/desktop \
 --method org.freedesktop.portal.Settings.ReadOne \
 org.freedesktop.appearance color-scheme

sudo -iu postgres initdb \
  --locale=C.UTF-8 \
  --encoding=UTF8 \
  -D /var/lib/postgres/data

sudo systemctl enable postgresql
echo "==> END <=="
