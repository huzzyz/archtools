#!/bin/bash
# Automated Arch Linux Installation Script with Btrfs, Dynamic Passwords, Partition Listing, Enhanced Pacman Configurations, Swap Setup, and Dynamic Hostname

# Function to display messages
print_message() {
    echo -e "\033[1;33m$1\033[0m"  # Yellow color for emphasis
}

# Clear the screen for better visibility
clear_screen() {
    echo -e "\033c"
}

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\033[1;31mThis script must be run as root\033[0m" >&2
    exit 1
fi

clear_screen

# Modify pacman.conf function
modify_pacman_conf() {
    local pacman_conf_file="$1"
    sed -i 's/#Color/Color/' "$pacman_conf_file"
    sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' "$pacman_conf_file"
    echo -e '\nILoveCandy' >> "$pacman_conf_file"
}

# List available partitions
print_message "Available partitions on the system:"
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
echo ""

# Ask for user input for EFI, Btrfs partitions, and hostname
echo -e "\033[1;34mPlease enter the partitions based on the list above.\033[0m"
read -p "Enter the EFI partition (e.g., /dev/sda1): " efi_partition
read -p "Enter the Btrfs partition (e.g., /dev/sda2): " btrfs_partition
read -p "Enter your desired hostname: " custom_hostname
echo ""

# Modify pacman.conf before chroot
modify_pacman_conf "/etc/pacman.conf"

# Disk Preparation
print_message "Formatting partitions..."
mkfs.fat -F 32 "$efi_partition"
mkfs.btrfs -f "$btrfs_partition"
echo ""

# Mount Partitions
print_message "Mounting partitions..."
mount "$btrfs_partition" /mnt
mkdir -p /mnt/efi
mount "$efi_partition" /mnt/efi
echo ""

# Creating Btrfs subvolumes
print_message "Creating Btrfs subvolumes..."
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@snapshots
echo ""

# Remounting with subvolumes
umount /mnt
mount -o subvol=@,compress=zstd "$btrfs_partition" /mnt
mkdir -p /mnt/{home,var,.snapshots,efi}
mount -o subvol=@home,compress=zstd "$btrfs_partition" /mnt/home
mount -o subvol=@var,compress=zstd "$btrfs_partition" /mnt/var
mount -o subvol=@snapshots,compress=zstd "$btrfs_partition" /mnt/.snapshots
mount "$efi_partition" /mnt/efi
echo ""

# Install Base System using Pacstrap
print_message "Installing base system..."
pacstrap /mnt base base-devel intel-ucode linux linux-firmware git btrfs-progs grub efibootmgr grub-btrfs inotify-tools vim networkmanager pipewire pipewire-alsa pipewire-pulse pipewire-jack sudo duf fish
echo ""

# Generate fstab
print_message "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab
echo ""

# Chroot into the new system
print_message "Entering chroot to configure system..."
arch-chroot /mnt /bin/bash <<EOF

# Modify pacman.conf after chroot
modify_pacman_conf "/etc/pacman.conf"

# Locale Setting
print_message "Configuring locale..."
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
locale-gen
echo ""

# Timezone Setting
print_message "Configuring timezone..."
ln -sf /usr/share/zoneinfo/Asia/Dubai /etc/localtime
hwclock --systohc
echo ""

# Hostname and Hosts Configuration
print_message "Configuring hostname and hosts..."
echo "$custom_hostname" > /etc/hostname
cat <<EOT > /etc/hosts
127.0.0.1 localhost
::1 localhost
127.0.1.1 $custom_hostname.localdomain $custom_hostname
EOT
echo ""

# Set Root Password
print_message "Setting root password..."
passwd
echo ""

# Create a New User
print_message "Creating a new user..."
read -p "Enter a new username: " newuser
useradd -m -G wheel -s /bin/bash "\$newuser"
passwd "\$newuser"
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
echo ""

# Bootloader Installation
print_message "Installing and configuring bootloader..."
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=Arch
grub-mkconfig -o /boot/grub/grub.cfg
echo ""

# Network Configuration
print_message "Enabling NetworkManager..."
systemctl enable NetworkManager
echo ""

EOF

clear_screen

# Swap Setup and fstab Update
print_message "Setting up swap..."
# Display available partitions again
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
echo ""
read -p "Enter the partition to be used for swap (e.g., /dev/sda3): " swap_partition

# Format the swap partition
mkswap "$swap_partition"
swapon "$swap_partition"

# Generate swap entry for fstab
swap_uuid=$(blkid -s UUID -o value "$swap_partition")
echo "UUID=$swap_uuid none swap sw 0 0" >> /mnt/etc/fstab

# Display updated fstab
print_message "Updated fstab:"
cat /mnt/etc/fstab
echo ""

# Finish Up
print_message "Arch Linux installation complete. Reboot your system."
umount -R /mnt
reboot
