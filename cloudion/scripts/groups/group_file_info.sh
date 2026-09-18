#!/usr/bin/env bash
# group_file_info.sh — metadata for one file in a group's storage.
# Usage: group_file_info.sh <group_id> <relative_path>
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
[[ $# -ge 2 ]] || { echo "Usage: $(basename "$0") <group_id> <relative_path>" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
group_id="$1"; relative_path="$2"
base_dir="${STORAGE_ROOT}/groups/group_${group_id}/files"
exec "${SCRIPT_DIR}/../files/file_info.sh" "$base_dir" "$relative_path"
