#!/usr/bin/env bash
# global_download.sh — resolves a download request from the Global Cloud.
# Usage: global_download.sh <relative_path> <actor>
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
[[ $# -ge 2 ]] || { echo "Usage: $(basename "$0") <relative_path> <actor>" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
relative_path="$1"; actor="$2"
base_dir="${STORAGE_ROOT}/global"
exec "${SCRIPT_DIR}/../files/file_download.sh" "$base_dir" "$relative_path" "$actor" "file"
