#!/usr/bin/env bash
# one_to_one_file_info.sh — metadata for one file in a 1:1 conversation.
# Usage: one_to_one_file_info.sh <conversation_id> <relative_path>
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
[[ $# -ge 2 ]] || { echo "Usage: $(basename "$0") <conversation_id> <relative_path>" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
conversation_id="$1"; relative_path="$2"
base_dir="${STORAGE_ROOT}/one_to_one/conversation_${conversation_id}"
exec "${SCRIPT_DIR}/../files/file_info.sh" "$base_dir" "$relative_path"
