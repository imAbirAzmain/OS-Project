#!/usr/bin/env bash
# =============================================================================
# process_status.sh — reports process counts and system uptime.
#
# On Linux: reads /proc/uptime and /proc/loadavg.
# On macOS: uses `sysctl kern.boottime` for uptime and `sysctl vm.loadavg`
#           for load average; `ps -ax` for process count.
#
# Usage: process_status.sh
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

process_count=0
uptime_seconds=0
load_avg="0.00 0.00 0.00"

os_type="$(uname -s)"

if [[ "$os_type" == "Darwin" ]]; then
    # -----------------------------------------------------------------------
    # macOS: ps -ax lists all processes (equivalent to Linux `ps -e`).
    # -----------------------------------------------------------------------
    process_count="$(ps -ax 2>/dev/null | tail -n +2 | wc -l | tr -d '[:space:]')"

    # sysctl kern.boottime returns: { sec = NNNN, usec = MMMM } <date>
    # We parse the 'sec' field and subtract from current epoch time.
    boot_sec="$(sysctl -n kern.boottime 2>/dev/null | awk -F'[=,]' '{gsub(/ /,"",$2); print $2}' || echo 0)"
    now_sec="$(date +%s)"
    if [[ "$boot_sec" =~ ^[0-9]+$ ]] && (( boot_sec > 0 )); then
        uptime_seconds=$(( now_sec - boot_sec ))
    fi

    # sysctl vm.loadavg returns: { 0.XX 0.XX 0.XX }
    load_avg="$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2, $3, $4}' || echo "0.00 0.00 0.00")"
else
    # -----------------------------------------------------------------------
    # Linux: read /proc directly.
    # -----------------------------------------------------------------------
    process_count="$(ps -e --no-headers 2>/dev/null | wc -l | tr -d '[:space:]')"
    uptime_seconds="$(cut -d'.' -f1 /proc/uptime)"
    load_avg="$(cut -d' ' -f1-3 /proc/loadavg)"
fi

emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
emit PROCESS_COUNT    "$process_count"
emit UPTIME_SECONDS   "$uptime_seconds"
emit LOAD_AVERAGE     "$load_avg"
exit "$EXIT_SUCCESS"
