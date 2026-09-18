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

while true
do
    # Update prompt to show current directory
    CURRENT_DIR="$(get_prompt_path "$PWD")"
    DYNAMIC_PROMPT=$'\001'"${COLOR_ORANGE}"$'\002'"az> "$'\001'"${COLOR_RESET}"$'\002'

    azterm_read_command "$DYNAMIC_PROMPT" || break

    if [[ -z "$USER_COMMAND" ]]
    then
        continue
    fi

    # Record command in history (before execution)
    history_add "$USER_COMMAND"

    # Parse and execute command
    parse_command "$USER_COMMAND"

done

