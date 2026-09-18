#!/usr/bin/env bash
# =============================================================================
# cloud_help.sh — prints the "cloud" command family reference.
#
# This mirrors the reference table format used elsewhere for the terminal's
# own top-level `help` command, but scoped to the `cloud` namespace only.
#
# Usage: cloud_help.sh
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

cat <<'TABLE'
╔══════════════════════╦════════════════════════════════════════════╦════════════════════════════════════════╗
║ Command              ║ Functionality                              ║ Syntax Example                         ║
╠══════════════════════╬════════════════════════════════════════════╬════════════════════════════════════════╣
║ cloud start          ║ Start Cloudion                             ║ cloud start                            ║
║ cloud stop           ║ Stop Cloudion                              ║ cloud stop                             ║
║ cloud restart        ║ Restart Cloudion                           ║ cloud restart                          ║
║ cloud status         ║ Show Cloudion status                       ║ cloud status                           ║
║ cloud storage        ║ Show storage usage & breakdown             ║ cloud storage                          ║
║ cloud logs           ║ Show recent Cloudion logs                  ║ cloud logs                             ║
║ cloud info           ║ Show Cloudion details                      ║ cloud info                             ║
║ cloud help           ║ Show this help                             ║ cloud help                             ║
╚══════════════════════╩════════════════════════════════════════════╩════════════════════════════════════════╝
TABLE

emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
exit "$EXIT_SUCCESS"
