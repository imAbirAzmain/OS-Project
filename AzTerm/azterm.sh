#!/bin/bash

############################################################
# AzTerm v2
#
# Main Program
############################################################

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

azterm_launch_macos_terminal()
{
    osascript <<EOF
    tell application "Terminal"
        activate
        tell application "System Events" to keystroke "n" using {command down}
        do script "export AZTERM_CHILD=1; cd '$SCRIPT_DIR'; exec bash '$SCRIPT_DIR/azterm.sh'"
    end tell
EOF
    exit 0
}

if [[ "${AZTERM_CHILD:-0}" != "1" ]]; then
    case "$(uname -s)" in
        Darwin)
            azterm_launch_macos_terminal
            ;;
        *)
            ;;
    esac
fi

############################################################
# Load Configuration
############################################################

source "$SCRIPT_DIR/config/config.sh"

############################################################
# Load Libraries
############################################################

source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/commands.sh"
source "$SCRIPT_DIR/lib/parser.sh"
source "$SCRIPT_DIR/lib/filesystem.sh"
source "$SCRIPT_DIR/lib/history.sh"
source "$SCRIPT_DIR/lib/script.sh"
source "$SCRIPT_DIR/lib/cloudion.sh"
source "$SCRIPT_DIR/lib/interpreter.sh"

############################################################
# Initialize
############################################################

# Set up history file path relative to script directory if not already absolute
if [[ "$HISTORY_FILE" != /* ]]; then
    HISTORY_FILE="$SCRIPT_DIR/$HISTORY_FILE"
fi

# Initialize history system
history_init

show_banner

############################################################
# Main Loop
############################################################

INTERACTIVE_BLOCK=()
BLOCK_STACK=()

while true
do
    if (( ${#BLOCK_STACK[@]} == 0 )); then
        # Update prompt to show current directory
        CURRENT_DIR="$(get_prompt_path "$PWD")"
        DYNAMIC_PROMPT=$'\001'"${COLOR_ORANGE}"$'\002'"az> "$'\001'"${COLOR_RESET}"$'\002'
    else
        # Continuation prompt for open blocks
        DYNAMIC_PROMPT=$'\001'"${COLOR_YELLOW}"$'\002'">>> "$'\001'"${COLOR_RESET}"$'\002'
    fi

    azterm_read_command "$DYNAMIC_PROMPT" || break

    if [[ -z "$USER_COMMAND" ]]
    then
        continue
    fi

    # Discard open block if user types :cancel
    if [[ "$USER_COMMAND" == ":cancel" ]] && (( ${#BLOCK_STACK[@]} > 0 )); then
        INTERACTIVE_BLOCK=()
        BLOCK_STACK=()
        echo "Block discarded."
        continue
    fi

    # Record command in history (before execution)
    history_add "$USER_COMMAND"

    if (( ${#BLOCK_STACK[@]} == 0 )); then
        # Check if command starts a multi-line block
        START_TYPE="$(az_is_block_start "$USER_COMMAND")"
        if [[ -n "$START_TYPE" ]]; then
            BLOCK_STACK+=("$START_TYPE")
            INTERACTIVE_BLOCK=("$USER_COMMAND")
            continue
        fi

        # Parse and execute single command
        parse_command "$USER_COMMAND"
    else
        # Inside interactive block
        START_TYPE="$(az_is_block_start "$USER_COMMAND")"
        if [[ -n "$START_TYPE" ]]; then
            BLOCK_STACK+=("$START_TYPE")
        fi

        END_TYPE="$(az_is_block_end "$USER_COMMAND")"
        if [[ -n "$END_TYPE" ]]; then
            LAST_INDEX=$(( ${#BLOCK_STACK[@]} - 1 ))
            EXPECTED_TYPE="${BLOCK_STACK[$LAST_INDEX]}"
            if [[ "$EXPECTED_TYPE" == "$END_TYPE" ]]; then
                unset 'BLOCK_STACK[LAST_INDEX]'
                BLOCK_STACK=("${BLOCK_STACK[@]}")
            else
                echo "Error: Mismatched block end: expected 'end $EXPECTED_TYPE', got '$USER_COMMAND'."
                INTERACTIVE_BLOCK=()
                BLOCK_STACK=()
                continue
            fi
        fi

        INTERACTIVE_BLOCK+=("$USER_COMMAND")

        # When all open blocks are closed, execute the collected block
        if (( ${#BLOCK_STACK[@]} == 0 )); then
            az_execute_block_lines "${INTERACTIVE_BLOCK[@]}"
            INTERACTIVE_BLOCK=()
            BLOCK_STACK=()
        fi
    fi

done


