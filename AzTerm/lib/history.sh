#!/bin/bash

############################################################
# AzTerm v2 - History Module
############################################################
#
# This file manages AzTerm command history.
#
# Responsibilities:
#   1. Initialize the persistent history file.
#   2. Add commands to history.
#   3. Display command history.
#   4. Dispatch the "history" command.
#
# The visual history table itself is handled by:
#
#   lib/utils.sh
#
# through:
#
#   azterm_print_history_box
#
############################################################


############################################################
# History counter
############################################################
#
# Keeps track of the number of commands added during the
# current AzTerm session.
#
# The actual persistent history is stored in:
#
#   data/history.txt
#
############################################################

HISTORY_COUNT=0


############################################################
# Dispatch history commands
############################################################
#
# Checks whether the current command is:
#
#   history
#
# Returns:
#
#   0 = command was handled
#   1 = command was not handled
#
############################################################

history_dispatch()
{
    case "$COMMAND" in

        history)
            history_display
            return 0
            ;;

        *)
            return 1
            ;;

    esac
}


############################################################
# Initialize history file
############################################################
#
# Creates the history directory and file if they do not
# already exist.
#
############################################################

history_init()
{
    if [[ ! -f "$HISTORY_FILE" ]]; then

        mkdir -p "$(dirname "$HISTORY_FILE")"

        touch "$HISTORY_FILE"

    fi
}


############################################################
# Add a command to history
############################################################
#
# Usage:
#
#   history_add "command"
#
# Empty commands are ignored.
#
# The "history" command itself is not stored to prevent the
# history list from becoming unnecessarily repetitive.
#
############################################################

history_add()
{
    local COMMAND_TO_ADD="$1"

    ########################################################
    # Ignore empty commands.
    ########################################################

    if [[ -z "$COMMAND_TO_ADD" ]]; then
        return 0
    fi


    ########################################################
    # Do not store the history command itself.
    ########################################################

    if [[ "$COMMAND_TO_ADD" == "history" ]]; then
        return 0
    fi


    ########################################################
    # Make sure the history file exists.
    ########################################################

    if [[ ! -f "$HISTORY_FILE" ]]; then
        history_init
    fi


    ########################################################
    # Add command to persistent history.
    ########################################################

    printf '%s\n' "$COMMAND_TO_ADD" >> "$HISTORY_FILE"


    ########################################################
    # Update session counter.
    ########################################################

    ((HISTORY_COUNT++))

    return 0
}


############################################################
# Display command history
############################################################
#
# The actual visual table is handled by:
#
#   azterm_print_history_box
#
# This keeps the history logic separate from the UI logic.
#
############################################################

history_display()
{
    ########################################################
    # Make sure the history file exists.
    ########################################################

    history_init


    ########################################################
    # Let the utility function handle the entire display.
    ########################################################

    azterm_print_history_box

    return 0
}