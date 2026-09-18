#!/usr/bin/env bash
# personal_search.sh — searches a user's Personal Cloud.
# Usage: personal_search.sh <username> <search_term> [extension]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
[[ $# -ge 2 ]] || { echo "Usage: $(basename "$0") <username> <search_term> [extension]" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
username="$1"; search_term="$2"; extension="${3:-}"
base_dir="${STORAGE_ROOT}/users/${username}/files"
exec "${SCRIPT_DIR}/../files/file_search.sh" "$base_dir" "$search_term" "$extension"
