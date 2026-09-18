#!/usr/bin/env bash
# one_to_one_upload.sh — uploads a file into a 1:1 conversation's shared storage.
# Usage: one_to_one_upload.sh <conversation_id> <source_tmp_file> <dest_filename> <actor>
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
[[ $# -ge 4 ]] || { echo "Usage: $(basename "$0") <conversation_id> <source_tmp_file> <dest_filename> <actor>" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
conversation_id="$1"; source_tmp_file="$2"; dest_filename="$3"; actor="$4"
base_dir="${STORAGE_ROOT}/one_to_one/conversation_${conversation_id}"
[[ -d "$base_dir" ]] || die "$EXIT_FILE_NOT_FOUND" "No storage for conversation: $conversation_id"
exec "${SCRIPT_DIR}/../files/file_upload.sh" "$base_dir" "$source_tmp_file" "." "$dest_filename" "$actor" "chat"
