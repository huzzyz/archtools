#!/bin/bash

# Global variables
BACKUP_DIR="/tmp/kde_backup_preparation"

# Function to display usage instructions
display_usage() {
    echo "Usage Instructions for Backup & Restore Script:"
    echo "1. To perform a backup (default location):"
    echo "   ./backup_script.sh"
    echo "2. To perform a backup (custom location):"
    echo "   ./backup_script.sh backup /custom/backup/location"
    echo "3. To restore from a backup:"
    echo "   ./backup_script.sh restore /path/to/backup.tar.gz"
    echo ""
}

# Function to advise users to close running applications
advise_to_close_apps() {
    echo "Please close all running applications, especially web browsers, before proceeding with the backup."
    read -p "Press Enter to continue if you have closed the applications, or Ctrl+C to cancel..."
}

# Function to display output in an ASCII box
display_box() {
    local -r content=("$@")
    local max_len=0

    for line in "${content[@]}"; do
        (( ${#line} > max_len )) && max_len=${#line}
    done

    local border=$(printf '=%.0s' $(seq 1 $((max_len + 2))))
    echo "┌$border┐"

    for line in "${content[@]}"; do
        printf "| %-${max_len}s |\n" "$line"
    done

    echo "└$border┘"
}

# Function to get summary of files and their total size in a directory
get_dir_summary() {
    local dir=$1
    local total_files=$(find "$dir" -type f | wc -l)
    local total_size=$(du -sh "$dir" | cut -f1)
    echo "$total_files files, Total Size: $total_size"
}

# Function to list backed up configurations with sizes concisely
list_backed_up_configs() {
    local config_summary=$(get_dir_summary "$BACKUP_DIR/config")
    local share_summary=$(get_dir_summary "$BACKUP_DIR/local_share")
    local configs=("Backup Configurations Summary:" "Location        Files & Size" "---------       ------------" "config          $config_summary" "local_share     $share_summary")

    display_box "${configs[@]}"
}

# Function to display output in a table format
display_table() {
    local backup_location=$1
    local token=$2
    local size=$(du -sh "$backup_location" | cut -f1)
    local lines=(
        "Backup Details:"
        "----------------"
        "Location:        $backup_location"
        "Token:           $token"
        "Total Size:      $size"
    )
    display_box "${lines[@]}"
}

# Function to perform actual backup
perform_backup() {
    local backup_location=${1:-$(pwd)}
    local date_stamp=$(date +%Y%m%d_%H%M%S)
    local readable_date=$(date +%Y-%m-%d_%H-%M-%S)
    local backup_dir_name="kde_backup_${readable_date}"
    local backup_root_dir="${backup_location}/${date_stamp}"
    local tar_name="${backup_dir_name}.tar.gz"

    mkdir -p "$backup_root_dir"

    # Create a unique token for identification
    local token=$(echo "$backup_dir_name" | md5sum | awk '{print $1}')

    echo "Creating backup archive at $backup_root_dir/$tar_name"
    tar -czf "$backup_root_dir/$tar_name" --warning=no-file-ignored -C "$BACKUP_DIR" .
    echo "Backup archive created."

    rm -rf "$BACKUP_DIR"

    echo "Backup completed."
    display_table "$backup_root_dir" "$token"
}

# Function to perform restore from backup
perform_restore() {
    local backup_archive=$1
    local restore_dir="/tmp/kde_restore"

    # Check if backup archive exists
    if [ ! -f "$backup_archive" ]; then
        echo "Backup archive not found: $backup_archive"
        exit 1
    fi

    echo "Restoring from $backup_archive..."
    mkdir -p "$restore_dir"
    tar -xzf "$backup_archive" -C "$restore_dir"

    # Restore configurations
    cp -r "$restore_dir/config/." "$HOME/.config/"
    cp -r "$restore_dir/local_share/." "$HOME/.local/share/"

    echo "Restore completed. Please check your restored files."
}

# Function to prepare for backup
prepare_backup() {
    local custom_backup_location=$1
    local config_dir="$HOME/.config"
    local local_share_dir="$HOME/.local/share"

    advise_to_close_apps

    mkdir -p "$BACKUP_DIR/config" "$BACKUP_DIR/local_share"

    echo "Copying configurations..."
    rsync -avh --progress "$config_dir/" "$BACKUP_DIR/config/" >/dev/null 2>&1

    echo "Copying local share data..."
    rsync -avh --progress "$local_share_dir/" "$BACKUP_DIR/local_share/" >/dev/null 2>&1

    echo "Configurations and data copied."

    # List a summary of configurations and sizes
    list_backed_up_configs

    # Perform the actual backup
    perform_backup "$custom_backup_location"
}

# Main script execution
clear
display_usage
echo "Backup & Restore Script Starting..."

# Process script arguments
if [ "$1" == "restore" ] && [ -n "$2" ]; then
    perform_restore "$2"
elif [ "$1" == "backup" ]; then
    prepare_backup "$2"
else
    prepare_backup
fi
