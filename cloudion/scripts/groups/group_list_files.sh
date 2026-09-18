#!/usr/bin/env bash
# group_list_files.sh — lists all files in a group's shared storage.
# Usage: group_list_files.sh <group_id>
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
[[ $# -ge 1 ]] || { echo "Usage: $(basename "$0") <group_id>" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
group_id="$1"
base_dir="${STORAGE_ROOT}/groups/group_${group_id}/files"
exec "${SCRIPT_DIR}/../files/file_list.sh" "$base_dir" "."
