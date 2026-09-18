#!/usr/bin/env bash
# =============================================================================
# file_delete.sh — deletes a single file within an authorized base directory.
#
# Authorization is the backend's job (confirm ownership/membership BEFORE
# invoking this script). This script's job is the mechanical,
# security-sensitive part: ensure the resolved path cannot escape base_dir,
# and only ever remove a single regular file, never a directory or symlink.
#
# Usage:
#   file_delete.sh <base_dir> <relative_path> <actor> <log_category>
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

if [[ $# -lt 4 ]]; then
    echo "Usage: $(basename "$0") <base_dir> <relative_path> <actor> <log_category>" >&2
    exit "$EXIT_INVALID_ARGUMENT"
fi

base_dir="$1"
relative_path="$2"
actor="$3"
log_category="$4"

resolved="$(resolve_within_base "$base_dir" "$relative_path")"

if [[ -L "$resolved" ]]; then
    die "$EXIT_PERMISSION_DENIED" "Refusing to operate on a symlink: $relative_path"
fi
if [[ ! -e "$resolved" ]]; then
    die "$EXIT_FILE_NOT_FOUND" "File not found: $relative_path"
fi
if [[ ! -f "$resolved" ]]; then
    die "$EXIT_INVALID_ARGUMENT" "Target is not a regular file: $relative_path"
fi

file_size="$(file_stat_size "$resolved")"

if ! rm -f -- "$resolved"; then
    die "$EXIT_STORAGE_ERROR" "Failed to delete file: $relative_path"
fi

log_event "$log_category" "FILE_DELETE" "$actor" "path=${resolved} size=${file_size}"

emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
emit MESSAGE "File deleted successfully"
emit FILE_NAME "$(basename -- "$relative_path")"

exit "$EXIT_SUCCESS"
