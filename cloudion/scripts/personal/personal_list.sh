#!/usr/bin/env bash
# personal_list.sh — lists all files in a user's Personal Cloud.
# Usage: personal_list.sh <username>
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
[[ $# -ge 1 ]] || { echo "Usage: $(basename "$0") <username>" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
username="$1"
base_dir="${STORAGE_ROOT}/users/${username}/files"
ensure_dir "$base_dir" 0750
exec "${SCRIPT_DIR}/../files/file_list.sh" "$base_dir" "."
