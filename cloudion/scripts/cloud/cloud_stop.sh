#!/usr/bin/env bash
# =============================================================================
# cloud_stop.sh — stops the running Cloudion backend server.
#
# Usage: cloud_stop.sh
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

PID_FILE="${PROJECT_ROOT}/.cloudion.pid"

if [[ ! -f "$PID_FILE" ]]; then
    die "$EXIT_GENERAL_ERROR" "Cloudion is not running (no PID file found)"
fi

pid="$(cat "$PID_FILE")"

if ! kill -0 "$pid" 2>/dev/null; then
    rm -f "$PID_FILE"
    die "$EXIT_GENERAL_ERROR" "Cloudion is not running (stale PID file removed)"
fi

kill "$pid" 2>/dev/null || true

# Give it a moment to shut down gracefully before force-killing.
for _ in 1 2 3 4 5; do
    kill -0 "$pid" 2>/dev/null || break
    sleep 0.5
done
if kill -0 "$pid" 2>/dev/null; then
    kill -9 "$pid" 2>/dev/null || true
fi

rm -f "$PID_FILE"
log_event server CLOUD_STOP system "pid=${pid}"

emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
emit MESSAGE "Cloudion stopped"
exit "$EXIT_SUCCESS"
