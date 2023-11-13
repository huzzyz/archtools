#!/bin/bash

# Function to display messages in color and with proper formatting
print_message() {
    COLOR=$1
    TEXT=$2
    NC='\033[0m' # No Color
    printf "\n${COLOR}${TEXT}${NC}\n"
}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'

# Required packages
required_packages=("virt-manager" "qemu-desktop" "libvirt" "edk2-ovmf" "dnsmasq" "iptables-nft")

print_message $YELLOW "Starting Virtualization Environment Setup..."

# Check if yay is installed
if ! command -v yay &> /dev/null; then
    print_message $RED "Error: yay is not installed. Please install yay first."
    exit 1
else
    print_message $GREEN "Confirmed: yay is installed."
fi

# Install virtualization related packages
print_message $YELLOW "Checking and installing virtualization related packages..."
for pkg in "${required_packages[@]}"; do
    if ! pacman -Qi $pkg &> /dev/null; then
        print_message $YELLOW "Installing $pkg..."
        if yay -S --needed --noconfirm $pkg; then
            print_message $GREEN "$pkg installed successfully."
        else
            print_message $RED "Error installing $pkg."
            exit 1
        fi
    else
        print_message $GREEN "$pkg is already installed. Skipping..."
    fi
done

# Configure libvirt and qemu
print_message $YELLOW "Configuring libvirt and qemu..."

# Append settings to /etc/libvirt/libvirtd.conf
{
    echo "unix_sock_rw_perms = \"0770\""
    echo "unix_sock_group = \"libvirt\""
} | sudo tee -a /etc/libvirt/libvirtd.conf &>/dev/null && \
print_message $GREEN "libvirt configuration updated." || \
{ print_message $RED "Error updating libvirt configuration."; exit 1; }

# Create the libvirt configuration directory and set default URI
if mkdir -p ~/.config/libvirt/ && echo 'uri_default = "qemu:///system"' >> ~/.config/libvirt/libvirt.conf; then
    print_message $GREEN "libvirt user configuration set."
else
    print_message $RED "Error setting libvirt user configuration."
    exit 1
fi

# Add the current user to the libvirt group
if sudo usermod -aG libvirt $USER; then
    print_message $GREEN "Current user added to libvirt group."
else
    print_message $RED "Error adding current user to libvirt group."
    exit 1
fi

# Set the user and group in qemu.conf to the current user and group
USER_GROUP=$(id -gn $USER)
if sudo sed -i "/^#user/c\user = \"$USER\"" /etc/libvirt/qemu.conf && \
   sudo sed -i "/^#group/c\group = \"$USER_GROUP\"" /etc/libvirt/qemu.conf; then
    print_message $GREEN "QEMU configuration updated for user $USER."
else
    print_message $RED "Error updating QEMU configuration."
    exit 1
fi

# Enable and restart the libvirtd service
if sudo systemctl enable libvirtd.service && sudo systemctl restart libvirtd.service; then
    print_message $GREEN "libvirtd service enabled and restarted."
else
    print_message $RED "Error managing libvirtd service."
    exit 1
fi

# Check and start the default network
if sudo virsh net-list --all | grep -q 'default'; then
    print_message $GREEN "Default network already defined."
else
    print_message $YELLOW "Defining and starting the default network..."
    # Define the default network
    sudo virsh net-define /etc/libvirt/qemu/networks/default.xml
fi

# Start the default virtual network
if sudo virsh net-start default; then
    print_message $GREEN "Default virtual network started successfully."
else
    print_message $RED "Error starting the default virtual network."
    exit 1
fi

# Enable default network autostart
if sudo virsh net-autostart default; then
    print_message $GREEN "Default virtual network set to autostart."
else
    print_message $RED "Error setting default network to autostart."
    exit 1
fi

# Create a polkit rule for passwordless virt-manager access
POLKIT_RULE='/etc/polkit-1/rules.d/80-virt-manager.rules'
if sudo tee $POLKIT_RULE > /dev/null <<'EOF'
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.libvirt") == 0 &&
        subject.isInGroup("libvirt")) {
        return polkit.Result.YES;
    }
});
EOF
then
    print_message $GREEN "Polkit rule for virt-manager created successfully."
else
    print_message $RED "Error creating polkit rule for virt-manager."
    exit 1
fi

print_message $GREEN "Virtualization environment setup completed successfully."
