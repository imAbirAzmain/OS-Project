#!/usr/bin/env bash
# =============================================================================
# log_operation.sh — writes a structured line to the appropriate log file.
#
# Usage:
#   log_operation.sh <category> <event> <actor> <detail>
#
#   category  one of: auth file group chat backup server error  (maps to
#             logs/<category>.log; unknown categories fall back to server.log)
#   event     short event name, e.g. FILE_UPLOAD, USER_LOGIN
#   actor     username or "system"
#   detail    free-text detail (should not contain newlines)
#
# Every event is also appended to logs/server.log so there is one combined
# timeline in addition to the per-category logs.
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

if [[ $# -lt 4 ]]; then
    echo "Usage: $(basename "$0") <category> <event> <actor> <detail>" >&2
    exit "$EXIT_INVALID_ARGUMENT"
fi

category="$1"
event="$2"
actor="$3"
shift 3
detail="$*"

ensure_dir "$LOGS_ROOT" 0750

case "$category" in
    auth|file|group|chat|backup|server|error) ;;
    *) category="server" ;;
esac

timestamp="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
detail="${detail//$'\n'/ }"

line="${timestamp} | ${event} | actor=${actor} | ${detail}"

printf '%s\n' "$line" >> "${LOGS_ROOT}/${category}.log"
printf '%s | category=%s | %s\n' "$timestamp" "$category" "$line" >> "${LOGS_ROOT}/server.log"

emit STATUS SUCCESS
exit "$EXIT_SUCCESS"
