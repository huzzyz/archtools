#!/bin/bash

# Function to display messages in color
print_message() {
    echo -e "\033[1;32m$1\033[0m" # Green color for messages
}

# Check if the temporary file exists
tmp_fstab_file="/tmp/btrfs_fstab_entries.tmp"

if [ ! -f "$tmp_fstab_file" ]; then
    print_message "Temporary file not found. Exiting."
    exit 1
fi

# Append entries to /mnt/etc/fstab
print_message "Appending fstab entries to /mnt/etc/fstab..."
cat "$tmp_fstab_file" >> /mnt/etc/fstab

print_message "Entries appended to /mnt/etc/fstab."
echo "Press Enter to exit."
read

# Optional: Remove the temporary file
rm "$tmp_fstab_file"
