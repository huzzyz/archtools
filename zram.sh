#!/bin/bash

# Check if run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

# Check for necessary commands
for cmd in grep awk modprobe mkswap swapon; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Command not found: $cmd. Please install it."
        exit 1
    fi
done

# Check if /proc/meminfo exists
if [ ! -f /proc/meminfo ]; then
    echo "/proc/meminfo not found. Are you running this on Linux?"
    exit 1
fi

# Detect total RAM in MB
total_ram=$(grep MemTotal /proc/meminfo | awk '{print $2}')
total_ram_mb=$((total_ram / 1024))

# Calculate recommended ZRAM size (using a 1:3 ratio)
zram_size_mb=$((total_ram_mb * 3))

# Check if zram module is loaded
if ! lsmod | grep -q zram; then
    # Load zram module
    modprobe zram
fi

# Setting up ZRAM
echo "Setting up ZRAM of size: $zram_size_mb MB..."

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
echo "ZRAM setup completed. Current status:"
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
