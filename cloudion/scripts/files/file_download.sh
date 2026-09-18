#!/usr/bin/env bash
# =============================================================================
# file_download.sh — resolves and validates a download request.
#
# This script does NOT stream bytes to the client — the backend does that
# with a normal file stream. Bash's job is the security/correctness part:
# confirm the path is legitimate, inside the caller's authorized area, that
# it exists, and return its real filesystem path plus metadata.
#
# Usage:
#   file_download.sh <base_dir> <relative_path> <actor> <log_category>
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

require_arg "base_dir" "$base_dir"
require_arg "relative_path" "$relative_path"

resolved="$(resolve_within_base "$base_dir" "$relative_path")"

if [[ ! -f "$resolved" ]]; then
    die "$EXIT_FILE_NOT_FOUND" "File not found: $relative_path"
fi
if [[ ! -r "$resolved" ]]; then
    die "$EXIT_PERMISSION_DENIED" "File is not readable: $relative_path"
fi

file_size="$(file_stat_size "$resolved")"
file_type="$(file -b --mime-type -- "$resolved" 2>/dev/null || echo "application/octet-stream")"

log_event "$log_category" "FILE_DOWNLOAD" "$actor" "path=${resolved}"

emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
emit FILE_NAME "$(basename -- "$resolved")"
emit FILE_SIZE "$file_size"
emit FILE_TYPE "$file_type"
emit PATH "$resolved"

exit "$EXIT_SUCCESS"
