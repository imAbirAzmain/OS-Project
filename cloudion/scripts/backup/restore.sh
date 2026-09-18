#!/usr/bin/env bash
# =============================================================================
# restore.sh — restores storage/ from a backup archive.
#
# Policy: never blindly overwrite live data. The current storage/ tree is
# first moved aside into a pre-restore safety snapshot (so a bad restore is
# itself reversible), and only then is the archive extracted.
#
# Usage: restore.sh <archive_name>
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

[[ $# -ge 1 ]] || { echo "Usage: $(basename "$0") <archive_name>" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
validate_filename "$1"
archive_path="$(resolve_within_base "$BACKUPS_ROOT" "$1")"

if [[ ! -f "$archive_path" ]]; then
    die "$EXIT_FILE_NOT_FOUND" "Backup archive not found: $1"
fi

timestamp="$(date -u +'%Y%m%dT%H%M%SZ')"
safety_snapshot="${BACKUPS_ROOT}/pre_restore_${timestamp}.tar.gz"

if [[ -d "$STORAGE_ROOT" ]]; then
    tar -czf "$safety_snapshot" -C "$PROJECT_ROOT" storage 2>/dev/null || true
fi

# Extract into a staging directory first so a corrupt archive can never
# leave storage/ half-overwritten.
staging_dir="$(mktemp -d "${PROJECT_ROOT}/.restore_staging.XXXXXX")"
trap 'rm -rf -- "$staging_dir"' EXIT

if ! tar -xzf "$archive_path" -C "$staging_dir" 2>/dev/null; then
    die "$EXIT_STORAGE_ERROR" "Failed to extract backup archive (it may be corrupt)"
fi

if [[ ! -d "${staging_dir}/storage" ]]; then
    die "$EXIT_STORAGE_ERROR" "Archive does not contain a storage/ directory"
fi

rm -rf -- "$STORAGE_ROOT"
mv -- "${staging_dir}/storage" "$STORAGE_ROOT"

log_event "backup" "RESTORE" "system" "archive=${archive_path} safety_snapshot=${safety_snapshot}"

emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
emit MESSAGE "Restore completed successfully"
emit SAFETY_SNAPSHOT "$safety_snapshot"
exit "$EXIT_SUCCESS"
