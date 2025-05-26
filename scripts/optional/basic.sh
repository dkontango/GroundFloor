#!/bin/bash

# Firefox to Chromium Migration Script
# This script removes Firefox (if installed) and installs Chromium using snap

set -e  # Exit on any error

echo "=== Firefox to Chromium Migration Script ==="
echo

# Function to check if a snap package is installed
is_snap_installed() {
    snap list "$1" &>/dev/null
}

# Function to check if Firefox is installed via apt
is_firefox_apt_installed() {
    dpkg -l | grep -q "^ii.*firefox" 2>/dev/null
}

# Check if snap is available
if ! command -v snap &> /dev/null; then
    echo "Error: snap is not installed or not available on this system."
    echo "Please install snapd first: sudo apt update && sudo apt install snapd"
    exit 1
fi

echo "Checking for existing Firefox installations..."

# Check for Firefox snap package
if is_snap_installed "firefox"; then
    echo "Found Firefox snap package. Removing..."
    sudo snap remove firefox
    echo "✓ Firefox snap package removed successfully."
elif is_firefox_apt_installed; then
    echo "Found Firefox installed via apt. Removing..."
    sudo apt remove --purge firefox firefox-esr -y
    sudo apt autoremove -y
    echo "✓ Firefox apt package removed successfully."
else
    echo "Firefox not found via snap or apt."
fi

echo

# Install Chromium
echo "Installing Chromium..."
if is_snap_installed "chromium"; then
    echo "Chromium is already installed."
else
    sudo snap install chromium
    echo "✓ Chromium installed successfully."
fi

echo
echo "=== Migration Complete ==="
echo "Firefox has been removed (if it was installed)"
echo "Chromium is now available and ready to use"
echo
echo "You can launch Chromium by:"
echo "- Searching for 'Chromium' in your applications menu"
echo "- Running 'chromium' from the terminal"