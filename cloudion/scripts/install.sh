#!/bin/bash
# Path: mini_cloud/scripts/install.sh
# Description: One-step environment initializer and dependency checker

set -e # Exit immediately if any command fails

echo "=================================================="
echo "    Mini Cloud - System Installation & Setup     "
echo "=================================================="

# 1. Verify required GCC and Linux system tools
echo "[+] Checking system dependencies..."
for tool in gcc make curl ss pgrep; do
    if ! command -v $tool &> /dev/null; then
        echo "[✘] Error: Required tool '$tool' is not installed."
        exit 1
    fi
done
echo "[✔] All dependencies detected."

# 2. Construct Master Directory Hierarchy
echo "[+] Constructing directory structure..."
mkdir -p src include cli scripts config systemd bin logs backups storage

# 3. Initialize default system users with POSIX security permissions
echo "[+] Initializing user storage environments..."
mkdir -p storage/admin storage/alice storage/bob

# POSIX Security: 700 means ONLY the user owner has Read/Write/Execute access
chmod 700 storage/admin
chmod 700 storage/alice
chmod 700 storage/bob

# 4. Create initial default files for testing
echo "<h1>Admin Cloud Storage</h1>" > storage/admin/index.html
echo "<h1>Alice Cloud Storage</h1>" > storage/alice/index.html
echo "<h1>Bob Cloud Storage</h1>"   > storage/bob/index.html

# 5. Initialize Empty Log Files
touch logs/server.log logs/audit.log logs/monitor.log

echo "=================================================="
echo "[✔] Environment successfully initialized!"
echo "    Storage Root : storage/"
echo "    Config File  : config/server.conf"
echo "=================================================="
