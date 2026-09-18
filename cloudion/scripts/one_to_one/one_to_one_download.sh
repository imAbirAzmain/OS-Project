#!/usr/bin/env bash
# one_to_one_download.sh — resolves a download request within a 1:1 conversation.
# Usage: one_to_one_download.sh <conversation_id> <relative_path> <actor>
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
[[ $# -ge 3 ]] || { echo "Usage: $(basename "$0") <conversation_id> <relative_path> <actor>" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
conversation_id="$1"; relative_path="$2"; actor="$3"
base_dir="${STORAGE_ROOT}/one_to_one/conversation_${conversation_id}"
exec "${SCRIPT_DIR}/../files/file_download.sh" "$base_dir" "$relative_path" "$actor" "chat"
