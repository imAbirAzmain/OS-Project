#!/usr/bin/env bash
# personal_upload.sh — uploads a file into a user's Personal Cloud.
# Thin wrapper: resolves the caller's personal storage root, then delegates
# to the shared file_upload.sh engine.
# Usage: personal_upload.sh <username> <source_tmp_file> <dest_filename>
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
[[ $# -ge 3 ]] || { echo "Usage: $(basename "$0") <username> <source_tmp_file> <dest_filename>" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
username="$1"; source_tmp_file="$2"; dest_filename="$3"
base_dir="${STORAGE_ROOT}/users/${username}/files"
ensure_dir "$base_dir" 0750
exec "${SCRIPT_DIR}/../files/file_upload.sh" "$base_dir" "$source_tmp_file" "." "$dest_filename" "$username" "file"
