#!/usr/bin/env bash
# =============================================================================
# global_delete.sh — deletes a file from the Global Cloud.
#
# Permission model: only the file's uploader OR an administrator may delete
# a global file. The backend enforces this (it knows uploader identity from
# file_metadata in the database) and only calls this script once that check
# has passed — this script performs the mechanical deletion, it does not
# re-derive ownership itself since Bash has no view of the app's user table.
#
# Usage: global_delete.sh <relative_path> <actor>
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
[[ $# -ge 2 ]] || { echo "Usage: $(basename "$0") <relative_path> <actor>" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
relative_path="$1"; actor="$2"
base_dir="${STORAGE_ROOT}/global"
exec "${SCRIPT_DIR}/../files/file_delete.sh" "$base_dir" "$relative_path" "$actor" "file"
