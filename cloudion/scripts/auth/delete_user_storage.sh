#!/usr/bin/env bash
# =============================================================================
# delete_user_storage.sh — retires a deleted user's storage.
#
# Policy: rather than blindly rm -rf, archive the user's tree into
# backups/deleted_users/ with a timestamp, then remove it from the live
# storage tree. An administrator can restore from the archive if needed.
#
# Usage: delete_user_storage.sh <username>
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

[[ $# -ge 1 ]] || { echo "Usage: $(basename "$0") <username>" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
username="$1"
if [[ ! "$username" =~ ^[a-zA-Z0-9_-]{3,32}$ ]]; then
    die "$EXIT_INVALID_ARGUMENT" "Invalid username format: $username"
fi

user_root="${STORAGE_ROOT}/users/${username}"
if [[ ! -d "$user_root" ]]; then
    die "$EXIT_FILE_NOT_FOUND" "No storage found for user: $username"
fi

archive_dir="${BACKUPS_ROOT}/deleted_users"
ensure_dir "$archive_dir" 0750
timestamp="$(date -u +'%Y%m%dT%H%M%SZ')"
archive_path="${archive_dir}/${username}_${timestamp}.tar.gz"

if ! tar -czf "$archive_path" -C "${STORAGE_ROOT}/users" "$username"; then
    die "$EXIT_STORAGE_ERROR" "Failed to archive user storage for: $username"
fi

if ! rm -rf -- "$user_root"; then
    die "$EXIT_STORAGE_ERROR" "Failed to remove live storage for: $username"
fi

meta_file="${STORAGE_ROOT}/accounts/${username}.json"
if [[ -f "$meta_file" ]]; then
    rm -f -- "$meta_file" || die "$EXIT_STORAGE_ERROR" "Failed to remove account metadata for: $username"
fi

log_event "file" "USER_STORAGE_DELETE" "$username" "archive=${archive_path}"

emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
emit MESSAGE "User storage archived and removed"
emit ARCHIVE_PATH "$archive_path"
exit "$EXIT_SUCCESS"
