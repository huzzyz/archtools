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

# Install packages using yay
if [ -f "packages.txt" ]; then
    print_message $YELLOW "Installing Arch/AUR packages from packages.txt..."
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

# Install Flatpak packages
if [ -f "flatpak_packages.txt" ]; then
    print_message $YELLOW "Installing Flatpak packages from flatpak_packages.txt..."
    while IFS= read -r package || [[ -n "$package" ]]; do
        if ! flatpak list | grep -q $package; then
            print_message $YELLOW "Installing Flatpak package: $package"
            if ! flatpak install -y $package; then
                print_message $RED "Error: Failed to install Flatpak package: $package"
                exit 1
            fi
        else
            print_message $GREEN "Flatpak package already installed: $package"
        fi
    done < flatpak_packages.txt
    print_message $GREEN "Flatpak packages installed successfully."
else
    print_message $RED "flatpak_packages.txt not found. Skipping Flatpak package installation."
fi
