#!/bin/bash

# Function to display messages in color
print_message() {
    echo -e "\033[1;32m$1\033[0m" # Green color for messages
}

# Function to validate the partition
validate_device() {
    local device=$1
    while true; do
        if [ -b "$device" ] && ! mount | grep -q "$device"; then
            break
        else
            echo "Invalid or in-use device: $device. Please enter a valid device:"
            read -r device
        fi
    done
    echo "$device"  # Return the valid device name
}

# Function to generate fstab entries with improved readability
generate_fstab_entry() {
    local device_uuid=$(blkid -s UUID -o value "$1")
    local mount_point="$2"
    local fs_type="$3"
    local options="$4"
    local dump_freq="$5"
    local pass_num="$6"

    printf "UUID=%-36s %-23s %-7s %-51s %s %s\n" "$device_uuid" "$mount_point" "$fs_type" "$options" "$dump_freq" "$pass_num"
}

# Function to create a temporary file with fstab entries
create_tmp_fstab_file() {
    local tmp_file="/tmp/btrfs_fstab_entries.tmp"
    
    # Adding header for better readability
    {
        echo "# /etc/fstab: static file system information."
        echo "# Btrfs subvolumes"
        generate_fstab_entry "$btrfs_partition" "/" "btrfs" "subvol=@,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2" "0" "0"
        generate_fstab_entry "$btrfs_partition" "/home" "btrfs" "subvol=@home,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2" "0" "0"
        generate_fstab_entry "$btrfs_partition" "/var/log" "btrfs" "subvol=@log,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2" "0" "0"
        generate_fstab_entry "$btrfs_partition" "/var/cache" "btrfs" "subvol=@cache,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2" "0" "0"
        generate_fstab_entry "$btrfs_partition" "/var/lib/libvirt/images" "btrfs" "subvol=@libvirt-images,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2" "0" "0"
        echo "# EFI partition"
        generate_fstab_entry "$efi_partition" "/efi" "vfat" "defaults,umask=0077" "0" "2"
    } > "$tmp_file"

    echo "$tmp_file"
}

# Main script

# Check if the script has been run before
if [ -f "/tmp/btrfs_layout_done" ]; then
    print_message "It seems the script has already been run. Exiting."
    exit 0
fi

print_message "WARNING: This script assumes that the partitions are already formatted."
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

# Mount the Btrfs partition and create subvolumes
if ! mount | grep -q "/mnt"; then
    mount "$btrfs_partition" /mnt
else
    print_message "Error: /mnt is already in use. Exiting."
    exit 1
fi

print_message "Creating Btrfs subvolumes..."
btrfs subvolume create /mnt/@ || { print_message "Failed to create subvolume @. Exiting."; exit 1; }
btrfs subvolume create /mnt/@home || { print_message "Failed to create subvolume @home. Exiting."; exit 1; }
btrfs subvolume create /mnt/@log || { print_message "Failed to create subvolume @log. Exiting."; exit 1; }
btrfs subvolume create /mnt/@cache || { print_message "Failed to create subvolume @cache. Exiting."; exit 1; }
btrfs subvolume create /mnt/@libvirt-images || { print_message "Failed to create subvolume @libvirt-images. Exiting."; exit 1; }
umount /mnt

# Mount subvolumes and EFI partition
print_message "Mounting subvolumes and EFI partition..."
mount -o subvol=@,defaults,noatime,compress=zstd "$btrfs_partition" /mnt || { print_message "Failed to mount subvolume @. Exiting."; exit 1; }
mkdir -p /mnt/{efi,home,var/log,var/cache,var/lib/libvirt/images}
mount -o subvol=@home,defaults,noatime,compress=zstd "$btrfs_partition" /mnt/home || { print_message "Failed to mount subvolume @home. Exiting."; exit 1; }
mount -o subvol=@log,defaults,noatime,compress=zstd "$btrfs_partition" /mnt/var/log || { print_message "Failed to mount subvolume @log. Exiting."; exit 1; }
mount -o subvol=@cache,defaults,noatime,compress=zstd "$btrfs_partition" /mnt/var/cache || { print_message "Failed to mount subvolume @cache. Exiting."; exit 1; }
mount -o subvol=@libvirt-images,defaults,noatime,compress=zstd "$btrfs_partition" /mnt/var/lib/libvirt/images || { print_message "Failed to mount subvolume @libvirt-images. Exiting."; exit 1; }
mount "$efi_partition" /mnt/efi || { print_message "Failed to mount EFI partition. Exiting."; exit 1; }

# Display the created subvolumes
print_message "Created Btrfs Subvolumes:"
btrfs subvolume list /mnt

# Generate temporary file with fstab entries
print_message "Generated fstab Entries:"
tmp_fstab_file=$(create_tmp_fstab_file)
cat "$tmp_fstab_file"

# Create a token file to indicate that the script has been run
touch /tmp/btrfs_layout_done

print_message "Entries added to temporary file: $tmp_fstab_file."
echo "Run the second script (append_fstab_entries.sh) to append the entries to /mnt/etc/fstab."
echo "Press Enter to exit."
read
