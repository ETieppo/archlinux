#!/usr/bin/env bash
set -euo pipefail

src="$(dirname "$(readlink -f "$0")")"
root="$(dirname "$src")"
dst=/etc/greetd/quickshell
wallpaper="$(sed -n 's/^\s*path\s*=\s*//p' "$HOME/.config/hypr/hyprpaper.conf" | head -n1)"

sudo rm -rf "$dst"
sudo mkdir -p "$dst/components" "$dst/lock"
sudo cp "$src/shell.qml" "$root/Theme.qml" "$root/Sky.qml" "$dst/"
sudo cp "$root/components/Label.qml" "$root/components/Icon.qml" "$root/components/SkyBar.qml" "$dst/components/"
sudo cp "$root/lock/LockSurface.qml" "$dst/lock/"
[ -n "$wallpaper" ] && [ -f "$wallpaper" ] && sudo cp "$wallpaper" "$dst/wallpaper"
sudo cp "$src/hyprland.lua" /etc/greetd/hyprland.lua
sudo chmod -R a+rX "$dst" /etc/greetd/hyprland.lua

sudo tee /etc/greetd/config.toml >/dev/null <<EOF
[terminal]
vt = 1

[default_session]
command = "start-hyprland -- --config /etc/greetd/hyprland.lua"
user = "greeter"
EOF
