#!/usr/bin/env bash
# =============================================================================
# storage_usage.sh — reports disk usage for the whole storage tree and for
# each major area (users/one_to_one/groups/global), using df and du.
# Usage: storage_usage.sh
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

ensure_dir "$STORAGE_ROOT" 0755

# df -P for POSIX-stable column layout: filesystem, 1K-blocks, used, avail, use%, mount
read -r _ total_kb used_kb avail_kb _ _ < <(df -P "$STORAGE_ROOT" | awk 'NR==2 {print}')

total_bytes=$(( total_kb * 1024 ))
used_bytes=$(( used_kb * 1024 ))
avail_bytes=$(( avail_kb * 1024 ))

emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
emit FILESYSTEM_TOTAL_BYTES "$total_bytes"
emit FILESYSTEM_USED_BYTES "$used_bytes"
emit FILESYSTEM_AVAILABLE_BYTES "$avail_bytes"

for area in users one_to_one groups global temporary; do
    dir="${STORAGE_ROOT}/${area}"
    if [[ -d "$dir" ]]; then
        size_bytes="$(dir_size_bytes "$dir")"
    else
        size_bytes=0
    fi
    key_area=$(echo "$area" | tr '[:lower:]' '[:upper:]')
    emit "AREA_${key_area}_BYTES" "$size_bytes"
done

exit "$EXIT_SUCCESS"
