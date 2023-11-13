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

# Check for the presence of packages.txt and flatpak_packages.txt
PACKAGES_FILE="packages.txt"
FLATPAK_PACKAGES_FILE="flatpak_packages.txt"
INSTALL_PACKAGES=false
INSTALL_FLATPAK_PACKAGES=false

if [ -f "$PACKAGES_FILE" ]; then
    INSTALL_PACKAGES=true
else
    print_message $RED "Warning: $PACKAGES_FILE not found. Skipping Arch/AUR package installation."
fi

if [ -f "$FLATPAK_PACKAGES_FILE" ]; then
    INSTALL_FLATPAK_PACKAGES=true
else
    print_message $RED "Warning: $FLATPAK_PACKAGES_FILE not found. Skipping Flatpak package installation."
fi

# Rest of the script (like checking for AMD GPU, installing yay and powerpill)...

# Install packages using yay
if [ "$INSTALL_PACKAGES" = true ]; then
    print_message $YELLOW "Installing Arch/AUR packages from $PACKAGES_FILE..."
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
    done < "$PACKAGES_FILE"
    print_message $GREEN "Arch/AUR packages installed successfully."
fi

# Install Flatpak packages
if [ "$INSTALL_FLATPAK_PACKAGES" = true ]; then
    print_message $YELLOW "Installing Flatpak packages from $FLATPAK_PACKAGES_FILE..."
    while IFS= read -r package || [[ -n "$package" ]]; do
        if ! flatpak list | grep -q $package; then
            print_message $YELLOW "Installing Flatpak package: $package"
            if ! flatpak install --noconfirm -y $package; then
                print_message $RED "Error: Failed to install Flatpak package: $package"
                exit 1
            fi
        else
            print_message $GREEN "Flatpak package already installed: $package"
        fi
    done < "$FLATPAK_PACKAGES_FILE"
    print_message $GREEN "Flatpak packages installed successfully."
fi
