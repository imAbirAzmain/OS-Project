#!/usr/bin/env bash
# =============================================================================
# cloudctl.sh — server administration from the Linux terminal.
#
# This proves the cloud server can be managed WITHOUT the web UI at all: it
# calls the exact same scripts the backend calls, just directly from a menu.
#
# Usage:
#   ./cloudctl.sh            interactive menu
#   ./cloudctl.sh status     run a single action non-interactively
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/scripts/lib/common.sh"

pause() { read -rp $'\nPress Enter to continue...' _; }

server_status() {
    echo "== Cloudion Status =="
    "${SCRIPT_DIR}/scripts/cloud/cloud_status.sh"
}

storage_status() {
    echo "== Storage Status =="
    "${SCRIPT_DIR}/scripts/storage/storage_usage.sh"
    echo
    echo "== Per-user breakdown =="
    "${SCRIPT_DIR}/scripts/storage/storage_report.sh"
}

user_management() {
    echo "1) Create user storage"
    echo "2) Delete user storage (archives first)"
    echo "3) Back"
    read -rp "Choice: " c
    case "$c" in
        1) read -rp "Username: " u; "${SCRIPT_DIR}/scripts/auth/create_user_storage.sh" "$u" ;;
        2) read -rp "Username: " u; "${SCRIPT_DIR}/scripts/auth/delete_user_storage.sh" "$u" ;;
        *) ;;
    esac
}

group_management() {
    echo "1) Create group storage"
    echo "2) Delete group storage (archives first)"
    echo "3) List group files"
    echo "4) Back"
    read -rp "Choice: " c
    case "$c" in
        1) read -rp "Group ID: " g; "${SCRIPT_DIR}/scripts/groups/create_group_storage.sh" "$g" ;;
        2) read -rp "Group ID: " g; "${SCRIPT_DIR}/scripts/groups/delete_group_storage.sh" "$g" ;;
        3) read -rp "Group ID: " g; "${SCRIPT_DIR}/scripts/groups/group_list_files.sh" "$g" ;;
        *) ;;
    esac
}

backup_menu() {
    echo "1) Create backup"
    echo "2) List backups"
    echo "3) Restore from backup"
    echo "4) Delete a backup"
    echo "5) Back"
    read -rp "Choice: " c
    case "$c" in
        1) read -rp "Label (optional): " l; "${SCRIPT_DIR}/scripts/backup/backup.sh" "$l" ;;
        2) "${SCRIPT_DIR}/scripts/backup/backup_list.sh" ;;
        3) read -rp "Archive filename: " a; "${SCRIPT_DIR}/scripts/backup/restore.sh" "$a" ;;
        4) read -rp "Archive filename: " a; "${SCRIPT_DIR}/scripts/backup/backup_delete.sh" "$a" ;;
        *) ;;
    esac
}

view_logs() {
    echo "Available logs:"
    ls "${LOGS_ROOT}"/*.log 2>/dev/null || echo "(no logs yet)"
    read -rp "Log filename to tail (blank to cancel): " f
    [[ -z "$f" ]] && return
    validate_filename "$f"
    resolved="$(resolve_within_base "$LOGS_ROOT" "$f")"
    if [[ -f "$resolved" ]]; then
        tail -n 50 "$resolved"
    else
        echo "Log not found: $f"
    fi
}

maintenance_menu() {
    echo "1) Cleanup temp files"
    echo "2) Cleanup old logs"
    echo "3) Cleanup failed uploads"
    echo "4) Back"
    read -rp "Choice: " c
    case "$c" in
        1) "${SCRIPT_DIR}/scripts/maintenance/cleanup_temp.sh" ;;
        2) "${SCRIPT_DIR}/scripts/maintenance/cleanup_old_logs.sh" ;;
        3) "${SCRIPT_DIR}/scripts/maintenance/cleanup_failed_uploads.sh" ;;
        *) ;;
    esac
}

server_start()   { "${SCRIPT_DIR}/scripts/cloud/cloud_start.sh"; }
server_stop()    { "${SCRIPT_DIR}/scripts/cloud/cloud_stop.sh"; }
server_restart() { "${SCRIPT_DIR}/scripts/cloud/cloud_restart.sh"; }

run_menu() {
    while true; do
        cat <<'MENU'

Cloud Server Management
=======================
1. Server Status
2. Storage Status
3. User Management
4. Group Management
5. Backup / Restore
6. View Logs
7. Maintenance
8. Start Server
9. Stop Server
10. Restart Server
11. Exit
MENU
        read -rp "Choice: " choice
        case "$choice" in
            1) server_status ;;
            2) storage_status ;;
            3) user_management ;;
            4) group_management ;;
            5) backup_menu ;;
            6) view_logs ;;
            7) maintenance_menu ;;
            8) server_start ;;
            9) server_stop ;;
            10) server_restart ;;
            11) echo "Goodbye."; exit 0 ;;
            *) echo "Invalid choice." ;;
        esac
        pause
    done
}

# Allow a single non-interactive action for scripting/cron, e.g.:
#   ./cloudctl.sh status
case "${1:-}" in
    status)  server_status ;;
    storage) storage_status ;;
    backup)  "${SCRIPT_DIR}/scripts/backup/backup.sh" "${2:-cron}" ;;
    cleanup) "${SCRIPT_DIR}/scripts/maintenance/cleanup_temp.sh"; "${SCRIPT_DIR}/scripts/maintenance/cleanup_old_logs.sh" ;;
    cloud)   shift; "${SCRIPT_DIR}/scripts/cloud/cloud.sh" "$@" ;;
    "")      run_menu ;;
    *)       echo "Unknown action: $1" >&2; exit "$EXIT_INVALID_ARGUMENT" ;;
esac
