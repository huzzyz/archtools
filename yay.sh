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
if ! command -v yay &> /dev/null; then
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
else
    print_message $GREEN "yay is already installed."
fi
