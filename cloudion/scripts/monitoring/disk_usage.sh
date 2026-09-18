#!/usr/bin/env bash
# disk_usage.sh — reports disk usage of the filesystem hosting the project.
# Usage: disk_usage.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

read -r _ total_kb used_kb avail_kb use_pct _ < <(df -P "$PROJECT_ROOT" | awk 'NR==2 {print}')
use_pct="${use_pct%\%}"

emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
emit DISK_TOTAL_BYTES $(( total_kb * 1024 ))
emit DISK_USED_BYTES $(( used_kb * 1024 ))
emit DISK_AVAILABLE_BYTES $(( avail_kb * 1024 ))
emit DISK_USAGE_PERCENT "$use_pct"
exit "$EXIT_SUCCESS"
