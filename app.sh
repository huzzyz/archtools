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

# Main script execution
broadcom_check
install_packages
