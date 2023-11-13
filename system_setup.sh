#!/bin/bash

# Function to display messages
print_message() {
    echo -e "\033[1;32m$1\033[0m" # Green color
}

# Set Locale
read -p "Enter your locale [default: en_US.UTF-8]: " locale
locale=${locale:-en_US.UTF-8}
echo "LANG=$locale" | sudo tee /etc/locale.conf
sudo locale-gen

# Set Timezone
read -p "Enter your timezone [default: Asia/Dubai] (e.g., Europe/London): " timezone
timezone=${timezone:-Asia/Dubai}
sudo ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
sudo hwclock --systohc

# Set Keyboard Layout
read -p "Enter your keyboard layout [default: us]: " keymap
keymap=${keymap:-us}
echo "KEYMAP=$keymap" | sudo tee /etc/vconsole.conf

# Set Hostname
read -p "Enter your hostname: " hostname
echo "$hostname" | sudo tee /etc/hostname

# Configure /etc/hosts
cat <<EOF | sudo tee /etc/hosts
127.0.0.1 localhost
::1 localhost
127.0.1.1 $hostname
EOF

print_message "Configuration completed successfully."
