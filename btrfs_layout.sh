#!/bin/bash

# Function to display messages in color
print_message() {
    echo -e "\033[1;32m$1\033[0m" # Green color for messages
}

print_message "WARNING: This script can modify disk partitions and may lead to data loss."
echo "Please ensure you have backups before proceeding."
read -p "Press Enter to continue or Ctrl+C to abort."

# Display available disks and partitions
print_message "Current Disk Layout:"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT

# Ask if user wants to create new partitions
read -p "Do you want to create new partitions? (yes/no): " create_partitions
if [ "$create_partitions" == "yes" ]; then
    echo "Please enter the disk where you want to create partitions (e.g., /dev/sda):"
    read -r disk

    # Partitioning
    echo "Creating partitions on $disk..."
    (
    echo n # Add a new partition (EFI)
    echo   # Partition number 1
    echo   # First sector (Accept default)
    echo +512M # Size of EFI partition
    echo n # Add a new partition (Btrfs)
    echo   # Partition number 2
    echo   # First sector (Accept default)
    echo   # Last sector (Accept default, uses remaining space)
    echo w # Write changes
    ) | fdisk $disk
fi

# Ask for the EFI and Btrfs partitions
echo "Please enter the EFI partition (e.g., /dev/sda1):"
read -r efi_partition
echo "Please enter the Btrfs partition (e.g., /dev/sda2):"
read -r btrfs_partition

# Format partitions
echo "Formatting the EFI partition ($efi_partition)..."
mkfs.fat -F32 "$efi_partition"

echo "Formatting the Btrfs partition ($btrfs_partition)..."
mkfs.btrfs "$btrfs_partition"

# Mount the Btrfs partition and create subvolumes
mount "$btrfs_partition" /mnt
print_message "Creating Btrfs subvolumes..."
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@cache
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@libvirt-images
umount /mnt

# Mount subvolumes and EFI partition
print_message "Mounting subvolumes and EFI partition..."
mount -o subvol=@,defaults,noatime,compress=zstd "$btrfs_partition" /mnt
mkdir -p /mnt/{boot/efi,home,var/log,var/cache,.snapshots,var/lib/libvirt/images}
mount -o subvol=@home,defaults,noatime,compress=zstd "$btrfs_partition" /mnt/home
mount -o subvol=@log,defaults,noatime,compress=zstd "$btrfs_partition" /mnt/var/log
mount -o subvol=@cache,defaults,noatime,compress=zstd "$btrfs_partition" /mnt/var/cache
mount -o subvol=@snapshots,defaults,noatime,compress=zstd "$btrfs_partition" /mnt/.snapshots
mount -o subvol=@libvirt-images,defaults,noatime,compress=zstd "$btrfs_partition" /mnt/var/lib/libvirt/images
mount "$efi_partition" /mnt/boot/efi

# Display the created subvolumes
print_message "Created Btrfs Subvolumes:"
btrfs subvolume list /mnt

# Reminder for fstab
print_message "Remember to update /etc/fstab with the new partitions and subvolumes."
echo "Press Enter to exit."
read
