#!/bin/bash

# Function to prompt for user input
prompt_for_zram_size() {
    read -p "Enter the ZRAM size in MB (Recommended: $1 MB, 0 to skip): " input_size
    if [[ $input_size =~ ^[0-9]+$ ]]; then
        if [ "$input_size" -eq 0 ]; then
            echo "Skipping ZRAM setup as per user request."
            exit 0
        else
            echo "$input_size"
        fi
    else
        echo "Invalid input. Using recommended size."
        echo "$1"
    fi
}

# Check if run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

# Detect total RAM in MB
total_ram=$(grep MemTotal /proc/meminfo | awk '{print $2}')
total_ram_mb=$((total_ram / 1024))

# Calculate recommended ZRAM size (using a 1:3 ratio)
recommended_zram_size_mb=$((total_ram_mb * 3))

# Prompt user for ZRAM size
zram_size_mb=$(prompt_for_zram_size "$recommended_zram_size_mb")

# Check if zram module is loaded
if ! lsmod | grep -q zram; then
    # Load zram module
    modprobe zram
fi

# Set the number of ZRAM devices (1 in this case)
echo 1 > /sys/class/zram-control/hot_add

# Configure ZRAM size
echo "$((zram_size_mb * 1024 * 1024))" > /sys/block/zram0/disksize

# Use a recommended compression algorithm, e.g., lz4
echo lz4 > /sys/block/zram0/comp_algorithm

# Set up swap on ZRAM
mkswap /dev/zram0
swapon /dev/zram0

# Display ZRAM setup
echo "ZRAM setup completed. Size: $zram_size_mb MB"
swapon --show

# Create a systemd service for persistence
cat << EOF > /etc/systemd/system/zram.service
[Unit]
Description=Set up ZRAM swap

[Service]
Type=oneshot
ExecStart=/usr/sbin/swapon /dev/zram0
ExecStop=/usr/sbin/swapoff /dev/zram0

[Install]
WantedBy=multi-user.target
EOF

# Enable the systemd service
systemctl enable zram.service
echo "ZRAM will now be set up on each boot."
