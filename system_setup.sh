#!/bin/bash

# Function to display messages
print_message() {
    echo -e "\033[1;32m$1\033[0m" # Green color
}

# Set Locale
read -p "Enter your locale [default: en_US.UTF-8]: " locale
locale=${locale:-en_US.UTF-8}
sudo sed -i "s/^#.*$locale/$locale/" /etc/locale.gen # Uncomment the selected locale
echo "LANG=$locale" | sudo tee /etc/locale.conf
echo "LANGUAGE=$locale" | sudo tee -a /etc/locale.conf
echo "LC_TIME=C.UTF-8" | sudo tee -a /etc/locale.conf
sudo locale-gen
print_message "Locale set to $locale."

# Set Timezone
read -p "Enter your timezone [default: Asia/Dubai] (e.g., Europe/London): " timezone
timezone=${timezone:-Asia/Dubai}
if [ -f /usr/share/zoneinfo/$timezone ]; then
    sudo ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
    sudo hwclock --systohc
    print_message "Timezone set to $timezone."
else
    print_message "Invalid timezone. Defaulting to Asia/Dubai."
    sudo ln -sf /usr/share/zoneinfo/Asia/Dubai /etc/localtime
    sudo hwclock --systohc
fi

# Set Keyboard Layout
read -p "Enter your keyboard layout [default: us]: " keymap
keymap=${keymap:-us}
echo "KEYMAP=$keymap" | sudo tee /etc/vconsole.conf
loadkeys $keymap
print_message "Keyboard layout set to $keymap."

# Set Hostname
while true; do
    read -p "Enter your hostname [default: myhostname]: " hostname
    hostname=${hostname:-myhostname}
    if [ -n "$hostname" ]; then
        echo "$hostname" | sudo tee /etc/hostname
        print_message "Hostname set to $hostname."
        break
    else
        print_message "Hostname cannot be empty. Please enter a hostname."
    fi
done

# Configure /etc/hosts
cat <<EOF | sudo tee /etc/hosts
127.0.0.1 localhost
::1 localhost
127.0.1.1 $hostname.localdomain $hostname
#192.168.53.53 Solitude
EOF
print_message "Hosts file configured."

print_message "Configuration completed successfully."
