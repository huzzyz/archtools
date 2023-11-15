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
    # Add other entries
    # ...
    
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

# ... (existing code)

# Mount subvolumes and EFI partition
# ... (existing code)

# Generate temporary file with fstab entries
print_message "Generated fstab Entries:"
tmp_fstab_file=$(create_tmp_fstab_file)

# Create a token file to indicate that the script has been run
touch /tmp/btrfs_layout_done

print_message "Entries added to temporary file: $tmp_fstab_file."
echo "Run the second script to append the entries to /mnt/etc/fstab."
echo "Press Enter to exit."
read
