#!/usr/bin/env bash
# group_delete_file.sh — deletes a file from a group's shared storage.
# Usage: group_delete_file.sh <group_id> <relative_path> <actor>
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
[[ $# -ge 3 ]] || { echo "Usage: $(basename "$0") <group_id> <relative_path> <actor>" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
group_id="$1"; relative_path="$2"; actor="$3"
base_dir="${STORAGE_ROOT}/groups/group_${group_id}/files"
exec "${SCRIPT_DIR}/../files/file_delete.sh" "$base_dir" "$relative_path" "$actor" "group"
