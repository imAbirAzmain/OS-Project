#!/usr/bin/env bash
# storage_available.sh — quick check of free space (used by upload paths
# and dashboards that just need the headline number).
# Usage: storage_available.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
ensure_dir "$STORAGE_ROOT" 0755
avail_kb="$(df -P "$STORAGE_ROOT" | awk 'NR==2 {print $4}')"
avail_bytes=$(( avail_kb * 1024 ))
emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
emit AVAILABLE_BYTES "$avail_bytes"
exit "$EXIT_SUCCESS"
