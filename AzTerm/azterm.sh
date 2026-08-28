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

# Set up history file path relative to script directory
HISTORY_FILE="$SCRIPT_DIR/$HISTORY_FILE"

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
    DYNAMIC_PROMPT="${COLOR_ORANGE}az> ${COLOR_RESET}"

    read -rp "$DYNAMIC_PROMPT" USER_COMMAND

    if [[ -z "$USER_COMMAND" ]]
    then
        continue
    fi

    # Record command in history (before execution)
    history_add "$USER_COMMAND"

    # Parse and execute command
    parse_command "$USER_COMMAND"

done

