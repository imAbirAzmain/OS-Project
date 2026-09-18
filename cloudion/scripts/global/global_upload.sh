#!/usr/bin/env bash
# global_upload.sh — uploads a file into the Global Cloud (shared by all users).
# Usage: global_upload.sh <source_tmp_file> <dest_filename> <actor>
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
[[ $# -ge 3 ]] || { echo "Usage: $(basename "$0") <source_tmp_file> <dest_filename> <actor>" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
source_tmp_file="$1"; dest_filename="$2"; actor="$3"
base_dir="${STORAGE_ROOT}/global"
ensure_dir "$base_dir" 0755
exec "${SCRIPT_DIR}/../files/file_upload.sh" "$base_dir" "$source_tmp_file" "." "$dest_filename" "$actor" "file"
