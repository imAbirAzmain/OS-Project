#!/bin/bash

############################################################
# Script Engine Module
############################################################

############################################################
# Dispatch script commands
# Returns 0 if handled, 1 if not
############################################################
script_dispatch()
{
    case "$COMMAND" in
        script)
            script_execute
            return 0
            ;;
        write)
            # "write script" command
            if [[ "${ARGS[0]}" == "script" ]]; then
                script_editor
                return 0
            fi
            return 1
            ;;
        *)
            return 1
            ;;
    esac
}

############################################################
# Execute a .az script file
# Syntax: script <filename.az>
############################################################
script_execute()
{
    if [[ $ARG_COUNT -lt 1 ]]; then
        echo
        echo "Error: Missing script filename."
        echo "Usage:"
        echo "  script <filename.az>"
        echo
        return 1
    fi

    local SCRIPT_FILE="${ARGS[0]}"

    # Check if file exists
    if [[ ! -f "$SCRIPT_FILE" ]]; then
        echo
        echo "Error: Script file not found: $SCRIPT_FILE"
        echo
        return 1
    fi

    echo
    echo "Executing script: $SCRIPT_FILE"
    echo

    # Execute the script
    local -a SCRIPT_LINES=()
    while IFS= read -r LINE_CONTENT || [[ -n "$LINE_CONTENT" ]]; do
        SCRIPT_LINES+=("$LINE_CONTENT")
    done < "$SCRIPT_FILE"

    AZ_SCRIPT_FILE="$SCRIPT_FILE"
    AZ_IN_SCRIPT=1
    az_execute_block_lines "${SCRIPT_LINES[@]}"
    local COMMAND_RESULT=$?
    AZ_IN_SCRIPT=0
    AZ_SCRIPT_FILE=""

    # Check if script succeeded
    if [[ $COMMAND_RESULT -ne 0 ]]; then
        echo
        echo "Script Error"
        echo "File: $SCRIPT_FILE"
        echo
        return 1
    fi

    echo
    echo "Script completed successfully."
    echo
    return 0
}

############################################################
# Built-in script editor
# Syntax: write script <filename.az>
############################################################
script_editor()
{
    if [[ $ARG_COUNT -lt 2 ]]; then
        echo
        echo "Error: Missing script filename."
        echo "Usage:"
        echo "  write script <filename.az>"
        echo
        return 1
    fi

    local SCRIPT_FILE="${ARGS[1]}"

    echo
    echo "========================================"
    echo "        AZTERM SCRIPT EDITOR"
    echo "========================================"
    echo
    echo "Writing $SCRIPT_FILE"
    echo
    echo "Enter script commands. Type ':save' to save or ':cancel' to discard."
    echo
    echo "az-script> "

    local -a SCRIPT_LINES=()
    local INPUT_LINE

    # If file exists, load its content
    if [[ -f "$SCRIPT_FILE" ]]; then
        while IFS= read -r INPUT_LINE; do
            SCRIPT_LINES+=("$INPUT_LINE")
        done < "$SCRIPT_FILE"
    fi

    # Read input lines
    while true; do
        read -rp "az-script> " INPUT_LINE

        if [[ "$INPUT_LINE" == ":save" ]]; then
            # Save the script
            {
                printf '%s\n' "${SCRIPT_LINES[@]}"
            } > "$SCRIPT_FILE"
            echo
            echo "Script saved: $SCRIPT_FILE"
            echo
            return 0

        elif [[ "$INPUT_LINE" == ":cancel" ]]; then
            # Discard without saving
            echo
            echo "Script discarded."
            echo
            return 0

        else
            # Add line to script
            SCRIPT_LINES+=("$INPUT_LINE")
        fi
    done
}

