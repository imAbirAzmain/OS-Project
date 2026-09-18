#!/usr/bin/env bash
# =============================================================================
# delete_group_storage.sh — archives and removes a deleted group's storage.
# Same "archive, then remove" policy as delete_user_storage.sh — group files
# are not destroyed irrecoverably by a single delete action.
# Usage: delete_group_storage.sh <group_id>
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
[[ $# -ge 1 ]] || { echo "Usage: $(basename "$0") <group_id>" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
group_id="$1"
group_root="${STORAGE_ROOT}/groups/group_${group_id}"
[[ -d "$group_root" ]] || die "$EXIT_FILE_NOT_FOUND" "No storage found for group: $group_id"

archive_dir="${BACKUPS_ROOT}/deleted_groups"
ensure_dir "$archive_dir" 0750
timestamp="$(date -u +'%Y%m%dT%H%M%SZ')"
archive_path="${archive_dir}/group_${group_id}_${timestamp}.tar.gz"

if ! tar -czf "$archive_path" -C "${STORAGE_ROOT}/groups" "group_${group_id}"; then
    die "$EXIT_STORAGE_ERROR" "Failed to archive group storage for: $group_id"
fi
if ! rm -rf -- "$group_root"; then
    die "$EXIT_STORAGE_ERROR" "Failed to remove live storage for group: $group_id"
fi

log_event "group" "GROUP_STORAGE_DELETE" "system" "group_id=${group_id} archive=${archive_path}"
emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
emit MESSAGE "Group storage archived and removed"
emit ARCHIVE_PATH "$archive_path"
exit "$EXIT_SUCCESS"
