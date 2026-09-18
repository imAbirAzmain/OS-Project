#!/usr/bin/env bash
# cleanup_temp.sh — removes stale files from storage/temporary older than N hours.
# Usage: cleanup_temp.sh [max_age_hours]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

max_age_hours="${1:-24}"
if [[ ! "$max_age_hours" =~ ^[0-9]+$ ]]; then
    die "$EXIT_INVALID_ARGUMENT" "max_age_hours must be a positive integer"
fi

temp_dir="${STORAGE_ROOT}/temporary"
ensure_dir "$temp_dir" 0750

stale=()
while IFS= read -r f; do
    [[ -n "$f" ]] && stale+=("$f")
done < <(find "$temp_dir" -type f -mmin "+$(( max_age_hours * 60 ))" 2>/dev/null)
removed=0
if (( ${#stale[@]} > 0 )); then
    for f in "${stale[@]}"; do
        rm -f -- "$f" && removed=$((removed + 1))
    done
fi

log_event "server" "CLEANUP_TEMP" "system" "removed=${removed} max_age_hours=${max_age_hours}"

emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
emit REMOVED_COUNT "$removed"
exit "$EXIT_SUCCESS"
