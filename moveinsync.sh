#!/bin/bash
# tailscale-up.sh — Installs Tailscale and brings it up with a key, after confirmation

set -euo pipefail

read -rp "This will install and connect Tailscale using a predefined auth key. Proceed? [y/N]: " confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "[-] Installation aborted."
  exit 1
fi

echo "[+] Downloading and running Tailscale installer..."
curl -fsSL https://tailscale.com/install.sh | sh

echo "[+] Authenticating with Tailscale..."
sudo tailscale up --auth-key=tskey-auth-kHy3wR4D4B21CNTRL-f3yLjgrYni9HSrwKzK8ti9F2oG3BfGXo1

echo "[✓] Tailscale is up and running."
