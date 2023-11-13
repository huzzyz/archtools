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

# Install powerpill using yay
if ! command -v powerpill &> /dev/null; then
    print_message $YELLOW "Installing powerpill using yay..."
    yay -S --needed --noconfirm powerpill
    if [ $? -eq 0 ]; then
        print_message $GREEN "powerpill installed successfully."
    else
        print_message $RED "Failed to install powerpill."
        exit 1
    fi
else
    print_message $GREEN "powerpill is already installed."
fi

# Configure yay to use powerpill
print_message $YELLOW "Configuring yay to use powerpill..."
yay -Syu --save --noconfirm
sed -i 's|"pacmanbin": "pacman"|"pacmanbin": "powerpill"|' ~/.config/yay/config.json
print_message $GREEN "yay configuration updated for powerpill."
