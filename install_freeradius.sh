#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Try 'sudo bash $0'"
    exit 1
fi

# Function to install FreeRADIUS
install_freeradius() {
    echo "Installing FreeRADIUS..."
    apt-get install -y freeradius freeradius-utils freeradius-common
    systemctl enable freeradius.service
    echo "FreeRADIUS has been installed."
}

# Function to generate SSL certificates for EAP
generate_ssl_certificates() {
    echo "Generating SSL certificates..."
    mkdir -p /etc/freeradius/3.0/certs
    openssl genrsa -out /etc/freeradius/3.0/certs/server.key 2048
    openssl req -new -x509 -key /etc/freeradius/3.0/certs/server.key -out /etc/freeradius/3.0/certs/server.pem -days 365 -subj "/CN=$(hostname)/O=YourOrganization/C=US"
    chown freerad:freerad /etc/freeradius/3.0/certs/server.key /etc/freeradius/3.0/certs/server.pem
    chmod 640 /etc/freeradius/3.0/certs/server.key /etc/freeradius/3.0/certs/server.pem
    echo "SSL certificates have been generated."
}

# Function to configure the EAP module
configure_eap() {
    echo "Configuring EAP module..."
    sed -i 's|private_key_file =.*|private_key_file = /etc/freeradius/3.0/certs/server.key|' /etc/freeradius/3.0/mods-available/eap
    sed -i 's|certificate_file =.*|certificate_file = /etc/freeradius/3.0/certs/server.pem|' /etc/freeradius/3.0/mods-available/eap
    ln -s /etc/freeradius/3.0/mods-available/eap /etc/freeradius/3.0/mods-enabled/
    echo "EAP module configured."
}

# Update package lists
echo "Updating package lists..."
apt-get update

# Install and configure FreeRADIUS
install_freeradius

# Generate and configure SSL certificates for EAP
generate_ssl_certificates
configure_eap

# Restart FreeRADIUS to apply all configurations
echo "Restarting FreeRADIUS service..."
systemctl restart freeradius.service

# Verify the status of the FreeRADIUS service
echo "FreeRADIUS installation and configuration complete."