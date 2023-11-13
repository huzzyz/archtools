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

install_yay_and_powerpill() {
    # Install yay if it's not installed
    if ! command -v yay &> /dev/null; then
        print_message $YELLOW "Installing yay..."
        sudo pacman -Sy --needed --noconfirm git base-devel
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd ..
        rm -rf yay
        print_message $GREEN "yay installed successfully."
    else
        print_message $GREEN "yay is already installed."
    fi

    # Configure yay to use powerpill
    print_message $YELLOW "Configuring yay to use powerpill..."
    yay -Syu --save --noconfirm
    sed -i 's|"pacmanbin": "pacman"|"pacmanbin": "powerpill"|' ~/.config/yay/config.json

    # Install powerpill for faster downloads if not installed
    if ! command -v powerpill &> /dev/null; then
        print_message $YELLOW "Installing powerpill..."
        yay -S --needed --noconfirm powerpill
        print_message $GREEN "powerpill installed successfully."
    else
        print_message $GREEN "powerpill is already installed."
    fi
}

install_packages() {
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
}

install_flatpak_packages() {
    # Install Flatpak packages
    if [ -f "flatpak_packages.txt" ]; then
        print_message $YELLOW "Installing Flatpak packages from flatpak_packages.txt..."
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
        done < flatpak_packages.txt
        print_message $GREEN "Flatpak packages installed successfully."
    else
        print_message $RED "flatpak_packages.txt not found. Skipping Flatpak package installation."
    fi
}

# Main script starts here
install_yay_and_powerpill
install_packages
install_flatpak_packages
