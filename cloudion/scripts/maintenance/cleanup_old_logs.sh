#!/usr/bin/env bash
# cleanup_old_logs.sh — rotates log files: gzips and archives logs older than
# N days into logs/archive/, keeping the live logs small.
# Usage: cleanup_old_logs.sh [max_age_days]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

max_age_days="${1:-30}"
if [[ ! "$max_age_days" =~ ^[0-9]+$ ]]; then
    die "$EXIT_INVALID_ARGUMENT" "max_age_days must be a positive integer"
fi

ensure_dir "$LOGS_ROOT" 0750
archive_dir="${LOGS_ROOT}/archive"
ensure_dir "$archive_dir" 0750

archived=0
for logfile in "$LOGS_ROOT"/*.log; do
    [[ -f "$logfile" ]] || continue
    if [[ $(find "$logfile" -mtime "+${max_age_days}" 2>/dev/null) ]]; then
        timestamp="$(date -u +'%Y%m%dT%H%M%SZ')"
        base="$(basename "$logfile")"
        gzip -c "$logfile" > "${archive_dir}/${base}.${timestamp}.gz"
        : > "$logfile"
        archived=$((archived + 1))
    fi
done

log_event "server" "CLEANUP_LOGS" "system" "archived=${archived} max_age_days=${max_age_days}"

emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
emit ARCHIVED_COUNT "$archived"
exit "$EXIT_SUCCESS"
