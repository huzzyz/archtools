#!/bin/bash

# Function to display messages in color
print_message() {
    echo -e "\033[1;32m$1\033[0m" # Green color for messages
}

# Function to validate the partition or disk
validate_device() {
    local device=$1
    while true; do
        if [ -b "$device" ]; then
            break
        else
            echo "Invalid device: $device. Please enter a valid device:"
            read -r device
        fi
    done
    echo "$device"  # Return the valid device name
}

print_message "WARNING: This script can modify disk partitions and may lead to data loss."
echo "Please ensure you have backups before proceeding."
read -p "Press Enter to continue or Ctrl+C to abort."

print_message "Current Disk Layout:"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT

# Partition deletion (optional)
read -p "Do you want to delete any partitions? (yes/no): " delete_partitions
if [ "$delete_partitions" == "yes" ]; then
    echo "Enter the partition you want to delete (e.g., /dev/sda1):"
    read -r partition
    partition=$(validate_device "$partition")
    echo "Deleting partition $partition..."
    (
    echo d # Delete a partition
    echo w # Write changes
    ) | fdisk "$(echo $partition | sed -r 's/(.*[a-z]).*/\1/')"
fi

# Partition creation (optional)
read -p "Do you want to create new partitions? (yes/no): " create_partitions
if [ "$create_partitions" == "yes" ]; then
    echo "Please enter the disk where you want to create partitions (e.g., /dev/sda):"
    read -r disk
    disk=$(validate_device "$disk")

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

# Format partitions
echo "Please enter the EFI partition (e.g., /dev/sda1):"
read -r efi_partition
efi_partition=$(validate_device "$efi_partition")
echo "Formatting the EFI partition ($efi_partition)..."
mkfs.fat -F32 "$efi_partition"

echo "Please enter the Btrfs partition (e.g., /dev/sda2):"
read -r btrfs_partition
btrfs_partition=$(validate_device "$btrfs_partition")
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

print_message "Remember to update /etc/fstab with the new partitions and subvolumes."
echo "Press Enter to exit."
read
