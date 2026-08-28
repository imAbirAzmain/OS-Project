#!/bin/bash

############################################################
# AzTerm v2 Update Script
############################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo
echo "=========================================="
echo "      AzTerm v2 Update Utility"
echo "=========================================="
echo

# Source config to get current version
source "$SCRIPT_DIR/config/config.sh"

echo "Current AzTerm Version: $AZTERM_VERSION"
echo

# For now, this is a reinitialize utility
# Future versions could check for updates online

echo "This utility ensures all AzTerm components are properly initialized."
echo

# Reinitialize permissions
echo "Updating script permissions..."
chmod +x "$SCRIPT_DIR/azterm.sh"
chmod +x "$SCRIPT_DIR/lib/"*.sh
chmod +x "$SCRIPT_DIR/config/"*.sh
echo "✓ Permissions updated"
echo

# Ensure data directory exists
if [[ ! -d "$SCRIPT_DIR/data" ]]; then
    echo "Creating data directory..."
    mkdir -p "$SCRIPT_DIR/data"
    echo "✓ Data directory created"
fi

# Ensure history file exists but don't reinitialize it
if [[ ! -f "$SCRIPT_DIR/data/history.txt" ]]; then
    echo "Initializing history file..."
    touch "$SCRIPT_DIR/data/history.txt"
    echo "✓ History file created"
else
    echo "✓ History file exists (preserved)"
fi

# Ensure scripts directory exists
if [[ ! -d "$SCRIPT_DIR/scripts" ]]; then
    echo "Creating scripts directory..."
    mkdir -p "$SCRIPT_DIR/scripts"
    echo "✓ Scripts directory created"
else
    echo "✓ Scripts directory exists (preserved)"
fi

echo
echo "=========================================="
echo "      Update Completed Successfully"
echo "=========================================="
echo
echo "All AzTerm components are initialized."
echo
echo "Your user data (history and scripts) has been preserved."
echo
echo "To run AzTerm, execute:"
echo "  $SCRIPT_DIR/azterm.sh"
echo

