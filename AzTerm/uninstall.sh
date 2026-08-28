#!/bin/bash

############################################################
# AzTerm v2 Uninstallation Script
############################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo
echo "=========================================="
echo "      AzTerm v2 Uninstallation"
echo "=========================================="
echo
echo "WARNING: This will remove AzTerm from your system."
echo
echo "The following will be preserved:"
echo "  - Your script files in: $SCRIPT_DIR/scripts/"
echo
echo "The following will be optionally removed:"
echo "  - Command history: $SCRIPT_DIR/data/history.txt"
echo
read -p "Continue with uninstallation? (yes/no): " RESPONSE

if [[ "$RESPONSE" != "yes" ]]; then
    echo
    echo "Uninstallation cancelled."
    echo
    exit 0
fi

echo
echo "Proceeding with uninstallation..."
echo

# Backup history if requested
if [[ -f "$SCRIPT_DIR/data/history.txt" ]]; then
    read -p "Backup command history before removal? (yes/no): " BACKUP

    if [[ "$BACKUP" == "yes" ]]; then
        BACKUP_FILE="$SCRIPT_DIR/data/history.txt.bak"
        cp "$SCRIPT_DIR/data/history.txt" "$BACKUP_FILE"
        echo "✓ History backed up to: $BACKUP_FILE"
    fi
fi

echo
echo "Removing AzTerm..."
echo

# Remove AzTerm executable
rm -f "$SCRIPT_DIR/azterm.sh"
echo "✓ Removed: azterm.sh"

# Remove scripts (ask first)
if [[ -d "$SCRIPT_DIR/scripts" ]] && [[ -n "$(ls -A "$SCRIPT_DIR/scripts")" ]]; then
    echo
    read -p "Remove user scripts in scripts/ directory? (yes/no): " REMOVE_SCRIPTS
    
    if [[ "$REMOVE_SCRIPTS" == "yes" ]]; then
        rm -rf "$SCRIPT_DIR/scripts"
        echo "✓ Removed: scripts/ directory"
    else
        echo "ℹ User scripts preserved in: $SCRIPT_DIR/scripts/"
    fi
fi

# Remove history (ask first)
if [[ -f "$SCRIPT_DIR/data/history.txt" ]]; then
    read -p "Remove command history? (yes/no): " REMOVE_HISTORY
    
    if [[ "$REMOVE_HISTORY" == "yes" ]]; then
        rm -f "$SCRIPT_DIR/data/history.txt"
        echo "✓ Removed: data/history.txt"
    else
        echo "ℹ History preserved in: $SCRIPT_DIR/data/history.txt"
    fi
fi

echo
echo "=========================================="
echo "    Uninstallation Completed"
echo "=========================================="
echo
echo "To reinstall AzTerm, run:"
echo "  ./install.sh"
echo

