#!/usr/bin/env bash
set -euo pipefail

USER_NAME="${SUDO_USER:-$USER}"
USER_HOME="/home/$USER_NAME"

echo "== Updating system =="
sudo pacman -Syu --noconfirm

echo "== Installing packages =="
sudo pacman -S --needed --noconfirm \
  dkms linux-headers nvidia-dkms nvidia-utils \
  libglvnd vulkan-icd-loader

sudo pacman -S --noconfirm \
  zsh git base-devel unzip bluez ruby lua \
  firefox-developer-edition thunar wezterm \
  postgresql zed waybar pavucontrol rofi \
  hyprpaper greetd adwaita-icon-theme \
  ttf-jetbrains-mono-nerd minio-client \
  rsync nano hyprland linux-headers darkman \
  xdg-desktop-portal-hyprland gvfs file-roller \
  gammastep grim pulseaudio pulseaudio-alsa \
  xfconf libxfce4ui xfce4-settings openssh \
  sddm

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
  minio steam elecwhat-bin kanata apidog-bin \
  tuigreet beekeeper-studio-bin

echo "== Installing CLIs =="
RUNZSH=no CHSH=no KEEP_ZSHRC=no \
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

sudo -u "$USER_NAME" bash -c "curl -fsSL https://sh.rustup.rs | sh -s -- -y"
sudo -u "$USER_NAME" bash -c "curl -fsSL https://bun.sh/install | bash"

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

echo "== Initializing PostgreSQL =="
sudo systemctl stop postgresql || true
sudo -iu postgres initdb \
  --locale=C.UTF-8 \
  --encoding=UTF8 \
  -D /var/lib/postgres/data

echo "== Enabling services =="
sudo groupadd --system uinput
sudo usermod -aG input,uinput $USER
sudo modprobe uinput
sudo tee /etc/udev/rules.d/99-input.rules > /dev/null <<EOF
KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
EOF

sudo udevadm control --reload-rules
sudo udevadm trigger

systemctl --user daemon-reload
systemctl --user enable --now kanata.service
systemctl --user start darkman

sudo systemctl enable postgresql
sudo -u "$USER_NAME" systemctl --user enable --now kanata.service || true
sudo dkms build nvidia/590.48.01
sudo mkinitcpio -P
xfsettingsd &
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' || true
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gdbus call --session \
 --dest org.freedesktop.portal.Desktop \
 --object-path /org/freedesktop/portal/desktop \
 --method org.freedesktop.portal.Settings.ReadOne \
 org.freedesktop.appearance color-scheme

echo "==> END <=="
ssh-keygen
