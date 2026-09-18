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
azterm_vis_len()
{
    local STR="$1"
    local CLEAN
    CLEAN=$(printf '%s' "$STR" | sed -E $'s/\[[0-9;]*[a-zA-Z]//g' | tr -d '\200-\277')
    printf '%s' "${#CLEAN}"
}

############################################################
# Generate exact space padding.
############################################################
azterm_pad_spaces()
{
    local COUNT="$1"
    if (( COUNT > 0 )); then
        printf '%*s' "$COUNT" ''
    fi
}

############################################################
# Shorten a filesystem path to fit inside a column cleanly.
############################################################
azterm_shorten_path()
{
    local P="$1"
    local MAX="${2:-22}"

    if [[ "$P" == "$HOME"* ]]; then
        local T="~${P#$HOME}"
        if (( ${#T} <= MAX )); then
            printf '%s' "$T"
            return 0
        fi
    fi

    if (( ${#P} <= MAX )); then
        printf '%s' "$P"
        return 0
    fi

    local BASE PARENT SHORT
    BASE="$(basename "$P")"
    PARENT="$(basename "$(dirname "$P")")"
    SHORT=".../$PARENT/$BASE"
    if (( ${#SHORT} <= MAX )); then
        printf '%s' "$SHORT"
        return 0
    fi

    SHORT=".../$BASE"
    if (( ${#SHORT} <= MAX )); then
        printf '%s' "$SHORT"
        return 0
    fi

    azterm_trim_text "$P" "$MAX"
}

############################################################
# Truncate text safely to fit inside a fixed-width column.
############################################################
azterm_trim_text()
{
    local TEXT="$1"
    local WIDTH="$2"
    local VLEN
    VLEN="$(azterm_vis_len "$TEXT")"

    if (( VLEN <= WIDTH )); then
        printf '%s' "$TEXT"
        return 0
    fi

    if (( WIDTH <= 1 )); then
        printf '…'
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
        local EMPTY_WIDTH=$((BOX_WIDTH - 2))

        if (( ${#EMPTY_MSG} > EMPTY_WIDTH )); then
            EMPTY_MSG="$(azterm_trim_text "$EMPTY_MSG" "$EMPTY_WIDTH")"
        fi

        local pad=$(( EMPTY_WIDTH - ${#EMPTY_MSG} ))
        (( pad < 0 )) && pad=0

        printf '%b' "${COLOR_WHITE}"
        printf '║ %s%*s ║\n' "$EMPTY_MSG" "$pad" ''
        printf '%b' "${COLOR_YELLOW}"
        printf '╚%s╝\n' "$(azterm_repeat_char '═' "$BOX_WIDTH")"
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

    local MAX_CMD=7   # "Command"
    local MAX_FN=13   # "Functionality"
    local MAX_EX=14   # "Syntax Example"

    for row in "${ROWS[@]}"; do
        IFS='|' read -r c f e <<< "$row"
        local clen flen elen
        clen="$(azterm_vis_len "$c")"
        flen="$(azterm_vis_len "$f")"
        elen="$(azterm_vis_len "$e")"
        (( clen > MAX_CMD )) && MAX_CMD=$clen
        (( flen > MAX_FN )) && MAX_FN=$flen
        (( elen > MAX_EX )) && MAX_EX=$elen
    done

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
        FUNCTION_WIDTH=30
        EXAMPLE_WIDTH=22
    fi

    # Ensure columns fit the actual content if terminal space permits
    (( COMMAND_WIDTH < MAX_CMD )) && COMMAND_WIDTH=$MAX_CMD
    (( FUNCTION_WIDTH < MAX_FN )) && FUNCTION_WIDTH=$MAX_FN
    (( EXAMPLE_WIDTH < MAX_EX )) && EXAMPLE_WIDTH=$MAX_EX

    TABLE_WIDTH=$((COMMAND_WIDTH + FUNCTION_WIDTH + EXAMPLE_WIDTH + 9))

    if (( TABLE_WIDTH > TERM_WIDTH )); then
        local AVAILABLE_WIDTH=$((TERM_WIDTH - 9))
        local MIN_CMD=16
        (( MAX_CMD < MIN_CMD )) && MIN_CMD=$MAX_CMD
        COMMAND_WIDTH=$MIN_CMD

        local REMAINING=$(( AVAILABLE_WIDTH - COMMAND_WIDTH ))
        FUNCTION_WIDTH=$(( REMAINING * 55 / 100 ))
        EXAMPLE_WIDTH=$(( REMAINING - FUNCTION_WIDTH ))
    fi

    printf '\n'
    printf '%b' "${COLOR_YELLOW}"

    printf '╔%s╦%s╦%s╗\n' \
        "$(azterm_repeat_char '═' "$((COMMAND_WIDTH + 2))")" \
        "$(azterm_repeat_char '═' "$((FUNCTION_WIDTH + 2))")" \
        "$(azterm_repeat_char '═' "$((EXAMPLE_WIDTH + 2))")"

    local cpad=$(( COMMAND_WIDTH - 7 ))
    local fpad=$(( FUNCTION_WIDTH - 13 ))
    local epad=$(( EXAMPLE_WIDTH - 14 ))
    (( cpad < 0 )) && cpad=0
    (( fpad < 0 )) && fpad=0
    (( epad < 0 )) && epad=0

    printf '║ %s%*s ║ %s%*s ║ %s%*s ║\n' \
        "Command" "$cpad" '' \
        "Functionality" "$fpad" '' \
        "Syntax Example" "$epad" ''

    printf '╠%s╬%s╬%s╣\n' \
        "$(azterm_repeat_char '═' "$((COMMAND_WIDTH + 2))")" \
        "$(azterm_repeat_char '═' "$((FUNCTION_WIDTH + 2))")" \
        "$(azterm_repeat_char '═' "$((EXAMPLE_WIDTH + 2))")"

    printf '%b' "${COLOR_RESET}"

    for row in "${ROWS[@]}"; do
        IFS='|' read -r COMMAND FUNCTION EXAMPLE <<< "$row"

        COMMAND="$(azterm_trim_text "$COMMAND" "$COMMAND_WIDTH")"
        FUNCTION="$(azterm_trim_text "$FUNCTION" "$FUNCTION_WIDTH")"
        EXAMPLE="$(azterm_trim_text "$EXAMPLE" "$EXAMPLE_WIDTH")"

        local clen flen elen
        clen="$(azterm_vis_len "$COMMAND")"
        flen="$(azterm_vis_len "$FUNCTION")"
        elen="$(azterm_vis_len "$EXAMPLE")"

        local c_spaces="$(azterm_pad_spaces "$((COMMAND_WIDTH - clen))")"
        local f_spaces="$(azterm_pad_spaces "$((FUNCTION_WIDTH - flen))")"
        local e_spaces="$(azterm_pad_spaces "$((EXAMPLE_WIDTH - elen))")"

        printf '%b║%b %s%s %b║%b %s%s %b║%b %s%s %b║%b\n' \
            "${COLOR_YELLOW}" "${COLOR_WHITE}" "$COMMAND" "$c_spaces" \
            "${COLOR_YELLOW}" "${COLOR_WHITE}" "$FUNCTION" "$f_spaces" \
            "${COLOR_YELLOW}" "${COLOR_WHITE}" "$EXAMPLE" "$e_spaces" \
            "${COLOR_YELLOW}" "${COLOR_RESET}"
    done

    printf '%b' "${COLOR_YELLOW}"

    printf '╚%s╩%s╩%s╝\n' \
        "$(azterm_repeat_char '═' "$((COMMAND_WIDTH + 2))")" \
        "$(azterm_repeat_char '═' "$((FUNCTION_WIDTH + 2))")" \
        "$(azterm_repeat_char '═' "$((EXAMPLE_WIDTH + 2))")"

    printf '%b' "${COLOR_RESET}"
    printf '\n'
}

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


############################################################
# Read user command with Readline (Up/Down arrow history)
############################################################
azterm_read_command()
{
    local PROMPT="$1"
    USER_COMMAND=""

    # Enable history for Readline line editing & arrow navigation
    set -o history
    export HISTCONTROL=ignorespace

    # Read user input with Readline (-e)
    # The leading space ensures this read command is ignored by HISTCONTROL
     read -e -r -p "$PROMPT" USER_COMMAND || return 1

    # Disable history while executing internal script commands
    set +o history
    return 0
}
