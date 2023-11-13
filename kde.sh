#!/bin/bash

# Define the list of packages to install
packages=(
    "plasma-meta"
    "kitty"
    "kate"
    "dolphin"
    "ark"
    "plasma-wayland-session"
    "egl-wayland"
)

# Update the system and install packages
sudo pacman -Syu --needed --noconfirm "${packages[@]}"
