#!/usr/bin/env bash
# =============================================================================
# create_user_storage.sh — provisions Linux storage for a newly registered user.
# Called by the backend right after a user row is inserted into the database.
# Usage: create_user_storage.sh <username>
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

[[ $# -ge 1 ]] || { echo "Usage: $(basename "$0") <username>" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
username="$1"

if [[ ! "$username" =~ ^[a-zA-Z0-9_-]{3,32}$ ]]; then
    die "$EXIT_INVALID_ARGUMENT" "Invalid username format: $username"
fi

user_root="${STORAGE_ROOT}/users/${username}"
if [[ -d "$user_root" ]]; then
    die "$EXIT_GENERAL_ERROR" "Storage already exists for user: $username"
fi

ensure_dir "${user_root}/files" 0750
ensure_dir "${user_root}/trash" 0750

log_event "file" "USER_STORAGE_CREATE" "$username" "path=${user_root}"

emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
emit MESSAGE "User storage created"
emit USER_ROOT "$user_root"
exit "$EXIT_SUCCESS"
