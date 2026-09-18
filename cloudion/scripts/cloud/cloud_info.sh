#!/usr/bin/env bash
# =============================================================================
# cloud_info.sh — static + light dynamic details about this Cloudion instance.
#
# Usage: cloud_info.sh
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

VERSION_FILE="${PROJECT_ROOT}/VERSION"
version="unknown"
[[ -f "$VERSION_FILE" ]] && version="$(tr -d '[:space:]' < "$VERSION_FILE")"

PID_FILE="${PROJECT_ROOT}/.cloudion.pid"
state="STOPPED"
pid=""
uptime_str=""

if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    state="RUNNING"
    pid="$(cat "$PID_FILE")"

    # Use `ps -o etime=` which works on both macOS and Linux (POSIX).
    # etime reports elapsed time in [[DD-]HH:]MM:SS format.
    uptime_str="$(ps -p "$pid" -o etime= 2>/dev/null | tr -d '[:space:]' || true)"
fi

script_count="$(find "${PROJECT_ROOT}/scripts" -name '*.sh' | wc -l | tr -d '[:space:]')"

emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
emit NAME "Cloudion"
emit VERSION "$version"
emit STATE "$state"
[[ -n "$pid" ]]        && emit PID "$pid"
[[ -n "$uptime_str" ]] && emit UPTIME "$uptime_str"
emit PROJECT_ROOT  "$PROJECT_ROOT"
emit STORAGE_ROOT  "$STORAGE_ROOT"
emit LOGS_ROOT     "$LOGS_ROOT"
emit BACKUPS_ROOT  "$BACKUPS_ROOT"
emit SCRIPT_COUNT  "$script_count"
emit CLOUD_AREAS   "personal,one_to_one,groups,global"

exit "$EXIT_SUCCESS"
