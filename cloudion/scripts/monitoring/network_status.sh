#!/usr/bin/env bash
# =============================================================================
# network_status.sh — reports basic network interface and listening-socket
# information.
#
# On Linux: uses `ip` and `ss` (iproute2).
# On macOS: uses `ifconfig` and `netstat -an` (available on all macOS versions).
#
# Usage: network_status.sh
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

interface_count=0
listening_count=0

os_type="$(uname -s)"

if [[ "$os_type" == "Darwin" ]]; then
    # -----------------------------------------------------------------------
    # macOS: ifconfig lists all interfaces; filter out loopback for parity
    # with Linux's `ip link show`.
    # netstat -an | grep LISTEN counts listening TCP sockets.
    # -----------------------------------------------------------------------
    if command -v ifconfig >/dev/null 2>&1; then
        # Count lines starting with an interface name (e.g. "en0:", "lo0:")
        interface_count="$(ifconfig 2>/dev/null | grep -cE '^[a-z]' || echo 0)"
    fi

    if command -v netstat >/dev/null 2>&1; then
        listening_count="$(netstat -an 2>/dev/null | grep -cE 'LISTEN' || echo 0)"
    fi
else
    # -----------------------------------------------------------------------
    # Linux: use iproute2 tools.
    # -----------------------------------------------------------------------
    if command -v ip >/dev/null 2>&1; then
        interface_count="$(ip -o link show 2>/dev/null | wc -l)"
    fi

    if command -v ss >/dev/null 2>&1; then
        listening_count="$(ss -ltn 2>/dev/null | tail -n +2 | wc -l)"
    fi
fi

emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
emit INTERFACE_COUNT        "$interface_count"
emit LISTENING_SOCKET_COUNT "$listening_count"
exit "$EXIT_SUCCESS"
