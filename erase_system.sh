#!/bin/bash
### ======================================= ###
###                                         ###
###                 HAZARD                  ###
###                                         ###
###                                         ###
###    This will delete all disk data!!     ###
###                                         ###
### ======================================= ###
set -euo pipefail

DISK=/dev/nvme1n1
EFI_PART="${DISK}p1"
ROOT_PART="${DISK}p2"
HOSTNAME="archlinux"
USERNAME="tieppo"
TIMEZONE="America/Sao_Paulo"

if [ -z "${PASSWORD:-}" ]; then
    echo "Set PASSWORD env var first: PASSWORD=yourpass sudo -E ./install.sh" >&2
    exit 1
fi

if [ "$EUID" -ne 0 ]; then
    echo "Run as root (sudo)." >&2
    exit 1
fi

[ -b "$DISK" ] || { echo "$DISK does not exist."; exit 1; }

echo
echo "=== Target disk: $DISK ==="
lsblk "$DISK"
echo
echo "This disk will be COMPLETELY ERASED."
read -p "Confirm? Type 'yes' to continue: " confirm
[ "$confirm" = "yes" ] || { echo "Aborted."; exit 1; }

pacman -S --needed --noconfirm arch-install-scripts dosfstools

for mp in $(mount | grep "^${DISK}" | awk '{print $3}'); do
    umount "$mp" 2>/dev/null || umount -l "$mp"
done
wipefs -af "$DISK"

sfdisk "$DISK" <<'SFDISK'
label: gpt
,1G,U
,,L
SFDISK

sleep 1
partprobe "$DISK" || true
udevadm settle

wipefs -af "$EFI_PART" "$ROOT_PART"

mkfs.fat -F32 "$EFI_PART"
mkfs.ext4 -F "$ROOT_PART"

udevadm settle

mount -t ext4 "$ROOT_PART" /mnt
mount --mkdir -t vfat "$EFI_PART" /mnt/boot

mountpoint -q /mnt && mountpoint -q /mnt/boot || {
    echo "Mount failed."; exit 1;
}

pacstrap -K /mnt base linux linux-firmware sudo neovim networkmanager intel-ucode
genfstab -U /mnt >> /mnt/etc/fstab

ROOT_UUID=$(blkid -s UUID -o value "$ROOT_PART")

arch-chroot /mnt /bin/bash <<CHROOT
set -e
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^#pt_BR.UTF-8 UTF-8/pt_BR.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "$HOSTNAME" > /etc/hostname
systemctl enable NetworkManager
useradd -m -G wheel -s /bin/bash $USERNAME
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
if ! grep -qE "^%wheel ALL=\(ALL:ALL\) NOPASSWD: ALL" /etc/sudoers; then
    echo "WARNING: sudoers sed did not match. Edit later with 'EDITOR=nvim visudo'."
fi
bootctl install
cat > /boot/loader/entries/arch.conf <<ENTRY
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=UUID=$ROOT_UUID rw
ENTRY
cat > /boot/loader/loader.conf <<LOADER
default arch.conf
timeout 3
console-mode max
editor no
LOADER
echo
echo "=== Bootloader configured: ==="
cat /boot/loader/entries/arch.conf
echo
bootctl list
CHROOT

echo
echo "=== Setting passwords ==="
echo "root:$PASSWORD" | arch-chroot /mnt chpasswd
echo "$USERNAME:$PASSWORD" | arch-chroot /mnt chpasswd

pkill -f "gpg-agent.*/mnt" 2>/dev/null || true
sleep 1

if ! umount -R /mnt 2>/dev/null; then
    echo "umount -R failed, killing processes..."
    fuser -kmv /mnt || true
    sleep 2
    umount -R /mnt
fi

echo
echo "=== Installation complete ==="
echo "Rebooting in 5s. Ctrl+C to cancel and review."
sleep 5
reboot
