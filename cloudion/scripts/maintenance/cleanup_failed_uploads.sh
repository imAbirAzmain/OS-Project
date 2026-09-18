#!/usr/bin/env bash
# =============================================================================
# cleanup_failed_uploads.sh — removes orphaned partial upload temp files.
#
# If the backend crashes mid-upload, a temp file can be left behind in the
# upload staging directory without ever being moved into storage/ by
# file_upload.sh. This script sweeps that staging directory for files older
# than a threshold and removes them.
#
# Usage: cleanup_failed_uploads.sh [max_age_minutes]
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

max_age_minutes="${1:-60}"
if [[ ! "$max_age_minutes" =~ ^[0-9]+$ ]]; then
    die "$EXIT_INVALID_ARGUMENT" "max_age_minutes must be a positive integer"
fi

staging_dir="${STORAGE_ROOT}/temporary/uploads"
ensure_dir "$staging_dir" 0750

stale=()
while IFS= read -r f; do
    [[ -n "$f" ]] && stale+=("$f")
done < <(find "$staging_dir" -type f -mmin "+${max_age_minutes}" 2>/dev/null)
removed=0
if (( ${#stale[@]} > 0 )); then
    for f in "${stale[@]}"; do
        rm -f -- "$f" && removed=$((removed + 1))
    done
fi

log_event "server" "CLEANUP_FAILED_UPLOADS" "system" "removed=${removed}"

emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
emit REMOVED_COUNT "$removed"
exit "$EXIT_SUCCESS"
