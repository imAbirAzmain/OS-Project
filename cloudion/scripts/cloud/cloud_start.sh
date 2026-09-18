#!/usr/bin/env bash
# =============================================================================
# cloud_start.sh — starts the Cloudion backend server as a background process.
#
# This is the script an integrating terminal (e.g. AzTerm's `cloud start`)
# should exec. It is independently runnable from any shell too.
#
# Usage: cloud_start.sh
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

PID_FILE="${PROJECT_ROOT}/.cloudion.pid"
PROCESS_LOG="${LOGS_ROOT}/cloudion_process.log"

if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    die "$EXIT_GENERAL_ERROR" "Cloudion is already running (PID $(cat "$PID_FILE"))"
fi

if [[ ! -d "${PROJECT_ROOT}/backend/node_modules" ]]; then
    die "$EXIT_GENERAL_ERROR" "Backend dependencies not installed — run 'npm install' in backend/ first"
fi

ensure_dir "$LOGS_ROOT" 0750

# ---------------------------------------------------------------------------
# Start Node.js server in a detached background process.
#
# macOS does not ship `setsid` (GNU/Linux only), so we use a portable
# approach: nohup prevents SIGHUP from the parent shell; redirecting stdin
# to /dev/null and stdout/stderr to the log file detaches I/O completely;
# `& disown` removes it from the shell's job table so it survives terminal
# closure. We capture node's real PID via a wrapper script that writes $$ to
# the PID file before exec-ing node (exec replaces the process image without
# forking, so the PID bash wrote is exactly node's real PID).
# ---------------------------------------------------------------------------
nohup bash -c "cd '${PROJECT_ROOT}/backend' && echo \$\$ > '${PID_FILE}' && exec node server.js" \
    </dev/null >"${PROCESS_LOG}" 2>&1 &
disown 2>/dev/null || true

sleep 1

if ! kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null; then
    rm -f "$PID_FILE"
    die "$EXIT_GENERAL_ERROR" "Cloudion failed to start — see logs/cloudion_process.log"
fi

pid="$(cat "$PID_FILE")"
log_event server CLOUD_START system "pid=${pid}"

emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
emit MESSAGE "Cloudion started"
emit PID "$pid"
exit "$EXIT_SUCCESS"
