#!/usr/bin/env bash
# =============================================================================
# memory_usage.sh — reports memory usage.
#
# On Linux: uses `free -b` (GNU coreutils).
# On macOS: uses `sysctl hw.memsize` for total and `vm_stat` for page counts.
#
# Usage: memory_usage.sh
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

total=0
used=0
free_bytes=0
available=0
usage_pct=0

os_type="$(uname -s)"

if [[ "$os_type" == "Darwin" ]]; then
    # -----------------------------------------------------------------------
    # macOS: `free` is not available.
    # - Total RAM via sysctl hw.memsize (bytes).
    # - Page sizes and counts via vm_stat; each page is 4096 bytes on Intel.
    # -----------------------------------------------------------------------
    total="$(sysctl -n hw.memsize 2>/dev/null || echo 0)"

    page_size="$(vm_stat 2>/dev/null | awk '/page size of/ {print $8}' || echo 4096)"
    [[ "$page_size" =~ ^[0-9]+$ ]] || page_size=4096

    # Pages wired + active + occupied by compressor = "used"
    pages_wired="$(    vm_stat 2>/dev/null | awk '/Pages wired down/         {gsub(/\./,"",$NF); print $NF}' || echo 0)"
    pages_active="$(   vm_stat 2>/dev/null | awk '/Pages active:/            {gsub(/\./,"",$NF); print $NF}' || echo 0)"
    pages_compressed="$(vm_stat 2>/dev/null | awk '/Pages occupied by compressor/ {gsub(/\./,"",$NF); print $NF}' || echo 0)"
    pages_free="$(     vm_stat 2>/dev/null | awk '/Pages free:/              {gsub(/\./,"",$NF); print $NF}' || echo 0)"
    pages_speculative="$(vm_stat 2>/dev/null | awk '/Pages speculative:/     {gsub(/\./,"",$NF); print $NF}' || echo 0)"

    # Sanitize — default to 0 if non-numeric
    for var in pages_wired pages_active pages_compressed pages_free pages_speculative; do
        [[ "${!var}" =~ ^[0-9]+$ ]] || printf -v "$var" '0'
    done

    used=$(( (pages_wired + pages_active + pages_compressed) * page_size ))
    free_bytes=$(( pages_free * page_size ))
    available=$(( (pages_free + pages_speculative) * page_size ))

    if (( total > 0 )); then
        usage_pct=$(( (used * 100) / total ))
    fi
else
    # -----------------------------------------------------------------------
    # Linux: standard `free -b` approach.
    # -----------------------------------------------------------------------
    read -r _ total used free_ shared buffcache available < <(free -b | awk '/^Mem:/ {print}')

    free_bytes="$free_"
    usage_pct=0
    if (( total > 0 )); then
        usage_pct=$(( (used * 100) / total ))
    fi
fi

emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
emit MEMORY_TOTAL_BYTES     "$total"
emit MEMORY_USED_BYTES      "$used"
emit MEMORY_FREE_BYTES      "$free_bytes"
emit MEMORY_AVAILABLE_BYTES "$available"
emit MEMORY_USAGE_PERCENT   "$usage_pct"
exit "$EXIT_SUCCESS"
