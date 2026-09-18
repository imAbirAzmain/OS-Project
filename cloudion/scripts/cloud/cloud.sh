#!/usr/bin/env bash
# =============================================================================
# cloud.sh — dispatcher for the `cloud <subcommand>` command family.
#
# This is the single entry point an integrating terminal (e.g. AzTerm) should
# exec for every `cloud ...` command it parses:
#
#     cloud start    ->  ./scripts/cloud/cloud.sh start
#     cloud stop     ->  ./scripts/cloud/cloud.sh stop
#     cloud restart  ->  ./scripts/cloud/cloud.sh restart
#     cloud status   ->  ./scripts/cloud/cloud.sh status
#     cloud logs     ->  ./scripts/cloud/cloud.sh logs [lines] [category]
#     cloud info     ->  ./scripts/cloud/cloud.sh info
#     cloud help     ->  ./scripts/cloud/cloud.sh help
#
# It does no work itself — it only routes to the focused script that
# actually implements each subcommand, so each one stays independently
# testable and runnable on its own (see the other scripts in this folder).
#
# Usage: cloud.sh <start|stop|restart|status|logs|info|help> [args...]
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

subcommand="${1:-help}"
shift || true

case "$subcommand" in
    start)   exec "${SCRIPT_DIR}/cloud_start.sh" "$@" ;;
    stop)    exec "${SCRIPT_DIR}/cloud_stop.sh" "$@" ;;
    restart) exec "${SCRIPT_DIR}/cloud_restart.sh" "$@" ;;
    status)  exec "${SCRIPT_DIR}/cloud_status.sh" "$@" ;;
    storage) exec "${SCRIPT_DIR}/cloud_storage.sh" "$@" ;;
    logs)    exec "${SCRIPT_DIR}/cloud_logs.sh" "$@" ;;
    info)    exec "${SCRIPT_DIR}/cloud_info.sh" "$@" ;;
    help)    exec "${SCRIPT_DIR}/cloud_help.sh" "$@" ;;
    *)
        die "$EXIT_INVALID_ARGUMENT" "Unknown cloud subcommand: $subcommand (try: start|stop|restart|status|storage|logs|info|help)"
        ;;
esac
