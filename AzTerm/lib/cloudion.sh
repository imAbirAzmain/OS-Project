#!/bin/bash

############################################################
# Cloudion management integration
############################################################

cloudion_platform_name()
{
    case "$(uname -s)" in
        Darwin)
            echo "macOS"
            ;;
        Linux)
            echo "Linux"
            ;;
        *)
            echo "$(uname -s)"
            ;;
    esac
}

cloudion_project_dir()
{
    local CANDIDATE="${CLOUDION_PATH:-${SCRIPT_DIR%/*}/cloudion}"

    if [[ "$CANDIDATE" = /* ]]; then
        echo "$CANDIDATE"
    else
        echo "$SCRIPT_DIR/$CANDIDATE"
    fi
}

cloudion_binary_path()
{
    local PROJECT_DIR
    PROJECT_DIR="$(cloudion_project_dir)"
    local CANDIDATE="${CLOUDION_EXECUTABLE:-bin/minicloud-server}"

    if [[ "$CANDIDATE" = /* ]]; then
        echo "$CANDIDATE"
    else
        echo "$PROJECT_DIR/$CANDIDATE"
    fi
}

cloudion_log_path()
{
    local PROJECT_DIR
    PROJECT_DIR="$(cloudion_project_dir)"

    local PROJECT_LOG_PATHS=(
        "$PROJECT_DIR/logs/server.log"
        "$PROJECT_DIR/server.log"
    )

    local i
    for i in "${PROJECT_LOG_PATHS[@]}"; do
        if [[ -f "$i" ]]; then
            echo "$i"
            return 0
        fi
    done

    local CANDIDATE="${CLOUDION_LOG_FILE:-${SCRIPT_DIR}/data/cloudion.log}"

    if [[ "$CANDIDATE" = /* ]]; then
        echo "$CANDIDATE"
    else
        echo "$SCRIPT_DIR/$CANDIDATE"
    fi
}

cloudion_pid_file_path()
{
    local CANDIDATE="${CLOUDION_PID_FILE:-${SCRIPT_DIR}/data/cloudion.pid}"

    if [[ "$CANDIDATE" = /* ]]; then
        echo "$CANDIDATE"
    else
        echo "$SCRIPT_DIR/$CANDIDATE"
    fi
}

cloudion_port_value()
{
    local PROJECT_DIR
    PROJECT_DIR="$(cloudion_project_dir)"

    if [[ -f "$PROJECT_DIR/config/server.conf" ]]; then
        local PORT_LINE
        PORT_LINE=$(grep '^PORT=' "$PROJECT_DIR/config/server.conf" 2>/dev/null | head -n 1)
        if [[ -n "$PORT_LINE" ]]; then
            echo "${PORT_LINE#PORT=}"
            return 0
        fi
    fi

    if [[ -f "$PROJECT_DIR/config.ini" ]]; then
        local PORT_LINE
        PORT_LINE=$(grep '^port=' "$PROJECT_DIR/config.ini" 2>/dev/null | head -n 1)
        if [[ -n "$PORT_LINE" ]]; then
            echo "${PORT_LINE#port=}"
            return 0
        fi
    fi

    if [[ -n "${CLOUDION_PORT:-}" ]]; then
        echo "$CLOUDION_PORT"
        return 0
    fi

    echo "8080"
}

cloudion_probe_runtime()
{
    local BINARY_PATH
    BINARY_PATH="$(cloudion_binary_path)"

    if [[ ! -f "$BINARY_PATH" ]]; then
        return 1
    fi

    if [[ ! -x "$BINARY_PATH" ]]; then
        return 1
    fi

    local FILE_INFO
    FILE_INFO=$(file "$BINARY_PATH" 2>/dev/null || true)
    if [[ "$FILE_INFO" != *"Mach-O"* && "$FILE_INFO" != *"ELF"* ]]; then
        return 1
    fi

    local PROBE_LOG
    PROBE_LOG="$(mktemp)"
    "$BINARY_PATH" > "$PROBE_LOG" 2>&1 &
    local PROBE_PID=$!
    sleep 2

    if kill -0 "$PROBE_PID" 2>/dev/null; then
        kill "$PROBE_PID" 2>/dev/null || kill -9 "$PROBE_PID" 2>/dev/null || true
        wait "$PROBE_PID" 2>/dev/null || true
        rm -f "$PROBE_LOG"
        return 0
    fi

    wait "$PROBE_PID" 2>/dev/null || true
    rm -f "$PROBE_LOG"
    return 1
}

cloudion_compatible_with_os()
{
    if cloudion_probe_runtime; then
        return 0
    fi

    return 1
}

cloudion_print_compatibility_error()
{
    local BINARY_PATH
    BINARY_PATH="$(cloudion_binary_path)"

    echo
    echo "Cloudion cannot be started from this host."
    echo
    echo "Detected platform: $(cloudion_platform_name)"
    echo "Executable: $BINARY_PATH"
    echo
    echo "The Cloudion binary is present, but it did not pass a real runtime startup check."
    echo "This usually means the binary is incompatible with this host or exited immediately."
    echo
    return 1
}

cloudion_clean_stale_pid()
{
    local PID_FILE
    PID_FILE="$(cloudion_pid_file_path)"

    if [[ ! -f "$PID_FILE" ]]; then
        return 0
    fi

    local PID
    PID=$(tr -d '[:space:]' < "$PID_FILE")

    if [[ ! "$PID" =~ ^[0-9]+$ ]]; then
        rm -f "$PID_FILE"
        return 0
    fi

    if ! kill -0 "$PID" 2>/dev/null; then
        rm -f "$PID_FILE"
    fi
}

cloudion_find_pid()
{
    local PID_FILE
    PID_FILE="$(cloudion_pid_file_path)"
    local PID=""

    if [[ -f "$PID_FILE" ]]; then
        PID=$(tr -d '[:space:]' < "$PID_FILE")
        if [[ "$PID" =~ ^[0-9]+$ ]] && kill -0 "$PID" 2>/dev/null; then
            local PROCESS_NAME
            PROCESS_NAME=$(ps -p "$PID" -o comm= 2>/dev/null | tr -d '[:space:]')
            if [[ "$PROCESS_NAME" == "minicloud-server" ]]; then
                echo "$PID"
                return 0
            fi
        fi
        rm -f "$PID_FILE"
    fi

    while IFS=' ' read -r PID PROCESS_NAME ARGS; do
        if [[ "$PID" =~ ^[0-9]+$ ]] && kill -0 "$PID" 2>/dev/null; then
            if [[ "$PROCESS_NAME" == "minicloud-server" ]] || [[ "$ARGS" == *"minicloud-server"* ]]; then
                echo "$PID"
                return 0
            fi
        fi
    done < <(ps -eo pid=,comm=,args= 2>/dev/null)

    return 1
}

cloudion_is_running()
{
    if [[ -n "$(cloudion_find_pid)" ]]; then
        return 0
    fi

    return 1
}

cloudion_start()
{
    if ! cloudion_compatible_with_os; then
        cloudion_print_compatibility_error
        return 1
    fi

    if cloudion_is_running; then
        echo
        echo "Cloudion is already running."
        echo
        return 1
    fi

    local PROJECT_DIR
    PROJECT_DIR="$(cloudion_project_dir)"
    local BINARY_PATH
    BINARY_PATH="$(cloudion_binary_path)"
    local LOG_FILE
    LOG_FILE="$(cloudion_log_path)"
    local PID_FILE
    PID_FILE="$(cloudion_pid_file_path)"

    if [[ ! -f "$BINARY_PATH" ]]; then
        echo
        echo "Error: Cloudion executable was not found."
        echo
        echo "Expected:"
        echo "    $BINARY_PATH"
        echo
        return 1
    fi

    if [[ ! -x "$BINARY_PATH" ]]; then
        echo
        echo "Error: Cloudion executable is not executable."
        echo
        echo "Expected:"
        echo "    $BINARY_PATH"
        echo
        return 1
    fi

    mkdir -p "$(dirname "$PID_FILE")"
    mkdir -p "$(dirname "$LOG_FILE")"

    echo
    echo "Starting Cloudion..."

    (
        cd "$PROJECT_DIR" || exit 1
        "$BINARY_PATH" > "$LOG_FILE" 2>&1 &
        echo $! > "$PID_FILE"
    )

    sleep 1

    local PID
    PID=$(cloudion_find_pid || true)

    if [[ -n "$PID" ]]; then
        echo
        echo "Cloudion started successfully."
        echo "PID: $PID"
        echo "Port: $(cloudion_port_value)"
        echo
        return 0
    fi

    echo
    echo "Failed to start Cloudion."
    echo
    if [[ -f "$LOG_FILE" ]]; then
        echo "Recent log output:"
        tail -n 20 "$LOG_FILE" 2>/dev/null
        echo
    fi
    rm -f "$PID_FILE"
    return 1
}

cloudion_stop()
{
    local PID
    PID=$(cloudion_find_pid || true)

    if [[ -z "$PID" ]]; then
        echo
        echo "Cloudion is not running."
        echo
        return 1
    fi

    echo
    echo "Stopping Cloudion..."
    kill -TERM "$PID" 2>/dev/null

    sleep 1

    if cloudion_is_running; then
        echo "Graceful shutdown did not complete."
        echo "Sending SIGKILL to PID $PID"
        kill -KILL "$PID" 2>/dev/null || true
        sleep 1
    fi

    if cloudion_is_running; then
        echo
        echo "Failed to stop Cloudion."
        echo
        return 1
    fi

    rm -f "$(cloudion_pid_file_path)"
    echo
    echo "Cloudion stopped successfully."
    echo
    return 0
}

cloudion_restart()
{
    if cloudion_is_running; then
        echo
        echo "Restarting Cloudion..."
        echo
        cloudion_stop
        cloudion_start
        return 0
    fi

    echo
    echo "Cloudion is not running."
    echo "Starting Cloudion..."
    echo
    cloudion_start
}

cloudion_status_line()
{
    local TEXT="$1"
    printf '%-14s : %s\n' "${TEXT}" "${2}"
}

cloudion_status()
{
    echo
    echo "========================================"
    echo "         CLOUDION STATUS"
    echo "========================================"

    if ! cloudion_compatible_with_os; then
        echo
        echo "Status       : INCOMPATIBLE"
        echo "Current OS   : $(cloudion_platform_name)"
        echo "Executable   : $(cloudion_binary_path)"
        echo
        echo "========================================"
        echo
        return 0
    fi

    local PID
    PID=$(cloudion_find_pid || true)

    if [[ -z "$PID" ]]; then
        echo
        echo "Status       : STOPPED"
        echo
        echo "========================================"
        echo
        return 0
    fi

    local PORT
    PORT="$(cloudion_port_value)"
    local UPTIME
    UPTIME=$(ps -p "$PID" -o etime= 2>/dev/null | tr -d '[:space:]')

    echo
    echo "Status       : RUNNING"
    echo "PID          : $PID"
    echo "Port         : $PORT"
    if [[ -n "$UPTIME" ]]; then
        echo "Uptime       : $UPTIME"
    fi
    echo "Server       : $(basename "$(cloudion_binary_path)")"
    echo
    echo "========================================"
    echo
    return 0
}

cloudion_info()
{
    local PROJECT_DIR
    PROJECT_DIR="$(cloudion_project_dir)"
    local BINARY_PATH
    BINARY_PATH="$(cloudion_binary_path)"
    local PORT
    PORT="$(cloudion_port_value)"
    local PID_FILE
    PID_FILE="$(cloudion_pid_file_path)"
    local LOG_FILE
    LOG_FILE="$(cloudion_log_path)"
    local STATUS_TEXT="STOPPED"

    if cloudion_is_running; then
        STATUS_TEXT="RUNNING"
    fi

    echo
    echo "========================================"
    echo "         CLOUDION INFORMATION"
    echo "========================================"
    echo
    echo "Project      : Cloudion"
    echo "Server       : $(basename "$BINARY_PATH")"
    echo "Location     : $PROJECT_DIR"
    echo "Executable   : $BINARY_PATH"
    echo "Port         : $PORT"
    echo "PID File     : $PID_FILE"
    echo "Log File     : $LOG_FILE"
    echo "Platform     : $(cloudion_platform_name)"
    echo "Status       : $STATUS_TEXT"
    echo
    echo "========================================"
    echo
    return 0
}

cloudion_logs()
{
    local COUNT="${1:-20}"
    local LOG_FILE
    LOG_FILE="$(cloudion_log_path)"

    if [[ ! "$COUNT" =~ ^[0-9]+$ ]]; then
        COUNT=20
    fi

    echo
    echo "========================================"
    echo "          CLOUDION LOGS"
    echo "========================================"
    echo

    if [[ ! -f "$LOG_FILE" ]]; then
        echo "No Cloudion log file is available yet."
        echo
        echo "========================================"
        echo
        return 1
    fi

    tail -n "$COUNT" "$LOG_FILE" 2>/dev/null || echo "Cloudion log file is empty."

    echo
    echo "========================================"
    echo
    return 0
}

cloudion_help()
{
    echo
    echo "Cloudion Management"
    echo "==================="
    echo
    echo "cloud start"
    echo "    Start Cloudion."
    echo
    echo "cloud stop"
    echo "    Stop Cloudion."
    echo
    echo "cloud restart"
    echo "    Restart Cloudion."
    echo
    echo "cloud status"
    echo "    Show Cloudion status."
    echo
    echo "cloud logs"
    echo "    Show recent Cloudion logs."
    echo
    echo "cloud info"
    echo "    Show Cloudion information."
    echo
    echo "cloud help"
    echo "    Show this help."
    echo
}

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
        logs)
            if [[ $ARG_COUNT -ge 2 ]]; then
                cloudion_logs "${ARGS[1]}"
            else
                cloudion_logs 20
            fi
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
            echo "Unknown Cloudion command: ${ARGS[0]}"
            echo
            cloudion_help
            return 1
            ;;
    esac
}
