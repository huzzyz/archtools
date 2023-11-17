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

# Backup the original fstab file
print_message "Backing up the original fstab file..."
cp /mnt/etc/fstab /mnt/etc/fstab.backup

# Validate and display the contents of the temporary file
if [ -s "$tmp_fstab_file" ]; then
    print_message "Contents of the temporary fstab file:"
    cat "$tmp_fstab_file"
    echo
else
    print_message "Temporary fstab file is empty. Exiting."
    exit 1
fi

# Ask for confirmation before appending
read -p "Are you sure you want to append these entries to /mnt/etc/fstab? (y/N): " confirm
if [[ $confirm != [yY] ]]; then
    print_message "Operation cancelled by the user."
    exit 0
fi

# Append entries to /mnt/etc/fstab
if cat "$tmp_fstab_file" >> /mnt/etc/fstab; then
    print_message "Entries appended to /mnt/etc/fstab."
else
    print_message "Failed to append entries. Check permissions and mount status."
    exit 1
fi

echo "Press Enter to exit."
read

# Optional: Remove the temporary file
rm "$tmp_fstab_file"
