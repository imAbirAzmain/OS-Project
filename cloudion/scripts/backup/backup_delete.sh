#!/usr/bin/env bash
# backup_delete.sh — deletes a named backup archive from backups/.
# Usage: backup_delete.sh <archive_name>
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
[[ $# -ge 1 ]] || { echo "Usage: $(basename "$0") <archive_name>" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
validate_filename "$1"
resolved="$(resolve_within_base "$BACKUPS_ROOT" "$1")"
[[ -f "$resolved" ]] || die "$EXIT_FILE_NOT_FOUND" "Backup not found: $1"
rm -f -- "$resolved"
log_event "backup" "BACKUP_DELETE" "system" "archive=${resolved}"
emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
emit MESSAGE "Backup deleted"
exit "$EXIT_SUCCESS"
