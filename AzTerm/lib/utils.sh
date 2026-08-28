#!/bin/bash

############################################################
# Utility Functions
############################################################

azterm_set_title()
{
    printf '\033]0;%s\007' "$AZTERM_TITLE"
}

azterm_print_header()
{
    printf '%b' "${COLOR_YELLOW}"
    printf '%s\n' "AZTERM v$AZTERM_VERSION"
    printf '%b' "${COLOR_ORANGE}"
    printf '%s\n' "Custom Bash Terminal"
    printf '%b' "${COLOR_RESET}"
}

azterm_print_system_info()
{
    local OS_NAME
    local ARCH_NAME
    OS_NAME="$(uname -s 2>/dev/null || echo "Unknown")"
    ARCH_NAME="$(uname -m 2>/dev/null || echo "unknown")"

    printf '%b' "${COLOR_DIM}"
    printf '%-12s %s\n' "System" "$OS_NAME"
    printf '%-12s %s\n' "Architecture" "$ARCH_NAME"
    printf '%-12s %s\n' "Shell" "Bash"
    printf '%b' "${COLOR_RESET}"
}

############################################################
# Show the AzTerm banner at startup
############################################################
show_banner()
{
    clear
    azterm_set_title

    printf '%b' "${COLOR_RESET}"
    if [[ -f "$SCRIPT_DIR/assets/logo.txt" ]]; then
        printf '%b' "${COLOR_YELLOW}"
        sed -e 's/^/  /' "$SCRIPT_DIR/assets/logo.txt"
        printf '\n\n'
    fi

    printf '%b' "${COLOR_YELLOW}"
    printf '%s\n' "-------------------------------------------"
    printf '%b' "${COLOR_YELLOW}"
    printf '%s\n' "AZTERM v$AZTERM_VERSION"
    printf '%b' "${COLOR_WHITE}"
    printf '%s\n' "Custom Bash Terminal"
    printf '%b' "${COLOR_WHITE}"
    printf '%s\n' "-------------------------------------------"
    printf '%b' "${COLOR_DIM}"
    printf '%-13s %s\n' "System" "$(uname -s 2>/dev/null || echo "Unknown")"
    printf '%-13s %s\n' "Architecture" "$(uname -m 2>/dev/null || echo "unknown")"
    printf '%-13s %s\n' "Shell" "Bash"
    printf '%b' "${COLOR_RESET}"
    printf '%b' "${COLOR_YELLOW}"
    printf '%s\n' "-------------------------------------------"
    printf '\n'
    printf '%b' "${COLOR_WHITE}"
    printf '%s\n' "Type 'help' to see available commands."
    
    printf '\n'
}

############################################################
# Print a formatted line
############################################################
print_line()
{
    echo "$1"
}

############################################################
# Repeat a character a fixed number of times.
############################################################
azterm_repeat_char()
{
    local CHAR="$1"
    local COUNT="$2"
    local REPEATED=""
    local i

    for ((i = 0; i < COUNT; i++)); do
        REPEATED+="$CHAR"
    done

    printf '%s' "$REPEATED"
}

############################################################
# Truncate text safely to fit inside a fixed-width column.
############################################################
azterm_trim_text()
{
    local TEXT="$1"
    local WIDTH="$2"

    if [[ ${#TEXT} -le $WIDTH ]]; then
        printf '%s' "$TEXT"
        return 0
    fi

    printf '%s…' "${TEXT:0:$((WIDTH - 1))}"
}

############################################################
# Print a boxed history table.
############################################################
azterm_print_history_box()
{
    local -a HISTORY_LINES=()
    local LINE_COUNT=0
    local i

    local TITLE="AZTERM COMMAND HISTORY"

    ########################################################
    # Detect terminal width.
    ########################################################
    local TERM_WIDTH

    TERM_WIDTH="$(tput cols 2>/dev/null || echo 100)"

    if ! [[ "$TERM_WIDTH" =~ ^[0-9]+$ ]]; then
        TERM_WIDTH=100
    fi

    ########################################################
    # Column widths.
    #
    # NO_WIDTH:
    # Space reserved for the history number.
    #
    # CMD_WIDTH:
    # Space reserved for the command itself.
    ########################################################

    local NO_WIDTH=6
    local CMD_WIDTH

    CMD_WIDTH=$((TERM_WIDTH - NO_WIDTH - 10))

    ########################################################
    # Keep the command column within sensible limits.
    ########################################################

    if (( CMD_WIDTH < 30 )); then
        CMD_WIDTH=30
    fi

    if (( CMD_WIDTH > 80 )); then
        CMD_WIDTH=80
    fi

    ########################################################
    # Read persistent history.
    ########################################################

    if [[ -f "$HISTORY_FILE" ]]; then

        while IFS= read -r LINE; do
            HISTORY_LINES+=("$LINE")
        done < "$HISTORY_FILE"

        LINE_COUNT=${#HISTORY_LINES[@]}

    fi

    ########################################################
    # Calculate complete box width.
    ########################################################

    local BOX_WIDTH

    BOX_WIDTH=$((NO_WIDTH + CMD_WIDTH + 3 ))

    ########################################################
    # Calculate title padding.
    ########################################################

    local TITLE_PAD
    local LEFT_PAD
    local RIGHT_PAD

    TITLE_PAD=$((BOX_WIDTH - ${#TITLE} ))

    if (( TITLE_PAD < 0 )); then
        TITLE_PAD=0
    fi

    LEFT_PAD=$((TITLE_PAD / 2))
    RIGHT_PAD=$((TITLE_PAD - LEFT_PAD))

    ########################################################
    # Top border.
    ########################################################

    printf '\n'

    printf '%b' "${COLOR_YELLOW}"

    printf '╔%s╗\n' \
        "$(azterm_repeat_char '═' "$BOX_WIDTH")"

    ########################################################
    # Title.
    ########################################################

    printf '║%*s%s%*s║\n' \
        "$LEFT_PAD" '' \
        "$TITLE" \
        "$RIGHT_PAD" ''

    ########################################################
    # Header separator.
    ########################################################

    printf '╠%s╦%s╣\n' \
        "$(azterm_repeat_char '═' "$NO_WIDTH")" \
        "$(azterm_repeat_char '═' "$((CMD_WIDTH + 2))")"

    ########################################################
    # Column headers.
    ########################################################

    printf '║ %-4s ║ %-*s ║\n' \
        "No." \
        "$CMD_WIDTH" \
        "Command"

    ########################################################
    # Header/data separator.
    ########################################################

    printf '╠%s╬%s╣\n' \
        "$(azterm_repeat_char '═' "$NO_WIDTH")" \
        "$(azterm_repeat_char '═' "$((CMD_WIDTH + 2))")"

    printf '%b' "${COLOR_RESET}"

    ########################################################
    # Empty history.
    ########################################################

    if (( LINE_COUNT == 0 )); then

        local EMPTY_MSG="No command history."
        local EMPTY_WIDTH=$((BOX_WIDTH - 4))

        if (( ${#EMPTY_MSG} > EMPTY_WIDTH )); then
            EMPTY_MSG="$(azterm_trim_text "$EMPTY_MSG" "$EMPTY_WIDTH")"
        fi

        printf '%b' "${COLOR_WHITE}"

        printf '║ %*s ║\n' \
            "$((NO_WIDTH - 1))" ''

        printf '║ %-*s ║\n' \
            "$((CMD_WIDTH + 1))" \
            "$EMPTY_MSG"

        printf '║ %*s ║\n' \
            "$((NO_WIDTH - 1))" ''

        printf '%b' "${COLOR_YELLOW}"

        printf '╚%s╝\n' \
            "$(azterm_repeat_char '═' "$BOX_WIDTH")"

        printf '%b' "${COLOR_RESET}"

        printf '\n'

        return 0
    fi

    ########################################################
    # Print history entries.
    ########################################################

    local LINE_NUM=1
    local COMMAND_TEXT
    local TRUNCATED
    local NO_CELL
    local CMD_CELL

    for i in "${!HISTORY_LINES[@]}"; do

        COMMAND_TEXT="${HISTORY_LINES[$i]}"

        ####################################################
        # Safely fit the command inside the command column.
        ####################################################

        TRUNCATED="$(azterm_trim_text "$COMMAND_TEXT" "$CMD_WIDTH")"

        ####################################################
        # Format history number.
        ####################################################

        NO_CELL="$(printf '%3d' "$LINE_NUM")"

        ####################################################
        # Pad command to exact column width.
        ####################################################

        CMD_CELL="$(printf '%-*s' "$CMD_WIDTH" "$TRUNCATED")"

        ####################################################
        # Print row.
        ####################################################

        printf '%b' "${COLOR_WHITE}"

        printf '║ %s  ║ %s ║\n' \
            "$NO_CELL" \
            "$CMD_CELL"

        printf '%b' "${COLOR_RESET}"

        ((LINE_NUM++))

    done

    ########################################################
    # Bottom border.
    ########################################################

    printf '%b' "${COLOR_YELLOW}"

    printf '╚%s╝\n' \
        "$(azterm_repeat_char '═' "$BOX_WIDTH")"

    printf '%b' "${COLOR_RESET}"

    printf '\n'
}
############################################################
# Print a professional ASCII table for command help.
############################################################
azterm_print_help_table()
{
    local -a ROWS=("$@")
    local row
    local COMMAND
    local FUNCTION
    local EXAMPLE
    local TERM_WIDTH
    local COMMAND_WIDTH
    local FUNCTION_WIDTH
    local EXAMPLE_WIDTH
    local TABLE_WIDTH

    TERM_WIDTH="$(tput cols 2>/dev/null || echo 100)"

    if ! [[ "$TERM_WIDTH" =~ ^[0-9]+$ ]]; then
        TERM_WIDTH=100
    fi

    ########################################################
    # Choose column widths based on terminal size.
    #
    # Command is intentionally wider because AzTerm has
    # multi-word commands such as:
    #
    #   show files
    #   make folder
    #   write script
    #   cloud restart
    ########################################################

    if (( TERM_WIDTH >= 120 )); then

        COMMAND_WIDTH=20
        FUNCTION_WIDTH=42
        EXAMPLE_WIDTH=38

    elif (( TERM_WIDTH >= 100 )); then

        COMMAND_WIDTH=20
        FUNCTION_WIDTH=36
        EXAMPLE_WIDTH=32

    elif (( TERM_WIDTH >= 90 )); then

        COMMAND_WIDTH=18
        FUNCTION_WIDTH=32
        EXAMPLE_WIDTH=28

    else

        COMMAND_WIDTH=16
        FUNCTION_WIDTH=28
        EXAMPLE_WIDTH=24

    fi

    ########################################################
    # Calculate total table width.
    ########################################################

    TABLE_WIDTH=$((COMMAND_WIDTH + FUNCTION_WIDTH + EXAMPLE_WIDTH + 9))

    ########################################################
    # If the table is still wider than the terminal,
    # reduce the Functionality and Example columns first.
    #
    # We intentionally protect the Command column because
    # command names should remain readable.
    ########################################################

    if (( TABLE_WIDTH > TERM_WIDTH )); then

        local AVAILABLE_WIDTH

        AVAILABLE_WIDTH=$((TERM_WIDTH - COMMAND_WIDTH - 9))

        if (( AVAILABLE_WIDTH >= 50 )); then

            FUNCTION_WIDTH=$((AVAILABLE_WIDTH * 55 / 100))
            EXAMPLE_WIDTH=$((AVAILABLE_WIDTH - FUNCTION_WIDTH))

        else

            # Very narrow terminal.
            # Keep the command column readable.

            COMMAND_WIDTH=16
            FUNCTION_WIDTH=24
            EXAMPLE_WIDTH=20

        fi

    fi

    ########################################################
    # Print top border.
    ########################################################

    printf '\n'

    printf '%b' "${COLOR_YELLOW}"

    printf '╔%s╦%s╦%s╗\n' \
        "$(azterm_repeat_char '═' "$((COMMAND_WIDTH + 2))")" \
        "$(azterm_repeat_char '═' "$((FUNCTION_WIDTH + 2))")" \
        "$(azterm_repeat_char '═' "$((EXAMPLE_WIDTH + 2))")"

    ########################################################
    # Print table header.
    ########################################################

    printf '║ %-*s ║ %-*s ║ %-*s ║\n' \
        "$COMMAND_WIDTH" "Command" \
        "$FUNCTION_WIDTH" "Functionality" \
        "$EXAMPLE_WIDTH" "Syntax Example"

    ########################################################
    # Print header separator.
    ########################################################

    printf '╠%s╬%s╬%s╣\n' \
        "$(azterm_repeat_char '═' "$((COMMAND_WIDTH + 2))")" \
        "$(azterm_repeat_char '═' "$((FUNCTION_WIDTH + 2))")" \
        "$(azterm_repeat_char '═' "$((EXAMPLE_WIDTH + 2))")"

    printf '%b' "${COLOR_RESET}"

    ########################################################
    # Print all command rows.
    ########################################################

    for row in "${ROWS[@]}"; do

        IFS='|' read -r COMMAND FUNCTION EXAMPLE <<< "$row"

        printf '%b' "${COLOR_WHITE}"

        printf '║ %-*s ║ %-*s ║ %-*s ║\n' \
            "$COMMAND_WIDTH" "$COMMAND" \
            "$FUNCTION_WIDTH" "$FUNCTION" \
            "$EXAMPLE_WIDTH" "$EXAMPLE"

        printf '%b' "${COLOR_RESET}"

    done

    ########################################################
    # Print bottom border.
    ########################################################

    printf '%b' "${COLOR_YELLOW}"

    printf '╚%s╩%s╩%s╝\n' \
        "$(azterm_repeat_char '═' "$((COMMAND_WIDTH + 2))")" \
        "$(azterm_repeat_char '═' "$((FUNCTION_WIDTH + 2))")" \
        "$(azterm_repeat_char '═' "$((EXAMPLE_WIDTH + 2))")"

    printf '%b' "${COLOR_RESET}"

    printf '\n'
}

############################################################
# Get the current directory short name for prompt
############################################################
get_prompt_path()
{
    local PWD="$1"
    
    # If in home directory, show ~
    if [[ "$PWD" == "$HOME" ]]; then
        echo "~"
    else
        # Show the last component of the path
        basename "$PWD"
    fi
}

