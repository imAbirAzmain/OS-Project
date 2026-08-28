#!/bin/bash

############################################################
# AzTerm v2 Installation Script
############################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo
echo "=========================================="
echo "      AzTerm v2 Installation"
echo "=========================================="
echo

# Check Bash version
BASH_VERSION_MAJOR=$(echo $BASH_VERSION | cut -d. -f1)
if [[ $BASH_VERSION_MAJOR -lt 3 ]]; then
    echo "Error: Bash 3.2+ required. Your version: $BASH_VERSION"
    exit 1
fi

echo "✓ Bash version: $BASH_VERSION"
echo

# Make scripts executable
echo "Making scripts executable..."
chmod +x "$SCRIPT_DIR/azterm.sh"
chmod +x "$SCRIPT_DIR/install.sh"
chmod +x "$SCRIPT_DIR/uninstall.sh"
chmod +x "$SCRIPT_DIR/update.sh"
chmod +x "$SCRIPT_DIR/lib/"*.sh
chmod +x "$SCRIPT_DIR/config/"*.sh

echo "✓ Scripts are executable"
echo

# Create data directory if it doesn't exist
if [[ ! -d "$SCRIPT_DIR/data" ]]; then
    echo "Creating data directory..."
    mkdir -p "$SCRIPT_DIR/data"
    echo "✓ Data directory created"
else
    echo "✓ Data directory exists"
fi

# Initialize history file if it doesn't exist
if [[ ! -f "$SCRIPT_DIR/data/history.txt" ]]; then
    echo "Initializing history file..."
    touch "$SCRIPT_DIR/data/history.txt"
    echo "✓ History file created"
else
    echo "✓ History file exists"
fi

# Create scripts directory if it doesn't exist
if [[ ! -d "$SCRIPT_DIR/scripts" ]]; then
    echo "Creating scripts directory..."
    mkdir -p "$SCRIPT_DIR/scripts"
    echo "✓ Scripts directory created"
else
    echo "✓ Scripts directory exists"
fi

echo
echo "=========================================="
echo "    Installation Completed Successfully"
echo "=========================================="
echo
echo "To start AzTerm, run:"
echo "  $SCRIPT_DIR/azterm.sh"
echo
echo "For help, run:"
echo "  ./azterm.sh"
echo "  az:~> help"
echo
