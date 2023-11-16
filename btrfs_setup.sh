#!/bin/bash

# Function to display messages in color
print_message() {
    echo -e "\033[1;32m$1\033[0m" # Green color for messages
}

# Function to validate the partition
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

# Function to generate fstab entries
generate_fstab_entry() {
    local uuid=$(blkid -s UUID -o value "$1")
    local mount_point="$2"
    local options="$3"
    echo "UUID=$uuid $mount_point btrfs $options 0 0"
}

# Function to create a temporary file with fstab entries
create_tmp_fstab_file() {
    local tmp_file="/tmp/btrfs_fstab_entries.tmp"
    
    generate_fstab_entry "$btrfs_partition" "/" "subvol=@,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2" > "$tmp_file"
    generate_fstab_entry "$btrfs_partition" "/home" "subvol=@home,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2" >> "$tmp_file"
    generate_fstab_entry "$btrfs_partition" "/var/log" "subvol=@log,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2" >> "$tmp_file"
    generate_fstab_entry "$btrfs_partition" "/var/cache" "subvol=@cache,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2" >> "$tmp_file"
    generate_fstab_entry "$btrfs_partition" "/var/lib/libvirt/images" "subvol=@libvirt-images,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2" >> "$tmp_file"
    generate_fstab_entry "$efi_partition" "/efi" "vfat defaults,umask=0077" >> "$tmp_file"

    echo "$tmp_file"
}

# Main script

# Check if the script has been run before
if [ -f "/tmp/btrfs_layout_done" ]; then
    print_message "It seems the script has already been run. Exiting."
    exit 0
fi

print_message "WARNING: This script assumes you have created the partitions and formatted them on your own. This script will only create a btrfs layout and may lead to data loss."
echo "Please ensure you have backups before proceeding."
read -p "Press Enter to continue or Ctrl+C to abort."

print_message "Current Disk Layout:"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT

# Ask for the EFI and Btrfs partitions
echo "Please enter the EFI partition (e.g., /dev/sda1):"
read -r efi_partition
efi_partition=$(validate_device "$efi_partition")

echo "Please enter the Btrfs partition (e.g., /dev/sda2):"
read -r btrfs_partition
btrfs_partition=$(validate_device "$btrfs_partition")

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
btrfs subvolume create /mnt/@libvirt-images
umount /mnt

# Mount subvolumes and EFI partition
print_message "Mounting subvolumes and EFI partition..."
mount -o subvol=@,defaults,noatime,compress=zstd "$btrfs_partition" /mnt
mkdir -p /mnt/{efi,home,var/log,var/cache,var/lib/libvirt/images}
mount -o subvol=@home,defaults,noatime,compress=zstd "$btrfs_partition" /mnt/home
mount -o subvol=@log,defaults,noatime,compress=zstd "$btrfs_partition" /mnt/var/log
mount -o subvol=@cache,defaults,noatime,compress=zstd "$btrfs_partition" /mnt/var/cache
mount -o subvol=@libvirt-images,defaults,noatime,compress=zstd "$btrfs_partition" /mnt/var/lib/libvirt/images
mount "$efi_partition" /mnt/efi

# Display the created subvolumes
print_message "Created Btrfs Subvolumes:"
btrfs subvolume list /mnt

# Generate temporary file with fstab entries
print_message "Generated fstab Entries:"
tmp_fstab_file=$(create_tmp_fstab_file)

# Create a token file to indicate that the script has been run
touch /tmp/btrfs_layout_done

print_message "Entries added to temporary file: $tmp_fstab_file."
echo "Run the second script (append_fstab_entries.sh) to append the entries to /mnt/etc/fstab."
echo "Press Enter to exit."
read
