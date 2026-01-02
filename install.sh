#!/usr/bin/env bash
set -euo pipefail

USER_NAME="${SUDO_USER:-$USER}"
USER_HOME="/home/$USER_NAME"

echo "== Updating system =="
sudo pacman -Syu --noconfirm

echo "== Installing packages =="
sudo pacman -S --noconfirm \
  zsh git base-devel unzip bluez ruby lua \
  firefox-developer-edition thunar wezterm \
  postgresql zed waybar pavucontrol wofi \
  hyprpaper greetd adwaita-icon-theme \
  ttf-jetbrains-mono-nerd minio-client \
  rsync nano hyprland

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
  minio \
  steam elecwhat-bin kanata apidog-bin tuigreet
  # beekeeper

echo "== Installing CLIs =="
RUNZSH=no CHSH=no KEEP_ZSHRC=no \
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

sudo -u "$USER_NAME" bash -c "curl -fsSL https://bun.sh/install | bash"
sudo -u "$USER_NAME" bash -c "curl -fsSL https://sh.rustup.rs | sh -s -- -y"

echo "== Merging system configs (/etc) =="
if [ -d "./etc" ]; then
  sudo rsync -av --checksum etc/ /etc/
fi

echo "== Merging user dotfiles =="
if [ -d "./root" ]; then
  sudo rsync -av --checksum root/ "$USER_HOME/"
  sudo chown -R "$USER_NAME:$USER_NAME" "$USER_HOME"
fi

echo "== Initializing PostgreSQL =="
sudo systemctl stop postgresql || true
sudo -iu postgres initdb \
  --locale=C.UTF-8 \
  --encoding=UTF8 \
  -D /var/lib/postgres/data

echo "== Enabling services =="
sudo systemctl enable postgresql
sudo -u "$USER_NAME" systemctl --user enable --now kanata.service || true

echo "== Setting GTK theme =="
sudo -u "$USER_NAME" gsettings set \
  org.gnome.desktop.interface gtk-theme 'Adwaita-dark' || true

echo "==> END <=="
