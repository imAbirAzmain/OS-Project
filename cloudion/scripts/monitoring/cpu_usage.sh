#!/usr/bin/env bash
# =============================================================================
# cpu_usage.sh — reports current CPU utilization.
#
# On Linux: reads /proc/stat twice with a short interval and computes
# utilization from the delta (same method as `top`).
# On macOS: uses `top -l 2` which samples twice and gives a reliable reading.
#
# Usage: cpu_usage.sh
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

usage_pct=0
cores=1

os_type="$(uname -s)"

if [[ "$os_type" == "Darwin" ]]; then
    # -----------------------------------------------------------------------
    # macOS: use `top -l 2 -n 0` (2 samples, 0 processes listed).
    # The second sample reflects real CPU activity (first is always 0).
    # We extract the "CPU usage: X.X% user, Y.Y% sys, Z.Z% idle" line.
    # -----------------------------------------------------------------------
    cpu_line="$(top -l 2 -n 0 2>/dev/null | grep -E '^CPU usage' | tail -n 1 || true)"
    if [[ -n "$cpu_line" ]]; then
        idle_pct="$(echo "$cpu_line" | grep -oE '[0-9]+\.[0-9]+% idle' | grep -oE '[0-9]+' | head -1 || echo '0')"
        usage_pct=$(( 100 - idle_pct ))
        if (( usage_pct < 0 )); then usage_pct=0; fi
        if (( usage_pct > 100 )); then usage_pct=100; fi
    fi
    cores="$(sysctl -n hw.logicalcpu 2>/dev/null || echo 1)"
else
    # -----------------------------------------------------------------------
    # Linux: read /proc/stat twice with a 0.3-second interval.
    # -----------------------------------------------------------------------
    read_cpu() {
        read -r _ user nice system idle iowait irq softirq steal _ _ < <(grep '^cpu ' /proc/stat)
        echo "$user $nice $system $idle $iowait $irq $softirq $steal"
    }

    read -r u1 n1 s1 i1 w1 q1 sq1 st1 <<< "$(read_cpu)"
    sleep 0.3
    read -r u2 n2 s2 i2 w2 q2 sq2 st2 <<< "$(read_cpu)"

    idle1=$(( i1 + w1 ))
    idle2=$(( i2 + w2 ))
    total1=$(( u1 + n1 + s1 + i1 + w1 + q1 + sq1 + st1 ))
    total2=$(( u2 + n2 + s2 + i2 + w2 + q2 + sq2 + st2 ))

    total_delta=$(( total2 - total1 ))
    idle_delta=$(( idle2 - idle1 ))

    if (( total_delta > 0 )); then
        usage_pct=$(( (100 * (total_delta - idle_delta)) / total_delta ))
    fi

    cores="$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo)"
fi

emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
emit CPU_USAGE_PERCENT "$usage_pct"
emit CPU_CORES "$cores"
exit "$EXIT_SUCCESS"
