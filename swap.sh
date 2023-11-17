#!/bin/bash

# Function to display messages in color
print_message() {
    echo -e "\033[1;32m$1\033[0m" # Green color for messages
}

# Function to validate the swap partition
validate_swap_partition() {
    local device=$1
    while true; do
        if [ -b "$device" ]; then
            break
        else
            echo "Invalid partition: $device. Please enter a valid partition:"
            read -r device
        fi
    done
    echo "$device"  # Return the valid partition name
}

# Check for existing swap partitions
existing_swap=$(swapon --show=NAME --noheadings)
if [ -n "$existing_swap" ]; then
    print_message "Existing swap partitions detected:"
    swapon --show=NAME,SIZE
    read -p "Do you want to continue creating a new swap partition? (yes/no): " response
    if [[ $response != [yY][eE][sS] ]]; then
        echo "Exiting script."
        exit 0
    fi
fi

print_message "Current Disk Layout:"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT

# Ask for the swap partition
echo "Please enter the swap partition (e.g., /dev/sda1):"
read -r swap_partition
swap_partition=$(validate_swap_partition "$swap_partition")

# Ask to format the swap partition
read -p "Do you want to format the swap partition? (yes/no): " format_response
if [[ $format_response == [yY][eE][sS] ]]; then
    print_message "WARNING: This will format the selected partition as swap and may lead to data loss."
    echo "Ensure you have selected the correct partition."
    read -p "Press Enter to continue or Ctrl+C to abort."

    # Format partition as swap
    echo "Formatting the swap partition ($swap_partition)..."
    sudo mkswap "$swap_partition"
else
    print_message "Skipping formatting."
fi

# Enable the swap partition
echo "Enabling the swap partition..."
sudo swapon "$swap_partition"

# Generate fstab entry
uuid=$(sudo blkid -s UUID -o value "$swap_partition")
echo "Generated fstab entry:"
echo "UUID=$uuid none swap sw 0 0"

# Ask to append to /etc/fstab
read -p "Do you want to append this entry to /etc/fstab? (yes/no): " append_answer
if [[ $append_answer == [yY][eE][sS] ]]; then
    echo "UUID=$uuid none swap sw 0 0" | sudo tee -a /etc/fstab
    print_message "fstab updated successfully."
else
    print_message "Please remember to update /etc/fstab manually."
fi

echo "Swap setup complete."
