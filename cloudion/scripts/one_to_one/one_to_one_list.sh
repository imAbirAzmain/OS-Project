#!/usr/bin/env bash
# one_to_one_list.sh — lists files shared within a 1:1 conversation.
# Usage: one_to_one_list.sh <conversation_id>
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
[[ $# -ge 1 ]] || { echo "Usage: $(basename "$0") <conversation_id>" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
conversation_id="$1"
base_dir="${STORAGE_ROOT}/one_to_one/conversation_${conversation_id}"
exec "${SCRIPT_DIR}/../files/file_list.sh" "$base_dir" "."
