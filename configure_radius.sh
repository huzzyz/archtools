#!/bin/bash

# Function to check if running with sudo
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root. Use sudo."
        exit 1
    fi
}

# Function to check and install jq if not present
check_jq_installed() {
    if ! command -v jq &> /dev/null; then
        echo "jq is not installed. Installing jq..."
        apt-get update
        apt-get install -y jq
    fi
}

# Function to search for FreeRADIUS configuration files
search_config_files() {
    clients_conf=$(find /etc/freeradius -name 'clients.conf' | head -n 1)
    eap_conf=$(find /etc/freeradius -name 'eap' | grep 'mods-available' | head -n 1)

    if [ -z "$clients_conf" ] || [ -z "$eap_conf" ]; then
        echo "Unable to locate FreeRADIUS configuration files."
        exit 1
    fi
}

# Function to prompt for JSON file location
prompt_for_json_file() {
    read -p "Enter the path to your configuration JSON file or press Enter to use the default (./config.json): " json_file
    json_file="${json_file:-./config.json}"

    if [ ! -f "$json_file" ]; then
        echo "Configuration file not found at $json_file."
        exit 1
    fi
}

# Read JSON using jq
read_json() {
    jq -r "$1" "$json_file"
}

# Function to apply client configurations
apply_client_configurations() {
    total_clients=$(read_json '.clients | length')
    for (( i=0; i<"$total_clients"; i++ ))
    do
        name=$(read_json ".clients[$i].name")
        ip=$(read_json ".clients[$i].ip")
        sharedKey=$(read_json ".clients[$i].sharedKey")

        # Add client to clients.conf
        echo "client \"$name\" {" >> "$clients_conf"
        echo "    ipaddr = $ip" >> "$clients_conf"
        echo "    secret = $sharedKey" >> "$clients_conf"
        echo "}" >> "$clients_conf"
    done
}

# Function to test FreeRADIUS configuration
test_freeradius_config() {
    systemctl restart freeradius.service
    if systemctl is-active --quiet freeradius.service; then
        echo "FreeRADIUS configuration test passed."
    else
        echo "FreeRADIUS configuration test failed."
        return 1
    fi
}
# Function to compare configuration files with their backups
output_config_changes() {
    echo "Outputting changes made in the configuration files:"

    # Paths to configuration files and their backups
    local eap_config="/etc/freeradius/3.0/mods-available/eap"
    local clients_config="/etc/freeradius/3.0/clients.conf"
    local eap_config_backup="${eap_config}.backup"
    local clients_config_backup="${clients_config}.backup"

    # Check and output changes for EAP configuration
    if [ -f "$eap_config_backup" ]; then
        echo "Changes in EAP configuration:"
        diff "$eap_config_backup" "$eap_config"
    else
        echo "No backup found for EAP configuration."
    fi

    # Check and output changes for clients configuration
    if [ -f "$clients_config_backup" ]; then
        echo "Changes in Clients configuration:"
        diff "$clients_config_backup" "$clients_config"
    else
        echo "No backup found for Clients configuration."
    fi
}

# Main script execution
check_root
check_jq_installed
search_config_files
prompt_for_json_file

# Backup existing configuration
cp "$clients_conf" "${clients_conf}.backup"
cp "$eap_conf" "${eap_conf}.backup"

apply_client_configurations

# Test FreeRADIUS configuration
if ! test_freeradius_config; then
    echo "Restoring backup due to failed configuration."
    cp "${clients_conf}.backup" "$clients_conf"
    cp "${eap_conf}.backup" "$eap_conf"
    exit 1
else
    echo "FreeRADIUS configuration updated successfully."
    output_config_changes
fi