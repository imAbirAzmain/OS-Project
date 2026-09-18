#!/usr/bin/env bash
# group_search.sh — searches within a group's shared storage.
# Usage: group_search.sh <group_id> <search_term> [extension]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
[[ $# -ge 2 ]] || { echo "Usage: $(basename "$0") <group_id> <search_term> [extension]" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
group_id="$1"; search_term="$2"; extension="${3:-}"
base_dir="${STORAGE_ROOT}/groups/group_${group_id}/files"
exec "${SCRIPT_DIR}/../files/file_search.sh" "$base_dir" "$search_term" "$extension"
