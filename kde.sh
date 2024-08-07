#!/bin/bash

# Define the list of packages to install
packages=(
    "kate"
    "dolphin"
    "sddm"
    "plasma-meta"
    "ark"
    "plasma-desktop"
)

# Update the system and install packages
sudo pacman -Syu --needed --noconfirm "${packages[@]}"
