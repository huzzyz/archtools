#!/bin/bash

# Function to display messages in color
print_message() {
    COLOR=$1
    TEXT=$2
    NC='\033[0m' # No Color
    printf "${COLOR}${TEXT}${NC}\n"
}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'

# Install yay if it's not installed
if ! command -v yay &> /dev/null; then
    print_message $YELLOW "Installing yay..."
    sudo pacman -Sy --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
fi

# Configure yay to use powerpill
print_message $YELLOW "Configuring yay to use powerpill..."
yay -Syu --save --noconfirm
sed -i 's|"pacmanbin": "pacman"|"pacmanbin": "powerpill"|' ~/.config/yay/config.json

# Install powerpill for faster downloads if not installed
if ! command -v powerpill &> /dev/null; then
    print_message $YELLOW "Installing powerpill..."
    yay -S --needed --noconfirm powerpill
fi

# Install packages using yay
print_message $YELLOW "Installing Arch/AUR packages from packages.txt..."
while IFS= read -r package || [[ -n "$package" ]]; do
    if ! pacman -Qi $package &> /dev/null; then
        if ! yay -S --needed --noconfirm $package; then
            print_message $RED "Error: Failed to install package: $package"
            exit 1
        fi
    else
        print_message $GREEN "Package already installed: $package"
    fi
done < packages.txt

print_message $GREEN "Arch/AUR packages installed successfully."

# Install Flatpak packages with --noconfirm
print_message $YELLOW "Installing Flatpak packages from flatpak_packages.txt..."
while IFS= read -r package || [[ -n "$package" ]]; do
    if ! flatpak list | grep -q $package; then
        if ! flatpak install -y $package; then
            print_message $RED "Error: Failed to install Flatpak package: $package"
            exit 1
        fi
    else
        print_message $GREEN "Flatpak package already installed: $package"
    fi
done < flatpak_packages.txt

print_message $GREEN "Flatpak packages installed successfully."
