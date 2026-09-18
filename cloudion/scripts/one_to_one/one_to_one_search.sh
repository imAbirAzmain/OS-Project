#!/usr/bin/env bash
# one_to_one_search.sh — searches within a 1:1 conversation's shared storage.
# Usage: one_to_one_search.sh <conversation_id> <search_term> [extension]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
[[ $# -ge 2 ]] || { echo "Usage: $(basename "$0") <conversation_id> <search_term> [extension]" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
conversation_id="$1"; search_term="$2"; extension="${3:-}"
base_dir="${STORAGE_ROOT}/one_to_one/conversation_${conversation_id}"
exec "${SCRIPT_DIR}/../files/file_search.sh" "$base_dir" "$search_term" "$extension"
