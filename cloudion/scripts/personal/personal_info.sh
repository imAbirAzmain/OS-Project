#!/usr/bin/env bash
# personal_info.sh — returns metadata for one file in a user's Personal Cloud.
# Usage: personal_info.sh <username> <relative_path>
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
[[ $# -ge 2 ]] || { echo "Usage: $(basename "$0") <username> <relative_path>" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
username="$1"; relative_path="$2"
base_dir="${STORAGE_ROOT}/users/${username}/files"
exec "${SCRIPT_DIR}/../files/file_info.sh" "$base_dir" "$relative_path"
