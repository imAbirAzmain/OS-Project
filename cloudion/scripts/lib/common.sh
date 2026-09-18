#!/usr/bin/env bash
# =============================================================================
# common.sh — shared helpers sourced by every script in this project.
#
# Centralizing this logic means every script gets the same exit-code
# contract, the same logging format, and the same path-traversal defense
# without re-implementing it (and possibly getting it wrong) each time.
# =============================================================================

# ---- Standard exit codes (documented in README.md, section "Exit Codes") --
export EXIT_SUCCESS=0
export EXIT_GENERAL_ERROR=1
export EXIT_INVALID_ARGUMENT=2
export EXIT_FILE_NOT_FOUND=3
export EXIT_PERMISSION_DENIED=4
export EXIT_STORAGE_ERROR=5
export EXIT_INVALID_PATH=6
export EXIT_AUTHORIZATION_FAILURE=7

# Resolve project root regardless of where a script is invoked from.
# scripts/<category>/<script>.sh -> project root is two levels up.
COMMON_SH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_ROOT="$(cd "${COMMON_SH_DIR}/../.." && pwd)"
export STORAGE_ROOT="${PROJECT_ROOT}/storage"
export LOGS_ROOT="${PROJECT_ROOT}/logs"
export BACKUPS_ROOT="${PROJECT_ROOT}/backups"

# ---- Portable realpath replacement ----------------------------------------
# macOS ships BSD realpath which does not support -m (allow non-existent paths).
# This function normalises a path without requiring GNU coreutils on either OS.
_portable_realpath() {
    local base="$1"
    local rel="$2"
    # Combine into one path and let python3 (present on every macOS and most
    # Linux distros) normalise it without touching the filesystem.
    python3 -c "
import os, sys
base = sys.argv[1]
rel  = sys.argv[2]
combined = os.path.join(base, rel) if not os.path.isabs(rel) else rel
print(os.path.normpath(combined))
" "$base" "$rel"
}

# ---- Cross-platform file/directory stat helpers --------------------------
# Works transparently on both macOS (BSD stat/du) and Linux (GNU stat/du).
file_stat_size() {
    local file="$1"
    if [[ "$(uname -s)" == "Darwin" ]]; then
        stat -f %z "$file"
    else
        stat -c %s "$file"
    fi
}

file_stat_modified() {
    local file="$1"
    if [[ "$(uname -s)" == "Darwin" ]]; then
        stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$file"
    else
        stat -c '%y' -- "$file" | cut -d'.' -f1
    fi
}

file_stat_mtime_epoch() {
    local file="$1"
    if [[ "$(uname -s)" == "Darwin" ]]; then
        stat -f %m "$file"
    else
        stat -c %Y -- "$file"
    fi
}

file_stat_created() {
    local file="$1"
    if [[ "$(uname -s)" == "Darwin" ]]; then
        stat -f "%SB" -t "%Y-%m-%d %H:%M:%S" "$file" 2>/dev/null || echo "unavailable"
    else
        stat -c '%w' -- "$file" 2>/dev/null || echo "unavailable"
    fi
}

file_stat_perms() {
    local file="$1"
    if [[ "$(uname -s)" == "Darwin" ]]; then
        stat -f %Sp "$file"
    else
        stat -c '%A' -- "$file"
    fi
}

file_stat_owner() {
    local file="$1"
    if [[ "$(uname -s)" == "Darwin" ]]; then
        stat -f %Su "$file"
    else
        stat -c '%U' -- "$file"
    fi
}

dir_size_bytes() {
    local dir="$1"
    if [[ "$(uname -s)" == "Darwin" ]]; then
        local kb
        kb="$(du -sk -- "$dir" 2>/dev/null | awk '{print $1}')"
        echo $(( ${kb:-0} * 1024 ))
    else
        local sb
        sb="$(du -sb -- "$dir" 2>/dev/null | awk '{print $1}')"
        echo "${sb:-0}"
    fi
}

# ---- Machine-readable output -------------------------------------------
# Emits KEY=VALUE lines the backend can parse without regex gymnastics.
# Usage: emit STATUS SUCCESS ; emit FILE_NAME "$name"
emit() {
    local key="$1"; shift
    local value="$*"
    printf '%s=%s\n' "$key" "$value"
}

die() {
    # die <exit_code> <message>
    local code="$1"; shift
    emit STATUS FAILURE
    emit CODE "$code"
    emit MESSAGE "$*"
    echo "ERROR: $*" >&2
    exit "$code"
}

require_arg() {
    # require_arg "<name>" "<value>"
    if [[ -z "${2:-}" ]]; then
        die "$EXIT_INVALID_ARGUMENT" "Missing required argument: $1"
    fi
}

# ---- Path safety ---------------------------------------------------------
# Ensures that a candidate path, once resolved, is still inside a given
# base directory. This is the core defense against path traversal
# (../../etc/passwd style attacks) and against absolute-path escapes.
#
# Usage: safe_path=$(resolve_within_base "$BASE_DIR" "$USER_SUPPLIED_RELATIVE_PATH")
resolve_within_base() {
    local base="$1"
    local candidate="$2"

    if [[ -z "$base" || -z "$candidate" ]]; then
        die "$EXIT_INVALID_PATH" "Empty path supplied to resolve_within_base"
    fi

    # Reject obviously dangerous fragments outright before touching the
    # filesystem at all (defense in depth; the realpath check below is the
    # authoritative check but cheap string rejection avoids surprises with
    # symlinks/special files).
    if [[ "$candidate" == *".."* ]]; then
        die "$EXIT_INVALID_PATH" "Path traversal sequence rejected: $candidate"
    fi
    if [[ "$candidate" == /* ]]; then
        die "$EXIT_INVALID_PATH" "Absolute paths are not allowed: $candidate"
    fi

    local base_real
    base_real="$(_portable_realpath "$base" ".")"
    local full_real
    full_real="$(_portable_realpath "$base" "$candidate")"

    case "$full_real" in
        "$base_real"|"$base_real"/*)
            printf '%s\n' "$full_real"
            ;;
        *)
            die "$EXIT_INVALID_PATH" "Resolved path escapes base directory: $candidate"
            ;;
    esac
}

# Validate a filename component (no slashes, no null bytes, no leading dash
# which could be misread as a command flag by downstream tools).
validate_filename() {
    local name="$1"
    if [[ -z "$name" ]]; then
        die "$EXIT_INVALID_ARGUMENT" "Filename cannot be empty"
    fi
    if [[ "$name" == */* ]]; then
        die "$EXIT_INVALID_PATH" "Filename must not contain path separators: $name"
    fi
    if [[ "$name" == -* ]]; then
        die "$EXIT_INVALID_ARGUMENT" "Filename must not start with a dash: $name"
    fi
    # Note: a literal null byte cannot actually appear in a Bash string
    # (argv is C-string based, so it would already be truncated by the
    # kernel/exec before Bash ever sees it) — the meaningful check here is
    # restricting to printable, unambiguous characters instead.
    if [[ "$name" =~ [[:cntrl:]] ]]; then
        die "$EXIT_INVALID_ARGUMENT" "Filename contains control characters: $name"
    fi
}

ensure_dir() {
    # ensure_dir <path> <mode>
    local dir="$1"
    local mode="${2:-0750}"
    if ! mkdir -p -m "$mode" "$dir" 2>/dev/null; then
        die "$EXIT_STORAGE_ERROR" "Failed to create directory: $dir"
    fi
}

# ---- Logging --------------------------------------------------------------
# Delegates to log_operation.sh so there is exactly one place that decides
# log file layout/rotation policy.
log_event() {
    # log_event <category> <event> <actor> <detail>
    local category="$1" event="$2" actor="$3" detail="$4"
    "${PROJECT_ROOT}/scripts/logging/log_operation.sh" "$category" "$event" "$actor" "$detail" || true
}
