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

# Install yay
install_yay() {
    if command -v yay &> /dev/null; then
        print_message $GREEN "yay is already installed."
    else
        print_message $YELLOW "Installing yay..."
        sudo pacman -Sy --needed --noconfirm git base-devel
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        if [ $? -eq 0 ]; then
            cd ..
            rm -rf yay
            print_message $GREEN "yay installed successfully."
        else
            print_message $RED "Failed to install yay."
            exit 1
        fi
    fi
}

# Install powerpill using yay
install_powerpill() {
    print_message $YELLOW "Installing powerpill using yay..."
    if yay -S --needed --noconfirm powerpill; then
        print_message $GREEN "powerpill installed successfully."
    else
        print_message $RED "Failed to install powerpill."
        exit 1
    fi
}

# Install Arch/AUR packages
install_arch_packages() {
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

# Install Flatpak packages
install_flatpak_packages() {
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

# Main script execution
install_yay
install_powerpill
install_arch_packages
install_flatpak_packages
