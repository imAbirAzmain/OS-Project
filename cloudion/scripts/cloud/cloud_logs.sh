#!/usr/bin/env bash
# =============================================================================
# cloud_logs.sh — shows the most recent Cloudion log lines.
#
# Usage: cloud_logs.sh [lines] [category]
#   lines      how many recent lines to show (default 30)
#   category   auth|file|group|chat|backup|server|error (default: server = combined timeline)
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

lines="${1:-30}"
category="${2:-server}"

if [[ ! "$lines" =~ ^[0-9]+$ ]]; then
    die "$EXIT_INVALID_ARGUMENT" "lines must be a positive integer"
fi
case "$category" in
    auth|file|group|chat|backup|server|error) ;;
    *) die "$EXIT_INVALID_ARGUMENT" "Unknown log category: $category" ;;
esac

log_file="${LOGS_ROOT}/${category}.log"
ensure_dir "$LOGS_ROOT" 0750

emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
emit CATEGORY "$category"

if [[ ! -f "$log_file" ]]; then
    emit COUNT 0
    exit "$EXIT_SUCCESS"
fi

# Use a while-loop instead of mapfile (mapfile requires bash 4+;
# macOS ships with bash 3.2 which does not have mapfile).
index=0
while IFS= read -r line; do
    emit "LINE_${index}" "$line"
    index=$(( index + 1 ))
done < <(tail -n "$lines" "$log_file")

emit COUNT "$index"

exit "$EXIT_SUCCESS"
