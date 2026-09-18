#!/usr/bin/env bash
# =============================================================================
# cloud_restart.sh — stops then starts the Cloudion backend server.
#
# Usage: cloud_restart.sh
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Stopping is allowed to "fail" here (e.g. it wasn't running yet) — a
# restart should still proceed to start the server either way.
"${SCRIPT_DIR}/cloud_stop.sh" > /dev/null 2>&1 || true
sleep 1

if ! "${SCRIPT_DIR}/cloud_start.sh"; then
    die "$EXIT_GENERAL_ERROR" "Cloudion failed to restart"
fi

log_event server CLOUD_RESTART system "restarted"
exit "$EXIT_SUCCESS"
