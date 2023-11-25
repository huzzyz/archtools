#!/bin/bash

# Define color codes for colored output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display messages in color
print_message() {
    COLOR=$1
    TEXT=$2
    printf "\n${COLOR}${TEXT}${NC}\n"
}

# Check if the snap_packages.txt file exists
if [ ! -f "snap_packages.txt" ]; then
    print_message $RED "Error: snap_packages.txt file not found. Please create the file with a list of Snap packages to install."
    exit 1
fi

# Install Snap packages from the file
while IFS= read -r package || [[ -n "$package" ]]; do
    if ! snap list | grep -q "^$package "; then
        print_message $YELLOW "Attempting to install Snap package: $package..."
        if sudo snap install "$package"; then
            print_message $GREEN "Successfully installed Snap package: $package."
        else
            print_message $RED "Error: Failed to install Snap package: $package. Check for typos or package availability."
            exit 1
        fi
    else
        print_message $GREEN "Package already installed: $package."
    fi
done < snap_packages.txt

print_message $GREEN "All specified Snap packages have been installed successfully."

# Start and enable snapd and related services
print_message $YELLOW "Starting and enabling snapd services..."
sudo systemctl start snapd
sudo systemctl enable --now snapd.apparmor
sudo systemctl enable --now snapd.service
print_message $GREEN "snapd services have been started and enabled successfully."

# End of script
print_message $GREEN "Script execution completed."
