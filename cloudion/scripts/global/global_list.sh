#!/usr/bin/env bash
# global_list.sh — lists all files in the Global Cloud.
# Usage: global_list.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
base_dir="${STORAGE_ROOT}/global"
ensure_dir "$base_dir" 0755
exec "${SCRIPT_DIR}/../files/file_list.sh" "$base_dir" "."
