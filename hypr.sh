#!/bin/bash

# Define the list of packages to install
packages=(
    "hyprland"
    "dunst"
    "kitty"
    "dolphin"
    "wofi"
    "xdg-desktop-portal-hyprland"
    "qt5-wayland"
    "qt6-wayland"
)

# Update the system and install packages
sudo pacman -Syu --needed --noconfirm "${packages[@]}"
