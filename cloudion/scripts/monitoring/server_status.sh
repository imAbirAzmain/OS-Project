#!/usr/bin/env bash
# =============================================================================
# server_status.sh — aggregate dashboard snapshot.
#
# Rather than duplicate logic, this composes the other monitoring scripts
# and merges their KEY=VALUE output into one report — a good example of
# Bash scripts calling other Bash scripts to build a higher-level view.
# Usage: server_status.sh
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
emit SERVER_STATE "ONLINE"
emit TIMESTAMP "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

# Merge sub-report output, skipping their own STATUS/CODE lines to avoid
# clobbering the aggregate ones set above.
for sub in cpu_usage.sh memory_usage.sh disk_usage.sh process_status.sh network_status.sh; do
    "${SCRIPT_DIR}/${sub}" | grep -v -E '^(STATUS|CODE)='
done

exit "$EXIT_SUCCESS"
