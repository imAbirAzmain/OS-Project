#!/usr/bin/env bash
# global_file_info.sh — metadata for one file in the Global Cloud.
# Usage: global_file_info.sh <relative_path>
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
[[ $# -ge 1 ]] || { echo "Usage: $(basename "$0") <relative_path>" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
relative_path="$1"
base_dir="${STORAGE_ROOT}/global"
exec "${SCRIPT_DIR}/../files/file_info.sh" "$base_dir" "$relative_path"
