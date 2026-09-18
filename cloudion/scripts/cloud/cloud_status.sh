#!/usr/bin/env bash
# =============================================================================
# cloud_status.sh — reports whether Cloudion is running, plus live system
# metrics from the monitoring scripts.
#
# Usage: cloud_status.sh
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

PID_FILE="${PROJECT_ROOT}/.cloudion.pid"

emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"

if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    emit CLOUDION_STATE "RUNNING"
    emit PID "$(cat "$PID_FILE")"
else
    emit CLOUDION_STATE "STOPPED"
fi

# Merge in live CPU/memory/disk/process/network metrics, same aggregation
# pattern as monitoring/server_status.sh — skip its own STATUS/CODE lines
# so they don't clobber the ones already emitted above.
"${SCRIPT_DIR}/../monitoring/server_status.sh" | grep -v -E '^(STATUS|CODE|SERVER_STATE)='

exit "$EXIT_SUCCESS"
