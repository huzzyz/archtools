#!/bin/bash

# Install necessary packages
yay -S snapper-support btrfs-assistant --noconfirm && sudo systemctl enable --now grub-btrfsd

# Unmount and remove the existing .snapshots directory
sudo umount /.snapshots
sudo rm -r /.snapshots

# Create snapper configurations for root and home
sudo snapper -c root create-config /
sudo snapper -c home create-config /home

# Delete the old .snapshots subvolume if it exists
sudo btrfs subvolume delete /.snapshots/ || true

# Create a new .snapshots directory and subvolume
sudo mkdir /.snapshots
sudo btrfs subvolume create /.snapshots

# Set the default subvolume to the newly created .snapshots subvolume
subvol_id=$(sudo btrfs subvol list / | grep -E 'path @' | awk '{print $2}')
sudo btrfs subvolume set-default "$subvol_id" /

# Mount all subvolumes
sudo mount -a

# Edit snapper config files
sudo sed -i '/ALLOW_GROUPS=/c\ALLOW_GROUPS="wheel"' /etc/snapper/configs/root
sudo sed -i '/ALLOW_GROUPS=/c\ALLOW_GROUPS="wheel"' /etc/snapper/configs/home

# Set timeline cleanup limits
for config in root home; do
  sudo sed -i '/^TIMELINE_MIN_AGE=/c\TIMELINE_MIN_AGE="1800"' "/etc/snapper/configs/$config"
  sudo sed -i '/^TIMELINE_LIMIT_HOURLY=/c\TIMELINE_LIMIT_HOURLY="5"' "/etc/snapper/configs/$config"
  sudo sed -i '/^TIMELINE_LIMIT_DAILY=/c\TIMELINE_LIMIT_DAILY="7"' "/etc/snapper/configs/$config"
  sudo sed -i '/^TIMELINE_LIMIT_WEEKLY=/c\TIMELINE_LIMIT_WEEKLY="0"' "/etc/snapper/configs/$config"
  sudo sed -i '/^TIMELINE_LIMIT_MONTHLY=/c\TIMELINE_LIMIT_MONTHLY="0"' "/etc/snapper/configs/$config"
  sudo sed -i '/^TIMELINE_LIMIT_YEARLY=/c\TIMELINE_LIMIT_YEARLY="0"' "/etc/snapper/configs/$config"
done

# Change ownership of the .snapshots directory
sudo chown -R :wheel /.snapshots/

# Enable and start necessary services
sudo systemctl enable --now grub-btrfsd
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer

# Create initial snapshots
sudo snapper -c root create -d "***** Base System Root *****"
sudo snapper -c home create -d "***** Base System Home *****"

# List the snapshots
snapper ls

# End of the script
