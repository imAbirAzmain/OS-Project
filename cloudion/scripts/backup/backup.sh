#!/usr/bin/env bash
# =============================================================================
# backup.sh — creates a compressed archive of storage/ (and optionally the
# database file) using tar + gzip.
#
# Usage: backup.sh [label]
#   label   optional short label included in the archive filename
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

label="${1:-manual}"
label="${label//[^a-zA-Z0-9_-]/_}"

ensure_dir "$BACKUPS_ROOT" 0750
timestamp="$(date -u +'%Y%m%dT%H%M%SZ')"
archive_name="backup_${label}_${timestamp}.tar.gz"
archive_path="${BACKUPS_ROOT}/${archive_name}"

tar_targets=("storage")
if [[ -d "${PROJECT_ROOT}/config" ]]; then
    tar_targets+=("config")
fi

if ! tar -czf "$archive_path" -C "$PROJECT_ROOT" "${tar_targets[@]}" 2>/dev/null; then
    die "$EXIT_STORAGE_ERROR" "Backup failed while creating archive"
fi

size_bytes="$(file_stat_size "$archive_path")"
log_event "backup" "BACKUP_CREATE" "system" "archive=${archive_path} size=${size_bytes}"

emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
emit MESSAGE "Backup created successfully"
emit ARCHIVE_NAME "$archive_name"
emit ARCHIVE_PATH "$archive_path"
emit ARCHIVE_SIZE_BYTES "$size_bytes"
exit "$EXIT_SUCCESS"
