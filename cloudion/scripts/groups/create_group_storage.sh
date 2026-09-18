#!/usr/bin/env bash
# =============================================================================
# create_group_storage.sh — provisions storage for a newly created group.
# Called by the backend right after the group row is inserted (creator
# becomes group admin at the database level).
# Usage: create_group_storage.sh <group_id>
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
[[ $# -ge 1 ]] || { echo "Usage: $(basename "$0") <group_id>" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
group_id="$1"
if [[ ! "$group_id" =~ ^[0-9]+$ ]]; then
    die "$EXIT_INVALID_ARGUMENT" "group_id must be numeric: $group_id"
fi
group_root="${STORAGE_ROOT}/groups/group_${group_id}"
if [[ -d "$group_root" ]]; then
    die "$EXIT_GENERAL_ERROR" "Storage already exists for group: $group_id"
fi
ensure_dir "${group_root}/files" 0750
log_event "group" "GROUP_STORAGE_CREATE" "system" "group_id=${group_id} path=${group_root}"
emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
emit MESSAGE "Group storage created"
emit GROUP_ROOT "$group_root"
exit "$EXIT_SUCCESS"
