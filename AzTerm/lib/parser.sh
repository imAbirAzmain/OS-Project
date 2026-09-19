#!/bin/bash

############################################################
# Command Parser and Tokenizer
############################################################

# Global variables to store parsed command information
COMMAND=""
ARGS=()
ARG_COUNT=0
USER_INPUT=""

############################################################
# Tokenize user input
# Handles quoted arguments
############################################################
tokenize_input()
{
    local INPUT="$1"
    local CURRENT_TOKEN=""
    local IN_QUOTES=false
    local QUOTE_CHAR=""
    local i

    # Process each character
    for ((i = 0; i < ${#INPUT}; i++)); do
        local CHAR="${INPUT:$i:1}"

        if [[ "$CHAR" == '"' || "$CHAR" == "'" ]] && [[ "$IN_QUOTES" == false ]]; then
            # Start of quoted string
            IN_QUOTES=true
            QUOTE_CHAR="$CHAR"
        elif [[ "$CHAR" == "$QUOTE_CHAR" ]] && [[ "$IN_QUOTES" == true ]]; then
            # End of quoted string
            IN_QUOTES=false
        elif [[ "$CHAR" == " " ]] && [[ "$IN_QUOTES" == false ]]; then
            # Space outside quotes - token separator
            if [[ -n "$CURRENT_TOKEN" ]]; then
                echo "$CURRENT_TOKEN"
                CURRENT_TOKEN=""
            fi
        else
            # Regular character
            CURRENT_TOKEN+="$CHAR"
        fi
    done

    # Print the last token if exists
    if [[ -n "$CURRENT_TOKEN" ]]; then
        echo "$CURRENT_TOKEN"
    fi
}

############################################################
# Parse user command input
# Sets global: COMMAND, ARGS[], ARG_COUNT, USER_INPUT
############################################################
parse_command()
{
    local INPUT="$1"
    
    # Store original input
    USER_INPUT="$INPUT"
    
    # Skip empty input
    if [[ -z "$INPUT" ]]; then
        COMMAND=""
        ARGS=()
        ARG_COUNT=0
        return 1
    fi

    # Tokenize the input into an array
    local -a TOKENS=()
    while IFS= read -r TOKEN; do
        TOKENS+=("$TOKEN")
    done < <(tokenize_input "$INPUT")

    # First token is the command
    COMMAND="${TOKENS[0]}"
    
    # Remaining tokens are arguments
    ARGS=()
    local i
    for ((i = 1; i < ${#TOKENS[@]}; i++)); do
        ARGS+=("${TOKENS[$i]}")
    done

    ARG_COUNT=${#ARGS[@]}

    # Dispatch to the appropriate handler
    route_command
}

############################################################
# Route command to appropriate module
# Each module returns 0 if handled, 1 if not
############################################################
route_command()
{
    # Try commands module first
    if commands_dispatch; then
        return 0
    fi

    # Try filesystem module
    if filesystem_dispatch; then
        return 0
    fi

    # Try history module
    if history_dispatch; then
        return 0
    fi

    # Try script module
    if script_dispatch; then
        return 0
    fi

    # Try Cloudion module
    if cloudion_dispatch; then
        return 0
    fi

    # Try interpreter module (print, math, assignments, calc)
    if interpreter_dispatch; then
        return 0
    fi

    # Unknown command
    echo
    echo "Unknown command: $COMMAND"
    echo "Type 'help' for available commands."
    echo
    
    return 1
}

