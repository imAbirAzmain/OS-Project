#!/usr/bin/env bash
# =============================================================================
# conversation_create.sh — creates the storage area for a 1:1 conversation.
#
# The conversation row itself (its id, the two participant usernames) lives
# in the database — that's relational data, not a filesystem concern. Once
# the backend has created that row and knows the conversation_id, it calls
# this script to provision the file-sharing directory for it.
#
# Usage: conversation_create.sh <conversation_id>
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

[[ $# -ge 1 ]] || { echo "Usage: $(basename "$0") <conversation_id>" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
conversation_id="$1"

if [[ ! "$conversation_id" =~ ^[0-9]+$ ]]; then
    die "$EXIT_INVALID_ARGUMENT" "conversation_id must be numeric: $conversation_id"
fi

conv_root="${STORAGE_ROOT}/one_to_one/conversation_${conversation_id}"
if [[ -d "$conv_root" ]]; then
    die "$EXIT_GENERAL_ERROR" "Storage already exists for conversation: $conversation_id"
fi

ensure_dir "$conv_root" 0750

log_event "chat" "CONVERSATION_CREATE" "system" "conversation_id=${conversation_id} path=${conv_root}"

emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
emit MESSAGE "Conversation storage created"
emit CONVERSATION_ROOT "$conv_root"
exit "$EXIT_SUCCESS"
