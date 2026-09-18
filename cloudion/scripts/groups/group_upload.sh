#!/usr/bin/env bash
# group_upload.sh — uploads a file into a group's shared storage.
# Usage: group_upload.sh <group_id> <source_tmp_file> <dest_filename> <actor>
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
[[ $# -ge 4 ]] || { echo "Usage: $(basename "$0") <group_id> <source_tmp_file> <dest_filename> <actor>" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
group_id="$1"; source_tmp_file="$2"; dest_filename="$3"; actor="$4"
base_dir="${STORAGE_ROOT}/groups/group_${group_id}/files"
[[ -d "$base_dir" ]] || die "$EXIT_FILE_NOT_FOUND" "No storage for group: $group_id"
exec "${SCRIPT_DIR}/../files/file_upload.sh" "$base_dir" "$source_tmp_file" "." "$dest_filename" "$actor" "group"
