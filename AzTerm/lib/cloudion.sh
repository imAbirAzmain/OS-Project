#!/bin/bash

############################################################
# Cloudion management integration for AzTerm
#
# All `cloud` commands are delegated to Cloudion's own
# scripts/cloud/cloud.sh dispatcher, which handles
# start / stop / restart / status / logs / info / help.
#
# Output from Cloudion scripts is KEY=VALUE formatted.
# This module parses those lines and renders them in
# AzTerm's box-border style — keeping both UIs intact.
#
# NOTE: Written to be compatible with bash 3.2 (macOS system
# bash) — no associative arrays (declare -A), no namerefs
# (local -n), no mapfile / readarray.
############################################################

# ---------------------------------------------------------------------------
# Resolve the Cloudion project directory.
# Default: sibling of AzTerm's own directory (../cloudion).
# Override via: export CLOUDION_PATH=/path/to/cloudion
# ---------------------------------------------------------------------------
cloudion_project_dir()
{
    if [[ -n "${CLOUDION_PATH:-}" ]]; then
        echo "$CLOUDION_PATH"
    else
        echo "${SCRIPT_DIR%/*}/cloudion"
    fi
}

# ---------------------------------------------------------------------------
# Path to Cloudion's cloud.sh dispatcher.
# ---------------------------------------------------------------------------
cloudion_dispatcher()
{
    echo "$(cloudion_project_dir)/scripts/cloud/cloud.sh"
}

# ---------------------------------------------------------------------------
# Verify Cloudion project is present and runnable.
# Returns 0 if OK, 1 if not.
# ---------------------------------------------------------------------------
cloudion_check_available()
{
    local DISPATCHER
    DISPATCHER="$(cloudion_dispatcher)"

    if [[ ! -f "$DISPATCHER" ]]; then
        echo
        printf '%b' "${COLOR_RED}"
        echo "Error: Cloudion project not found."
        printf '%b' "${COLOR_RESET}"
        echo
        echo "Expected at: $(cloudion_project_dir)"
        echo "Make sure the cloudion folder is next to the AzTerm folder."
        echo
        return 1
    fi

    if [[ ! -x "$DISPATCHER" ]]; then
        # Auto-fix: make all cloud scripts executable
        local CDIR
        CDIR="$(cloudion_project_dir)"
        chmod +x "$DISPATCHER" 2>/dev/null || true
        find "$CDIR/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    fi

    return 0
}

# ---------------------------------------------------------------------------
# Run a Cloudion subcommand and store all KEY=VALUE pairs into env vars
# prefixed with _CK_ (Cloudion Key).  Clear them first.
#
# Usage:
#   cloudion_run_kv start
#   echo "$_CK_STATUS"   # SUCCESS or FAILURE
#   echo "$_CK_PID"
# ---------------------------------------------------------------------------
cloudion_run_kv()
{
    # Clear all previous _CK_ vars
    local _var
    for _var in STATUS CODE MESSAGE PID CLOUDION_STATE STATE NAME VERSION UPTIME \
                CPU_USAGE_PERCENT CPU_CORES \
                MEMORY_TOTAL_BYTES MEMORY_USED_BYTES MEMORY_FREE_BYTES \
                MEMORY_AVAILABLE_BYTES MEMORY_USAGE_PERCENT \
                DISK_TOTAL_BYTES DISK_USED_BYTES DISK_AVAILABLE_BYTES DISK_USAGE_PERCENT \
                PROCESS_COUNT UPTIME_SECONDS LOAD_AVERAGE TIMESTAMP \
                INTERFACE_COUNT LISTENING_SOCKET_COUNT \
                PROJECT_ROOT STORAGE_ROOT LOGS_ROOT BACKUPS_ROOT SCRIPT_COUNT CLOUD_AREAS \
                CATEGORY COUNT; do
        eval "_CK_${_var}=''"
    done
    _CK_RAW=""
    _CK_LINE_COUNT=0

    local DISPATCHER
    DISPATCHER="$(cloudion_dispatcher)"

    # Run the subcommand; capture output (allow non-zero exit gracefully)
    _CK_RAW="$("$DISPATCHER" "$@" 2>&1)" || true

    # Parse KEY=VALUE lines — bash 3.2 compatible loop
    local _line _key _val
    while IFS= read -r _line; do
        # Skip blank lines and comments
        case "$_line" in
            ''|\#*) continue ;;
        esac
        # Only process lines that contain '='
        case "$_line" in
            *=*)
                _key="${_line%%=*}"
                _val="${_line#*=}"
                # Skip keys with spaces (not valid KEY=VALUE)
                case "$_key" in
                    *\ *) continue ;;
                esac
                eval "_CK_${_key}=\"\$_val\""
                # Count log lines
                case "$_key" in
                    LINE_*) _CK_LINE_COUNT=$(( _CK_LINE_COUNT + 1 )) ;;
                esac
                ;;
        esac
    done <<< "$_CK_RAW"
}

# ---------------------------------------------------------------------------
# Print the standard AzTerm-style Cloudion box header.
# ---------------------------------------------------------------------------
cloudion_box_header()
{
    local TITLE="$1"
    printf '%b' "${COLOR_YELLOW}"
    printf '\n'
    printf '╔══════════════════════════════════════════╗\n'
    printf '║  %-40s║\n' "$TITLE"
    printf '╠══════════════════════════════════════════╣\n'
    printf '%b' "${COLOR_RESET}"
}

# ---------------------------------------------------------------------------
# Print the standard AzTerm-style Cloudion box footer.
# ---------------------------------------------------------------------------
cloudion_box_footer()
{
    printf '%b' "${COLOR_YELLOW}"
    printf '╚══════════════════════════════════════════╝\n'
    printf '%b' "${COLOR_RESET}"
    printf '\n'
}

# ---------------------------------------------------------------------------
# Print a labelled row inside the box.
# ---------------------------------------------------------------------------
cloudion_box_row()
{
    local LABEL="$1"
    local VALUE="$2"
    printf '%b' "${COLOR_WHITE}"
    printf '║  %-14s: %-23s║\n' "$LABEL" "$VALUE"
    printf '%b' "${COLOR_RESET}"
}

# ---------------------------------------------------------------------------
# cloud start
# ---------------------------------------------------------------------------
cloudion_start()
{
    if ! cloudion_check_available; then return 1; fi

    printf '%b' "${COLOR_YELLOW}"
    printf '\nStarting Cloudion...\n'
    printf '%b' "${COLOR_RESET}"

    cloudion_run_kv start

    cloudion_box_header "CLOUDION — START"

    if [[ "$_CK_STATUS" == "SUCCESS" ]]; then
        cloudion_box_row "Status"  "STARTED ✓"
        [[ -n "$_CK_PID" ]] && cloudion_box_row "PID"     "$_CK_PID"
        cloudion_box_row "Port"    "4000"
        cloudion_box_row "URL"     "http://localhost:4000"
        cloudion_box_row "Logs"    "cloud logs"
    else
        printf '%b' "${COLOR_RED}"
        printf '║  %-40s║\n' "FAILED TO START"
        printf '%b' "${COLOR_RESET}"
        [[ -n "$_CK_MESSAGE" ]] && printf '║  %-40s║\n' "$_CK_MESSAGE"
    fi

    cloudion_box_footer
}

# ---------------------------------------------------------------------------
# cloud stop
# ---------------------------------------------------------------------------
cloudion_stop()
{
    if ! cloudion_check_available; then return 1; fi

    printf '%b' "${COLOR_YELLOW}"
    printf '\nStopping Cloudion...\n'
    printf '%b' "${COLOR_RESET}"

    cloudion_run_kv stop

    cloudion_box_header "CLOUDION — STOP"

    if [[ "$_CK_STATUS" == "SUCCESS" ]]; then
        cloudion_box_row "Status"  "STOPPED ✓"
        [[ -n "$_CK_MESSAGE" ]] && cloudion_box_row "Info" "$_CK_MESSAGE"
    else
        printf '%b' "${COLOR_RED}"
        printf '║  %-40s║\n' "FAILED TO STOP"
        printf '%b' "${COLOR_RESET}"
        [[ -n "$_CK_MESSAGE" ]] && printf '║  %-40s║\n' "$_CK_MESSAGE"
    fi

    cloudion_box_footer
}

# ---------------------------------------------------------------------------
# cloud restart
# ---------------------------------------------------------------------------
cloudion_restart()
{
    if ! cloudion_check_available; then return 1; fi

    printf '%b' "${COLOR_YELLOW}"
    printf '\nRestarting Cloudion...\n'
    printf '%b' "${COLOR_RESET}"

    cloudion_run_kv restart

    cloudion_box_header "CLOUDION — RESTART"

    if [[ "$_CK_STATUS" == "SUCCESS" ]]; then
        cloudion_box_row "Status"  "RESTARTED ✓"
        [[ -n "$_CK_PID" ]] && cloudion_box_row "PID"     "$_CK_PID"
        cloudion_box_row "Port"    "4000"
    else
        printf '%b' "${COLOR_RED}"
        printf '║  %-40s║\n' "FAILED TO RESTART"
        printf '%b' "${COLOR_RESET}"
        [[ -n "$_CK_MESSAGE" ]] && printf '║  %-40s║\n' "$_CK_MESSAGE"
    fi

    cloudion_box_footer
}

# ---------------------------------------------------------------------------
# cloud status
# ---------------------------------------------------------------------------
cloudion_status()
{
    if ! cloudion_check_available; then return 1; fi

    cloudion_run_kv status

    cloudion_box_header "CLOUDION — STATUS"

    # Server state
    if [[ "$_CK_CLOUDION_STATE" == "RUNNING" ]]; then
        printf '%b' "${COLOR_SUCCESS}"
        printf '║  %-14s: %-23s║\n' "Server" "RUNNING ●"
        printf '%b' "${COLOR_RESET}"
        [[ -n "$_CK_PID" ]] && cloudion_box_row "PID" "$_CK_PID"
        cloudion_box_row "URL" "http://localhost:4000"
    else
        printf '%b' "${COLOR_RED}"
        printf '║  %-14s: %-23s║\n' "Server" "STOPPED ○"
        printf '%b' "${COLOR_RESET}"
    fi

    # Separator
    printf '%b' "${COLOR_YELLOW}"
    printf '╠══════════════════════════════════════════╣\n'
    printf '%b' "${COLOR_DIM}"
    printf '║  %-40s║\n' "System Metrics"
    printf '%b' "${COLOR_YELLOW}"
    printf '╠══════════════════════════════════════════╣\n'
    printf '%b' "${COLOR_RESET}"

    # CPU
    if [[ -n "$_CK_CPU_USAGE_PERCENT" ]]; then
        local CPU_LABEL="CPU"
        [[ -n "$_CK_CPU_CORES" ]] && CPU_LABEL="CPU ($_CK_CPU_CORES cores)"
        cloudion_box_row "$CPU_LABEL" "${_CK_CPU_USAGE_PERCENT}%"
    fi

    # Memory
    if [[ -n "$_CK_MEMORY_USAGE_PERCENT" ]]; then
        if [[ -n "$_CK_MEMORY_USED_BYTES" && -n "$_CK_MEMORY_TOTAL_BYTES" && "$_CK_MEMORY_TOTAL_BYTES" -gt 0 ]]; then
            local MEM_USED_MB=$(( _CK_MEMORY_USED_BYTES / 1024 / 1024 ))
            local MEM_TOTAL_MB=$(( _CK_MEMORY_TOTAL_BYTES / 1024 / 1024 ))
            cloudion_box_row "Memory" "${_CK_MEMORY_USAGE_PERCENT}% (${MEM_USED_MB}/${MEM_TOTAL_MB} MB)"
        else
            cloudion_box_row "Memory" "${_CK_MEMORY_USAGE_PERCENT}%"
        fi
    fi

    # Disk
    [[ -n "$_CK_DISK_USAGE_PERCENT" ]]    && cloudion_box_row "Disk"       "${_CK_DISK_USAGE_PERCENT}%"

    # Load
    [[ -n "$_CK_LOAD_AVERAGE" ]]          && cloudion_box_row "Load avg"   "$_CK_LOAD_AVERAGE"

    # Uptime
    if [[ -n "$_CK_UPTIME_SECONDS" && "$_CK_UPTIME_SECONDS" =~ ^[0-9]+$ ]]; then
        local UH=$(( _CK_UPTIME_SECONDS / 3600 ))
        local UM=$(( (_CK_UPTIME_SECONDS % 3600) / 60 ))
        local US=$(( _CK_UPTIME_SECONDS % 60 ))
        cloudion_box_row "Uptime" "${UH}h ${UM}m ${US}s"
    fi

    # Processes
    [[ -n "$_CK_PROCESS_COUNT" ]]         && cloudion_box_row "Processes"  "$_CK_PROCESS_COUNT"

    # Network
    [[ -n "$_CK_INTERFACE_COUNT" ]]       && cloudion_box_row "Interfaces" "$_CK_INTERFACE_COUNT"
    [[ -n "$_CK_LISTENING_SOCKET_COUNT" ]] && cloudion_box_row "Listening"  "$_CK_LISTENING_SOCKET_COUNT"

    cloudion_box_footer
}

# ---------------------------------------------------------------------------
# cloud storage
# ---------------------------------------------------------------------------
cloudion_storage()
{
    if ! cloudion_check_available; then return 1; fi

    cloudion_run_kv storage

    cloudion_box_header "CLOUDION — STORAGE"

    # Filesystem total, used, available
    if [[ -n "$_CK_FILESYSTEM_TOTAL_BYTES" && "$_CK_FILESYSTEM_TOTAL_BYTES" -gt 0 ]]; then
        local TOTAL_MB=$(( _CK_FILESYSTEM_TOTAL_BYTES / 1024 / 1024 ))
        local USED_MB=$(( _CK_FILESYSTEM_USED_BYTES / 1024 / 1024 ))
        local AVAIL_MB=$(( _CK_FILESYSTEM_AVAILABLE_BYTES / 1024 / 1024 ))
        cloudion_box_row "Total Disk" "${TOTAL_MB} MB"
        cloudion_box_row "Used Disk"  "${USED_MB} MB"
        cloudion_box_row "Available"  "${AVAIL_MB} MB"
    fi

    # Separator
    printf '%b' "${COLOR_YELLOW}"
    printf '╠══════════════════════════════════════════╣\n'
    printf '%b' "${COLOR_DIM}"
    printf '║  %-40s║\n' "Storage Areas"
    printf '%b' "${COLOR_YELLOW}"
    printf '╠══════════════════════════════════════════╣\n'
    printf '%b' "${COLOR_RESET}"

    [[ -n "$_CK_AREA_USERS_BYTES" ]]      && cloudion_box_row "Users (Personal)" "$(( _CK_AREA_USERS_BYTES / 1024 )) KB"
    [[ -n "$_CK_AREA_ONE_TO_ONE_BYTES" ]]  && cloudion_box_row "One-to-One"        "$(( _CK_AREA_ONE_TO_ONE_BYTES / 1024 )) KB"
    [[ -n "$_CK_AREA_GROUPS_BYTES" ]]     && cloudion_box_row "Groups"            "$(( _CK_AREA_GROUPS_BYTES / 1024 )) KB"
    [[ -n "$_CK_AREA_GLOBAL_BYTES" ]]     && cloudion_box_row "Global Cloud"      "$(( _CK_AREA_GLOBAL_BYTES / 1024 )) KB"
    [[ -n "$_CK_AREA_TEMPORARY_BYTES" ]]  && cloudion_box_row "Temporary"         "$(( _CK_AREA_TEMPORARY_BYTES / 1024 )) KB"

    # Per-user breakdown if available
    if [[ -n "$_CK_COUNT" && "$_CK_COUNT" -gt 0 ]]; then
        printf '%b' "${COLOR_YELLOW}"
        printf '╠══════════════════════════════════════════╣\n'
        printf '%b' "${COLOR_DIM}"
        printf '║  %-40s║\n' "User Usage Breakdown"
        printf '%b' "${COLOR_YELLOW}"
        printf '╠══════════════════════════════════════════╣\n'
        printf '%b' "${COLOR_RESET}"

        local i
        for ((i = 0; i < _CK_COUNT; i++)); do
            local UNAME_VAR="_CK_USER_${i}_NAME"
            local UBYTES_VAR="_CK_USER_${i}_BYTES"
            local UNAME="${!UNAME_VAR}"
            local UBYTES="${!UBYTES_VAR}"
            if [[ -n "$UNAME" ]]; then
                cloudion_box_row "$UNAME" "$(( ${UBYTES:-0} / 1024 )) KB"
            fi
        done
    fi

    cloudion_box_footer
}

# ---------------------------------------------------------------------------
# cloud logs [N] [category]
# ---------------------------------------------------------------------------
cloudion_logs()
{
    if ! cloudion_check_available; then return 1; fi

    local COUNT="${1:-30}"
    local CATEGORY="${2:-server}"

    cloudion_run_kv logs "$COUNT" "$CATEGORY"

    local CAT="${_CK_CATEGORY:-$CATEGORY}"
    cloudion_box_header "CLOUDION — LOGS ($CAT)"

    if [[ "$_CK_STATUS" != "SUCCESS" ]]; then
        printf '%b' "${COLOR_RED}"
        printf '║  %-40s║\n' "Error reading logs"
        [[ -n "$_CK_MESSAGE" ]] && printf '║  %-40s║\n' "$_CK_MESSAGE"
        printf '%b' "${COLOR_RESET}"
        cloudion_box_footer
        return 1
    fi

    if [[ "${_CK_COUNT:-0}" -eq 0 ]]; then
        printf '%b' "${COLOR_DIM}"
        printf '║  %-40s║\n' "No log entries yet."
        printf '%b' "${COLOR_RESET}"
        cloudion_box_footer
        return 0
    fi

    cloudion_box_footer

    # Print each log line in readable form (not boxed to preserve line length)
    printf '%b' "${COLOR_DIM}"
    local i=0
    while [[ $i -lt $_CK_LINE_COUNT ]]; do
        local _LINEVAR="_CK_LINE_${i}"
        local _LINEVAL
        _LINEVAL="$(eval echo "\${$_LINEVAR:-}")"
        [[ -n "$_LINEVAL" ]] && printf '  %s\n' "$_LINEVAL"
        i=$(( i + 1 ))
    done
    printf '%b' "${COLOR_RESET}"
    printf '\n'
    return 0
}

# ---------------------------------------------------------------------------
# cloud info
# ---------------------------------------------------------------------------
cloudion_info()
{
    if ! cloudion_check_available; then return 1; fi

    cloudion_run_kv info

    cloudion_box_header "CLOUDION — INFO"

    cloudion_box_row "Name"    "${_CK_NAME:-Cloudion}"
    cloudion_box_row "Version" "${_CK_VERSION:-unknown}"
    cloudion_box_row "State"   "${_CK_STATE:-UNKNOWN}"
    [[ -n "$_CK_PID" ]]    && cloudion_box_row "PID"     "$_CK_PID"
    [[ -n "$_CK_UPTIME" ]] && cloudion_box_row "Uptime"  "$_CK_UPTIME"
    cloudion_box_row "Port"    "4000"
    cloudion_box_row "URL"     "http://localhost:4000"

    printf '%b' "${COLOR_YELLOW}"
    printf '╠══════════════════════════════════════════╣\n'
    printf '%b' "${COLOR_DIM}"
    printf '║  %-40s║\n' "Paths"
    printf '%b' "${COLOR_YELLOW}"
    printf '╠══════════════════════════════════════════╣\n'
    printf '%b' "${COLOR_RESET}"

    [[ -n "$_CK_PROJECT_ROOT" ]] && cloudion_box_row "Root"    "$_CK_PROJECT_ROOT"
    [[ -n "$_CK_STORAGE_ROOT" ]] && cloudion_box_row "Storage" "$_CK_STORAGE_ROOT"
    [[ -n "$_CK_LOGS_ROOT" ]]    && cloudion_box_row "Logs"    "$_CK_LOGS_ROOT"
    [[ -n "$_CK_BACKUPS_ROOT" ]] && cloudion_box_row "Backups" "$_CK_BACKUPS_ROOT"

    if [[ -n "$_CK_SCRIPT_COUNT" || -n "$_CK_CLOUD_AREAS" ]]; then
        printf '%b' "${COLOR_YELLOW}"
        printf '╠══════════════════════════════════════════╣\n'
        printf '%b' "${COLOR_RESET}"
        [[ -n "$_CK_SCRIPT_COUNT" ]] && cloudion_box_row "Scripts" "$_CK_SCRIPT_COUNT shell scripts"
        [[ -n "$_CK_CLOUD_AREAS" ]]  && cloudion_box_row "Areas"   "$_CK_CLOUD_AREAS"
    fi

    cloudion_box_footer
}

# ---------------------------------------------------------------------------
# cloud help
# ---------------------------------------------------------------------------
cloudion_help()
{
    local -a HELP_ROWS=(
        "cloud|Manage Cloudion server|cloud start"
        "cloud start|Start Cloudion backend|cloud start"
        "cloud stop|Stop Cloudion backend|cloud stop"
        "cloud restart|Restart Cloudion|cloud restart"
        "cloud status|Show status & metrics|cloud status"
        "cloud storage|Show storage usage & breakdown|cloud storage"
        "cloud logs|Show recent server logs|cloud logs"
        "cloud logs N cat|Show N lines of category|cloud logs 50 auth"
        "cloud info|Show full project info|cloud info"
        "cloud help|Show this help|cloud help"
    )
    azterm_print_help_table "${HELP_ROWS[@]}"
}

# ---------------------------------------------------------------------------
# Dispatcher — called by AzTerm's route_command()
# Returns 0 if handled, 1 if not our command.
# ---------------------------------------------------------------------------
cloudion_dispatch()
{
    if [[ "$COMMAND" != "cloud" ]]; then
        return 1
    fi

    if [[ $ARG_COUNT -eq 0 ]]; then
        cloudion_help
        return 0
    fi

    case "${ARGS[0]}" in
        start)
            cloudion_start
            return 0
            ;;
        stop)
            cloudion_stop
            return 0
            ;;
        restart)
            cloudion_restart
            return 0
            ;;
        status)
            cloudion_status
            return 0
            ;;
        storage)
            cloudion_storage
            return 0
            ;;
        logs)
            local LOG_COUNT=30
            local LOG_CAT="server"
            if [[ $ARG_COUNT -ge 2 ]]; then
                LOG_COUNT="${ARGS[1]}"
            fi
            if [[ $ARG_COUNT -ge 3 ]]; then
                LOG_CAT="${ARGS[2]}"
            fi
            cloudion_logs "$LOG_COUNT" "$LOG_CAT"
            return 0
            ;;
        info)
            cloudion_info
            return 0
            ;;
        help)
            cloudion_help
            return 0
            ;;
        *)
            echo
            printf '%b' "${COLOR_RED}"
            echo "Unknown cloud subcommand: ${ARGS[0]}"
            printf '%b' "${COLOR_RESET}"
            echo
            cloudion_help
            return 1
            ;;
    esac
}
