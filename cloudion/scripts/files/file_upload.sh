#!/usr/bin/env bash
# =============================================================================
# file_upload.sh — reusable upload engine.
#
# The backend never writes files itself. It saves the incoming multipart
# upload to a temp path, then hands off to this script to do the actual
# Linux filesystem work: validate, check space, create dirs, move, chmod,
# stat, log.
#
# Usage:
#   file_upload.sh <base_dir> <source_tmp_file> <dest_subdir> <dest_filename> <actor> <log_category>
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

if [[ $# -lt 6 ]]; then
    echo "Usage: $(basename "$0") <base_dir> <source_tmp_file> <dest_subdir> <dest_filename> <actor> <log_category>" >&2
    exit "$EXIT_INVALID_ARGUMENT"
fi

base_dir="$1"
source_tmp_file="$2"
dest_subdir="$3"
dest_filename="$4"
actor="$5"
log_category="$6"

require_arg "base_dir" "$base_dir"
require_arg "source_tmp_file" "$source_tmp_file"
validate_filename "$dest_filename"

MAX_UPLOAD_BYTES=$((500 * 1024 * 1024)) # 500 MB

if [[ ! -f "$source_tmp_file" ]]; then
    die "$EXIT_FILE_NOT_FOUND" "Source temp file not found: $source_tmp_file"
fi

file_size="$(file_stat_size "$source_tmp_file")"
if (( file_size > MAX_UPLOAD_BYTES )); then
    die "$EXIT_STORAGE_ERROR" "File exceeds maximum allowed size of ${MAX_UPLOAD_BYTES} bytes"
fi

if [[ ! -d "$base_dir" ]]; then
    die "$EXIT_INVALID_PATH" "Base directory does not exist: $base_dir"
fi

dest_dir_resolved="$(resolve_within_base "$base_dir" "$dest_subdir")"
ensure_dir "$dest_dir_resolved" 0750

dest_path="${dest_dir_resolved}/${dest_filename}"

avail_kb="$(df -P "$base_dir" | awk 'NR==2 {print $4}')"
avail_bytes=$(( avail_kb * 1024 ))
if (( file_size > avail_bytes )); then
    die "$EXIT_STORAGE_ERROR" "Insufficient disk space to store upload"
fi

if ! mv -f -- "$source_tmp_file" "$dest_path"; then
    die "$EXIT_STORAGE_ERROR" "Failed to move file into storage: $dest_path"
fi

chmod 0640 "$dest_path" || true

file_type="$(file -b --mime-type -- "$dest_path" 2>/dev/null || echo "unknown")"
modified="$(file_stat_modified "$dest_path")"

log_event "$log_category" "FILE_UPLOAD" "$actor" "path=${dest_path} size=${file_size}"

emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
emit MESSAGE "File uploaded successfully"
emit FILE_NAME "$dest_filename"
emit FILE_SIZE "$file_size"
emit FILE_TYPE "$file_type"
emit MODIFIED "$modified"
emit PATH "$dest_path"
emit RELATIVE_PATH "${dest_subdir%/}/${dest_filename}"

exit "$EXIT_SUCCESS"
