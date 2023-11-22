#!/bin/bash

# Function to display messages in color
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

# Check for AMD GPU
amd_gpu_check() {
    if lspci | grep -E "VGA|3D" | grep -qi AMD; then
        print_message $YELLOW "An AMD GPU has been detected."
        read -p "Please confirm if you want to install AMD-specific packages (y/n): " confirm_amd
        if [[ $confirm_amd != [Yy]* ]]; then
            # Exclude AMD-specific package from installation if user does not confirm
            sed -i '/corectrl-git/d' packages.txt
        fi
    else
        # Exclude AMD-specific package as no AMD GPU is detected
        sed -i '/corectrl-git/d' packages.txt
    fi
}

# Check for Broadcom network card
broadcom_check() {
    if lspci | grep -qi Broadcom; then
        print_message $YELLOW "A Broadcom network card has been detected."
    else
        # Exclude Broadcom package as no Broadcom network card is detected
        sed -i '/broadcom-wl/d' packages.txt
    fi
}

# Install packages using yay
install_packages() {
    if [ -f "packages.txt" ]; then
        while IFS= read -r package || [[ -n "$package" ]]; do
            if ! pacman -Qi $package &> /dev/null; then
                print_message $YELLOW "Installing package: $package"
                if ! yay -S --needed --noconfirm $package; then
                    print_message $RED "Error: Failed to install package: $package"
                    exit 1
                fi
            else
                print_message $GREEN "Package already installed: $package"
            fi
        done < packages.txt
        print_message $GREEN "Arch/AUR packages installed successfully."
    else
        print_message $RED "packages.txt not found. Skipping Arch/AUR package installation."
    fi
}

# Install Snap packages
install_snap_packages() {
    # Start and enable snapd and related services
    sudo systemctl start snapd
    sudo systemctl enable --now snapd.apparmor
    sudo systemctl enable --now snapd.service
    sudo systemctl enable --now bluetooth

    if [ -f "snap_packages.txt" ]; then
        while IFS= read -r package || [[ -n "$package" ]]; do
            if ! snap list | grep -q "^$package "; then
                print_message $YELLOW "Installing Snap package: $package"
                if ! sudo snap install $package; then
                    print_message $RED "Error: Failed to install Snap package: $package"
                    exit 1
                fi
            else
                print_message $GREEN "Snap package already installed: $package"
            fi
        done < snap_packages.txt
        print_message $GREEN "Snap packages installed successfully."
    else
        print_message $RED "snap_packages.txt not found. Skipping Snap package installation."
    fi
}

# Main script execution
amd_gpu_check
broadcom_check
install_packages
install_snap_packages
