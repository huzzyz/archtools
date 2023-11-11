#!/bin/bash

# Script to install yay (Yet Another Yaourt) - AUR Helper

echo "Starting the installation of yay (Yet Another Yaourt) AUR Helper..."

# Update system and install git and base-devel if they are not already installed
echo "Updating system and installing necessary packages..."
sudo pacman -Syu --needed git base-devel

# Check if git clone is successful
echo "Cloning the yay repository from AUR..."
if git clone https://aur.archlinux.org/yay.git; then
    echo "Successfully cloned the yay repository."
else
    echo "Failed to clone the yay repository. Exiting."
    exit 1
fi

# Change directory to the cloned yay directory
cd yay || { echo "Directory 'yay' not found. Exiting."; exit 1; }

# Build and install yay
echo "Building and installing yay..."
if makepkg -si; then
    echo "yay has been successfully installed."
else
    echo "Failed to install yay. Exiting."
    exit 1
fi

# Return to the original directory
cd ..

echo "yay installation complete."
