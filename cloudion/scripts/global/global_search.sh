#!/usr/bin/env bash
# global_search.sh — searches the Global Cloud.
# Usage: global_search.sh <search_term> [extension]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
[[ $# -ge 1 ]] || { echo "Usage: $(basename "$0") <search_term> [extension]" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
search_term="$1"; extension="${2:-}"
base_dir="${STORAGE_ROOT}/global"
exec "${SCRIPT_DIR}/../files/file_search.sh" "$base_dir" "$search_term" "$extension"
