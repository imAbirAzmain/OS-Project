#!/usr/bin/env bash
# =============================================================================
# cloud_storage.sh — reports storage metrics and per-user usage breakdown.
# Used by AzTerm and terminal administrators for host-only storage monitoring.
#
# Usage: cloud_storage.sh
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"

# Run storage usage and omit redundant STATUS/CODE lines
"${SCRIPT_DIR}/../storage/storage_usage.sh" | grep -v -E '^(STATUS|CODE)='

# Run storage report and omit redundant STATUS/CODE lines
"${SCRIPT_DIR}/../storage/storage_report.sh" | grep -v -E '^(STATUS|CODE)='

exit "$EXIT_SUCCESS"
