#!/bin/bash

############################################################
# AzTerm v2 - Interpreter & Language Module
#
# Implements:
#   1. Variable management (az_set_var, az_get_var)
#   2. print command (with strict double quotes and variable interpolation)
#   3. Basic mathematical operations:
#      +, -, *, /, ++, --, >, <, >=, <=, ==
#   4. Variable assignments (x = 5 + 3, x = "val")
#   5. Standalone calculation command (calc) & direct math
#   6. Condition evaluation (for if and while statements)
#   7. Control flow execution engine:
#      - if ... else if ... else ... end if
#      - for var=1,2,3,4,5 ... end for
#      - while condition ... end while
############################################################

# Dynamic variable store compatible with Bash 3.2+
# Variables are stored as AZ_VAR_<NAME> and exported to environment

############################################################
# Variable Management
############################################################

az_var_valid_name()
{
    local NAME="$1"
    [[ "$NAME" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]
}

az_set_var()
{
    local NAME="$1"
    local VALUE="$2"

    if ! az_var_valid_name "$NAME"; then
        echo "Error: Invalid variable name '$NAME'."
        return 1
    fi

    printf -v "AZ_VAR_${NAME}" '%s' "$VALUE"
    export "$NAME"="$VALUE"
    return 0
}

az_get_var()
{
    local NAME="$1"
    local INTERNAL_NAME="AZ_VAR_${NAME}"

    if [[ -n "${!INTERNAL_NAME+x}" ]]; then
        echo "${!INTERNAL_NAME}"
    elif [[ -n "${!NAME+x}" ]]; then
        echo "${!NAME}"
    else
        echo ""
    fi
}

############################################################
# String Interpolation ($var and ${var})
############################################################
az_interpolate_string()
{
    local STR="$1"
    local RESULT=""
    local i=0
    local LEN=${#STR}

    while (( i < LEN )); do
        local CHAR="${STR:$i:1}"
        if [[ "$CHAR" == '$' ]]; then
            ((i++))
            if (( i >= LEN )); then
                RESULT+='$'
                break
            fi
            local NEXT_CHAR="${STR:$i:1}"
            local VAR_NAME=""
            if [[ "$NEXT_CHAR" == '{' ]]; then
                ((i++))
                while (( i < LEN )) && [[ "${STR:$i:1}" != '}' ]]; do
                    VAR_NAME+="${STR:$i:1}"
                    ((i++))
                done
                if (( i < LEN )) && [[ "${STR:$i:1}" == '}' ]]; then
                    ((i++))
                fi
            elif [[ "$NEXT_CHAR" =~ [a-zA-Z_] ]]; then
                VAR_NAME+="$NEXT_CHAR"
                ((i++))
                while (( i < LEN )) && [[ "${STR:$i:1}" =~ [a-zA-Z0-9_] ]]; do
                    VAR_NAME+="${STR:$i:1}"
                    ((i++))
                done
            else
                RESULT+="$CHAR$NEXT_CHAR"
                ((i++))
                continue
            fi

            local VAL
            VAL="$(az_get_var "$VAR_NAME")"
            RESULT+="$VAL"
        else
            RESULT+="$CHAR"
            ((i++))
        fi
    done

    printf '%s' "$RESULT"
}

############################################################
# Command: print
# Syntax: print "text"
# Strictly enforces double quotes around what to print.
############################################################
command_print()
{
    local RAW_INPUT="${USER_INPUT:-$*}"

    # Trim leading whitespace
    local TRIMMED
    TRIMMED="$(echo "$RAW_INPUT" | sed -E 's/^[[:space:]]+//')"

    # Check command name
    if [[ ! "$TRIMMED" =~ ^print([[:space:]]|$) ]]; then
        echo "Error: Unknown print syntax."
        return 1
    fi

    local ARGS_PART
    ARGS_PART="$(echo "$TRIMMED" | sed -E 's/^print[[:space:]]*//')"

    # Check if empty
    if [[ -z "$ARGS_PART" ]]; then
        echo "Error: Missing text to print."
        echo "Usage:"
        echo "  print \"message\""
        return 1
    fi

    # Trim trailing whitespace
    ARGS_PART="$(echo "$ARGS_PART" | sed -E 's/[[:space:]]+$//')"

    # Check double quote enclosure
    if [[ "${ARGS_PART:0:1}" != '"' ]]; then
        echo "Error: Text to print must be enclosed in double quotes."
        echo "Usage:"
        echo "  print \"message\""
        return 1
    fi

    if (( ${#ARGS_PART} < 2 )) || [[ "${ARGS_PART: -1}" != '"' ]]; then
        echo "Error: Unterminated double quote in print statement."
        echo "Usage:"
        echo "  print \"message\""
        return 1
    fi

    # Extract content inside outer double quotes
    local CONTENT="${ARGS_PART:1:${#ARGS_PART}-2}"

    # Perform variable interpolation
    local EXPANDED
    EXPANDED="$(az_interpolate_string "$CONTENT")"

    # Print the output
    printf '%s\n' "$EXPANDED"
    return 0
}

############################################################
# Mathematical Expression Evaluator
# Supports: +, -, *, /, ++, --, >, <, >=, <=, ==
############################################################

# Check for division by zero pattern in an expression
az_has_div_by_zero()
{
    local EXPR="$1"
    # Matches / 0 followed by space, operator, parenthesis or end of string
    if [[ "$EXPR" =~ /[[:space:]]*0([[:space:]]|$|[^0-9\.]) ]]; then
        return 0
    fi
    return 1
}

# Resolve variables in mathematical expression
az_resolve_math_vars()
{
    local EXPR="$1"
    local RESOLVED=""
    local TOKEN=""
    local i=0
    local LEN=${#EXPR}

    while (( i < LEN )); do
        local CHAR="${EXPR:$i:1}"

        if [[ "$CHAR" =~ [a-zA-Z_] ]]; then
            TOKEN=""
            while (( i < LEN )) && [[ "${EXPR:$i:1}" =~ [a-zA-Z0-9_] ]]; do
                TOKEN+="${EXPR:$i:1}"
                ((i++))
            done
            local VAL
            VAL="$(az_get_var "$TOKEN")"
            if [[ -z "$VAL" ]]; then
                VAL=0
            fi
            RESOLVED+="$VAL"
        elif [[ "$CHAR" == '$' ]]; then
            ((i++))
            TOKEN=""
            while (( i < LEN )) && [[ "${EXPR:$i:1}" =~ [a-zA-Z0-9_] ]]; do
                TOKEN+="${EXPR:$i:1}"
                ((i++))
            done
            local VAL
            VAL="$(az_get_var "$TOKEN")"
            if [[ -z "$VAL" ]]; then
                VAL=0
            fi
            RESOLVED+="$VAL"
        else
            RESOLVED+="$CHAR"
            ((i++))
        fi
    done

    echo "$RESOLVED"
}

# Evaluate a mathematical or comparison expression
# Returns output in global AZ_MATH_RESULT and return code 0 on success, 1 on error
AZ_MATH_RESULT=""
az_eval_math()
{
    local RAW_EXPR="$1"
    AZ_MATH_RESULT=""

    if [[ -z "$RAW_EXPR" ]]; then
        echo "Error: Missing mathematical expression."
        return 1
    fi

    # Check division by zero before evaluation
    if az_has_div_by_zero "$RAW_EXPR"; then
        echo "Error: Division by zero."
        return 1
    fi

    # Resolve variables inside expression
    local RESOLVED_EXPR
    RESOLVED_EXPR="$(az_resolve_math_vars "$RAW_EXPR")"

    # Double check division by zero after variable resolution
    if az_has_div_by_zero "$RESOLVED_EXPR"; then
        echo "Error: Division by zero."
        return 1
    fi

    # Evaluate using bash arithmetic expansion
    local EVAL_OUT
    local EVAL_ERR
    EVAL_OUT=$(bash -c "echo \$(( $RESOLVED_EXPR ))" 2>&1)
    local STATUS=$?

    if [[ $STATUS -ne 0 ]] || [[ "$EVAL_OUT" =~ (error|syntax|division) ]]; then
        if [[ "$EVAL_OUT" =~ division[[:space:]]by[[:space:]]0 ]]; then
            echo "Error: Division by zero."
        else
            echo "Error: Invalid mathematical expression: '$RAW_EXPR'."
        fi
        return 1
    fi

    AZ_MATH_RESULT="$EVAL_OUT"
    return 0
}

############################################################
# Condition Evaluator
# Supports:
#   Numeric & comparison: >, <, >=, <=, ==, !=
#   String equality: "str1" == "str2" or var == "str"
############################################################
az_eval_condition()
{
    local COND="$1"
    COND="$(echo "$COND" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')"

    if [[ -z "$COND" ]]; then
        echo "Error: Missing condition expression."
        return 2
    fi

    # Check for string comparison with quotes
    if [[ "$COND" =~ ^(.*)[[:space:]]*(==|!=)[[:space:]]*(.*)$ ]]; then
        local LHS="${BASH_REMATCH[1]}"
        local OP="${BASH_REMATCH[2]}"
        local RHS="${BASH_REMATCH[3]}"
        LHS="$(echo "$LHS" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')"
        RHS="$(echo "$RHS" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')"

        # If either side is quoted, perform string comparison
        if [[ "$LHS" =~ ^(\".*\"|\'.*\')$ ]] || [[ "$RHS" =~ ^(\".*\"|\'.*\')$ ]]; then
            # Strip quotes and expand
            local LHS_VAL="$LHS"
            local RHS_VAL="$RHS"
            if [[ "$LHS_VAL" =~ ^\"(.*)\"$ ]]; then LHS_VAL="${BASH_REMATCH[1]}"; fi
            if [[ "$RHS_VAL" =~ ^\"(.*)\"$ ]]; then RHS_VAL="${BASH_REMATCH[1]}"; fi
            LHS_VAL="$(az_interpolate_string "$LHS_VAL")"
            RHS_VAL="$(az_interpolate_string "$RHS_VAL")"

            if [[ "$OP" == "==" ]]; then
                [[ "$LHS_VAL" == "$RHS_VAL" ]] && return 0 || return 1
            else
                [[ "$LHS_VAL" != "$RHS_VAL" ]] && return 0 || return 1
            fi
        fi
    fi

    # Evaluate as numeric / relational expression
    if ! az_eval_math "$COND"; then
        return 2
    fi

    if (( AZ_MATH_RESULT != 0 )); then
        return 0
    else
        return 1
    fi
}

############################################################
# Variable Increment / Decrement (++ / --)
# Syntax: var++, ++var, var--, --var
############################################################
az_handle_inc_dec()
{
    local CMD="$1"
    CMD="$(echo "$CMD" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')"

    local VAR_NAME=""
    local OP=""

    if [[ "$CMD" =~ ^([a-zA-Z_][a-zA-Z0-9_]*)\+\+$ ]]; then
        VAR_NAME="${BASH_REMATCH[1]}"
        OP="inc"
    elif [[ "$CMD" =~ ^\+\+([a-zA-Z_][a-zA-Z0-9_]*)$ ]]; then
        VAR_NAME="${BASH_REMATCH[1]}"
        OP="inc"
    elif [[ "$CMD" =~ ^([a-zA-Z_][a-zA-Z0-9_]*)\-\-$ ]]; then
        VAR_NAME="${BASH_REMATCH[1]}"
        OP="dec"
    elif [[ "$CMD" =~ ^\-\-([a-zA-Z_][a-zA-Z0-9_]*)$ ]]; then
        VAR_NAME="${BASH_REMATCH[1]}"
        OP="dec"
    else
        return 1
    fi

    local CURR_VAL
    CURR_VAL="$(az_get_var "$VAR_NAME")"
    if [[ -z "$CURR_VAL" ]]; then
        CURR_VAL=0
    fi

    if ! [[ "$CURR_VAL" =~ ^-?[0-9]+$ ]]; then
        echo "Error: Cannot increment/decrement non-numeric variable '$VAR_NAME' (value: '$CURR_VAL')."
        return 2
    fi

    local NEW_VAL
    if [[ "$OP" == "inc" ]]; then
        NEW_VAL=$(( CURR_VAL + 1 ))
    else
        NEW_VAL=$(( CURR_VAL - 1 ))
    fi

    az_set_var "$VAR_NAME" "$NEW_VAL"
    return 0
}

############################################################
# Variable Assignment
# Syntax: var = expr  or  var="string"
############################################################
az_handle_assignment()
{
    local CMD="$1"
    CMD="$(echo "$CMD" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')"

    # Check for assignment pattern: candidate = value
    if [[ ! "$CMD" =~ ^([^=[:space:]]+)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
        return 1
    fi

    local VAR_NAME="${BASH_REMATCH[1]}"
    local VALUE_EXPR="${BASH_REMATCH[2]}"

    if ! az_var_valid_name "$VAR_NAME"; then
        echo "Error: Invalid variable name '$VAR_NAME'. Variable names must start with a letter or underscore."
        return 2
    fi

    if [[ -z "$VALUE_EXPR" ]]; then
        echo "Error: Missing value for assignment to '$VAR_NAME'."
        return 2
    fi

    # If value is a double-quoted string
    if [[ "$VALUE_EXPR" =~ ^\"(.*)\"$ ]]; then
        local STR_VAL="${BASH_REMATCH[1]}"
        STR_VAL="$(az_interpolate_string "$STR_VAL")"
        az_set_var "$VAR_NAME" "$STR_VAL"
        return 0
    fi

    # If value is a single-quoted string
    if [[ "$VALUE_EXPR" =~ ^\'(.*)\'$ ]]; then
        local STR_VAL="${BASH_REMATCH[1]}"
        az_set_var "$VAR_NAME" "$STR_VAL"
        return 0
    fi

    # Evaluate as mathematical expression
    if ! az_eval_math "$VALUE_EXPR"; then
        return 2
    fi

    az_set_var "$VAR_NAME" "$AZ_MATH_RESULT"
    return 0
}

############################################################
# Standalone Calculation: calc <expr> or direct math
############################################################
command_calc()
{
    local EXPR="$*"
    if [[ -z "$EXPR" ]]; then
        echo "Error: Missing mathematical expression."
        echo "Usage:"
        echo "  calc <expression>"
        echo "  Examples: calc 5 + 3, calc 10 > 2, calc 5 == 5"
        return 1
    fi

    if ! az_eval_math "$EXPR"; then
        return 1
    fi

    # If expression contains comparison operators, display boolean representation
    if [[ "$EXPR" =~ (==|!=|>=|<=|>|<) ]]; then
        if (( AZ_MATH_RESULT != 0 )); then
            echo "true"
        else
            echo "false"
        fi
    else
        echo "$AZ_MATH_RESULT"
    fi
    return 0
}

############################################################
# Block Execution Engine
# Handles:
#   if <cond> ... else if <cond> ... else ... end if
#   for <var>=<val1>,<val2>,... ... end for
#   while <cond> ... end while
############################################################

# Check if a line opens a block
az_is_block_start()
{
    local LINE="$1"
    LINE="$(echo "$LINE" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')"

    if [[ "$LINE" =~ ^if([[:space:]]|$) ]] && ! [[ "$LINE" =~ [[:space:]]end[[:space:]]+if([[:space:]]|$) ]]; then
        echo "if"
        return 0
    fi
    if [[ "$LINE" =~ ^for([[:space:]]|$) ]] && ! [[ "$LINE" =~ [[:space:]]end[[:space:]]+for([[:space:]]|$) ]]; then
        echo "for"
        return 0
    fi
    if [[ "$LINE" =~ ^while([[:space:]]|$) ]] && ! [[ "$LINE" =~ [[:space:]]end[[:space:]]+while([[:space:]]|$) ]]; then
        echo "while"
        return 0
    fi
    return 1
}

# Check if a line closes a block
az_is_block_end()
{
    local LINE="$1"
    LINE="$(echo "$LINE" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')"

    if [[ "$LINE" == "end if" || "$LINE" == "endif" || "$LINE" == "fi" ]]; then
        echo "if"
        return 0
    fi
    if [[ "$LINE" == "end for" || "$LINE" == "endfor" || "$LINE" == "done" ]]; then
        echo "for"
        return 0
    fi
    if [[ "$LINE" == "end while" || "$LINE" == "endwhile" ]]; then
        echo "while"
        return 0
    fi
    return 1
}

# Execute a single AzTerm command line
az_exec_single_line()
{
    local LINE="$1"
    LINE="$(echo "$LINE" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')"

    if [[ -z "$LINE" ]] || [[ "$LINE" =~ ^# ]]; then
        return 0
    fi

    # Check for variable assignment: x = 5 + 3
    az_handle_assignment "$LINE"
    local ASSIGN_RES=$?
    if [[ $ASSIGN_RES -eq 0 ]]; then
        return 0
    elif [[ $ASSIGN_RES -eq 2 ]]; then
        return 1
    fi

    # Check for increment/decrement: i++ or i--
    az_handle_inc_dec "$LINE"
    local INC_RES=$?
    if [[ $INC_RES -eq 0 ]]; then
        return 0
    elif [[ $INC_RES -eq 2 ]]; then
        return 1
    fi

    # Check for direct calculation: 5 + 3 or 10 > 2
    if [[ "$LINE" =~ ^[0-9]+[[:space:]]*(\+|\-|\*|\/|>|<|>=|<=|==)[[:space:]]* ]]; then
        command_calc "$LINE"
        return $?
    fi

    # Standard dispatch through parse_command
    parse_command "$LINE"
    return $?
}

# Execute an array of script lines
az_execute_block_lines()
{
    local -a BLOCK_LINES=("$@")
    local TOTAL_LINES=${#BLOCK_LINES[@]}
    local i=0

    while (( i < TOTAL_LINES )); do
        local RAW_LINE="${BLOCK_LINES[$i]}"
        local LINE
        LINE="$(echo "$RAW_LINE" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')"

        # Skip empty lines and comments
        if [[ -z "$LINE" ]] || [[ "$LINE" =~ ^# ]]; then
            ((i++))
            continue
        fi

        # ----------------------------------------------------
        # 1. Handle IF Block
        # ----------------------------------------------------
        if [[ "$LINE" =~ ^if([[:space:]]|$) ]]; then
            local IF_START_INDEX=$i
            local IF_COND="${LINE#if}"
            IF_COND="$(echo "$IF_COND" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')"

            if [[ -z "$IF_COND" ]]; then
                echo "Error: Missing condition in 'if' statement."
                echo "Usage: if <condition>"
                return 1
            fi

            # Scan forward to find branches (else if, else, end if)
            local DEPTH=1
            local j=$(( i + 1 ))
            local -a BRANCH_CONDITIONS=("$IF_COND")
            local -a BRANCH_START_INDICES=($(( i + 1 )))
            local -a BRANCH_TYPES=("if")
            local END_IF_INDEX=-1

            while (( j < TOTAL_LINES )); do
                local SCAN_LINE="${BLOCK_LINES[$j]}"
                SCAN_LINE="$(echo "$SCAN_LINE" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')"

                if [[ "$SCAN_LINE" =~ ^if([[:space:]]|$) ]]; then
                    ((DEPTH++))
                elif [[ "$SCAN_LINE" == "end if" || "$SCAN_LINE" == "endif" || "$SCAN_LINE" == "fi" ]]; then
                    ((DEPTH--))
                    if (( DEPTH == 0 )); then
                        END_IF_INDEX=$j
                        break
                    fi
                elif (( DEPTH == 1 )); then
                    if [[ "$SCAN_LINE" =~ ^else[[:space:]]+if([[:space:]]|$) ]] || [[ "$SCAN_LINE" =~ ^elif([[:space:]]|$) ]]; then
                        local ELIF_COND
                        if [[ "$SCAN_LINE" =~ ^else[[:space:]]+if ]]; then
                            ELIF_COND="${SCAN_LINE#else if}"
                        else
                            ELIF_COND="${SCAN_LINE#elif}"
                        fi
                        ELIF_COND="$(echo "$ELIF_COND" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')"
                        BRANCH_CONDITIONS+=("$ELIF_COND")
                        BRANCH_START_INDICES+=($(( j + 1 )))
                        BRANCH_TYPES+=("elif")
                    elif [[ "$SCAN_LINE" == "else" ]]; then
                        BRANCH_CONDITIONS+=("true")
                        BRANCH_START_INDICES+=($(( j + 1 )))
                        BRANCH_TYPES+=("else")
                    fi
                fi
                ((j++))
            done

            if (( END_IF_INDEX == -1 )); then
                echo "Error: Syntax error: Missing 'end if' for 'if' statement."
                return 1
            fi

            # Determine which branch to execute
            local NUM_BRANCHES=${#BRANCH_CONDITIONS[@]}
            local EXECUTED_BRANCH=false
            local b

            for (( b = 0; b < NUM_BRANCHES; b++ )); do
                local B_COND="${BRANCH_CONDITIONS[$b]}"
                local COND_MET=false

                if [[ "${BRANCH_TYPES[$b]}" == "else" ]]; then
                    COND_MET=true
                else
                    az_eval_condition "$B_COND"
                    local COND_STATUS=$?
                    if [[ $COND_STATUS -eq 0 ]]; then
                        COND_MET=true
                    elif [[ $COND_STATUS -eq 2 ]]; then
                        return 1
                    fi
                fi

                if [[ "$COND_MET" == true ]]; then
                    # Collect lines belonging to this branch
                    local B_START="${BRANCH_START_INDICES[$b]}"
                    local B_END
                    if (( b + 1 < NUM_BRANCHES )); then
                        B_END=$(( BRANCH_START_INDICES[b + 1] - 2 ))
                    else
                        B_END=$(( END_IF_INDEX - 1 ))
                    fi

                    local -a BRANCH_LINES=()
                    local k
                    for (( k = B_START; k <= B_END; k++ )); do
                        BRANCH_LINES+=("${BLOCK_LINES[$k]}")
                    done

                    if (( ${#BRANCH_LINES[@]} > 0 )); then
                        az_execute_block_lines "${BRANCH_LINES[@]}"
                        local B_RES=$?
                        if [[ $B_RES -ne 0 ]]; then return $B_RES; fi
                    fi

                    EXECUTED_BRANCH=true
                    break
                fi
            done

            i=$(( END_IF_INDEX + 1 ))
            continue

        # ----------------------------------------------------
        # 2. Handle FOR Loop: for var=1,2,3,4,5 ... end for
        # ----------------------------------------------------
        elif [[ "$LINE" =~ ^for([[:space:]]|$) ]]; then
            local FOR_HEADER="${LINE#for}"
            FOR_HEADER="$(echo "$FOR_HEADER" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')"

            # Validate header format: var=val1,val2,... or var = 1..5
            if [[ ! "$FOR_HEADER" =~ ^([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
                echo "Error: Invalid 'for' loop syntax."
                echo "Usage:"
                echo "  for <var>=<val1>,<val2>,..."
                echo "  Example: for i=1,2,3,4,5"
                return 1
            fi

            local FOR_VAR="${BASH_REMATCH[1]}"
            local FOR_VALS_RAW="${BASH_REMATCH[2]}"

            if [[ -z "$FOR_VALS_RAW" ]]; then
                echo "Error: Empty values list in 'for' loop."
                return 1
            fi

            # Scan forward to find matching end for
            local DEPTH=1
            local j=$(( i + 1 ))
            local END_FOR_INDEX=-1

            while (( j < TOTAL_LINES )); do
                local SCAN_LINE="${BLOCK_LINES[$j]}"
                SCAN_LINE="$(echo "$SCAN_LINE" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')"

                if [[ "$SCAN_LINE" =~ ^for([[:space:]]|$) ]]; then
                    ((DEPTH++))
                elif [[ "$SCAN_LINE" == "end for" || "$SCAN_LINE" == "endfor" || "$SCAN_LINE" == "done" ]]; then
                    ((DEPTH--))
                    if (( DEPTH == 0 )); then
                        END_FOR_INDEX=$j
                        break
                    fi
                fi
                ((j++))
            done

            if (( END_FOR_INDEX == -1 )); then
                echo "Error: Syntax error: Missing 'end for' for 'for' loop."
                return 1
            fi

            # Parse the values list
            local -a VALUES=()
            # Check for range: 1..5
            if [[ "$FOR_VALS_RAW" =~ ^([0-9]+)\.\.([0-9]+)$ ]]; then
                local R_START="${BASH_REMATCH[1]}"
                local R_END="${BASH_REMATCH[2]}"
                local r
                for (( r = R_START; r <= R_END; r++ )); do
                    VALUES+=("$r")
                done
            else
                # Comma separated
                IFS=',' read -ra RAW_ARR <<< "$FOR_VALS_RAW"
                for item in "${RAW_ARR[@]}"; do
                    item="$(echo "$item" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')"
                    if [[ -n "$item" ]]; then
                        VALUES+=("$item")
                    fi
                done
            fi

            # Extract body lines
            local -a BODY_LINES=()
            local k
            for (( k = i + 1; k < END_FOR_INDEX; k++ )); do
                BODY_LINES+=("${BLOCK_LINES[$k]}")
            done

            # Execute loop
            for val in "${VALUES[@]}"; do
                az_set_var "$FOR_VAR" "$val"
                if (( ${#BODY_LINES[@]} > 0 )); then
                    az_execute_block_lines "${BODY_LINES[@]}"
                    local L_RES=$?
                    if [[ $L_RES -ne 0 ]]; then return $L_RES; fi
                fi
            done

            i=$(( END_FOR_INDEX + 1 ))
            continue

        # ----------------------------------------------------
        # 3. Handle WHILE Loop: while cond ... end while
        # ----------------------------------------------------
        elif [[ "$LINE" =~ ^while([[:space:]]|$) ]]; then
            local WHILE_COND="${LINE#while}"
            WHILE_COND="$(echo "$WHILE_COND" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')"

            if [[ -z "$WHILE_COND" ]]; then
                echo "Error: Missing condition in 'while' statement."
                echo "Usage:"
                echo "  while <condition>"
                echo "  Example: while i <= 5"
                return 1
            fi

            # Scan forward to find matching end while
            local DEPTH=1
            local j=$(( i + 1 ))
            local END_WHILE_INDEX=-1

            while (( j < TOTAL_LINES )); do
                local SCAN_LINE="${BLOCK_LINES[$j]}"
                SCAN_LINE="$(echo "$SCAN_LINE" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')"

                if [[ "$SCAN_LINE" =~ ^while([[:space:]]|$) ]]; then
                    ((DEPTH++))
                elif [[ "$SCAN_LINE" == "end while" || "$SCAN_LINE" == "endwhile" ]]; then
                    ((DEPTH--))
                    if (( DEPTH == 0 )); then
                        END_WHILE_INDEX=$j
                        break
                    fi
                fi
                ((j++))
            done

            if (( END_WHILE_INDEX == -1 )); then
                echo "Error: Syntax error: Missing 'end while' for 'while' loop."
                return 1
            fi

            # Extract body lines
            local -a BODY_LINES=()
            local k
            for (( k = i + 1; k < END_WHILE_INDEX; k++ )); do
                BODY_LINES+=("${BLOCK_LINES[$k]}")
            done

            # Loop safety limit to prevent infinite loops
            local ITER_COUNT=0
            local MAX_ITER=100000

            while true; do
                az_eval_condition "$WHILE_COND"
                local C_STATUS=$?
                if [[ $C_STATUS -eq 2 ]]; then
                    return 1
                elif [[ $C_STATUS -ne 0 ]]; then
                    break
                fi

                ((ITER_COUNT++))
                if (( ITER_COUNT > MAX_ITER )); then
                    echo "Error: Maximum iteration limit ($MAX_ITER) exceeded in while loop. Possible infinite loop."
                    return 1
                fi

                if (( ${#BODY_LINES[@]} > 0 )); then
                    az_execute_block_lines "${BODY_LINES[@]}"
                    local W_RES=$?
                    if [[ $W_RES -ne 0 ]]; then return $W_RES; fi
                fi
            done

            i=$(( END_WHILE_INDEX + 1 ))
            continue

        # ----------------------------------------------------
        # 4. Stray block endings
        # ----------------------------------------------------
        elif [[ "$LINE" == "end if" || "$LINE" == "endif" ]]; then
            echo "Error: 'end if' without matching 'if'."
            return 1
        elif [[ "$LINE" == "end for" || "$LINE" == "endfor" ]]; then
            echo "Error: 'end for' without matching 'for'."
            return 1
        elif [[ "$LINE" == "end while" || "$LINE" == "endwhile" ]]; then
            echo "Error: 'end while' without matching 'while'."
            return 1
        elif [[ "$LINE" =~ ^else([[:space:]]|$) ]]; then
            echo "Error: 'else' without matching 'if'."
            return 1

        # ----------------------------------------------------
        # 5. Standard single statement execution
        # ----------------------------------------------------
        else
            az_exec_single_line "$LINE"
            local S_RES=$?
            if [[ $S_RES -ne 0 ]]; then
                return $S_RES
            fi
            ((i++))
        fi
    done

    return 0
}

############################################################
# Dispatch interpreter commands
# Returns 0 if handled, 1 if not
############################################################
interpreter_dispatch()
{
    # 1. Print command
    if [[ "$COMMAND" == "print" ]]; then
        command_print "$USER_INPUT"
        return 0
    fi

    # 2. Standalone calc command
    if [[ "$COMMAND" == "calc" ]]; then
        local CALC_ARGS=""
        local a
        for a in "${ARGS[@]}"; do
            CALC_ARGS+="$a "
        done
        command_calc "$CALC_ARGS"
        return 0
    fi

    # 3. Increment / Decrement: x++, x--, ++x, --x
    az_handle_inc_dec "$USER_INPUT"
    local INC_DEC_RES=$?
    if [[ $INC_DEC_RES -eq 0 ]]; then
        return 0
    elif [[ $INC_DEC_RES -eq 2 ]]; then
        return 0 # Handled with error output
    fi

    # 4. Variable assignment: x = 5 + 3 or x = "val"
    az_handle_assignment "$USER_INPUT"
    local ASSIGN_RES=$?
    if [[ $ASSIGN_RES -eq 0 ]]; then
        return 0
    elif [[ $ASSIGN_RES -eq 2 ]]; then
        return 0 # Handled with error output
    fi

    # 5. Direct standalone math: e.g. 5 + 3, 10 > 2, 5 == 5
    if [[ "$USER_INPUT" =~ ^[0-9]+[[:space:]]*(\+|\-|\*|\/|>|<|>=|<=|==)[[:space:]]* ]]; then
        command_calc "$USER_INPUT"
        return 0
    fi

    # 6. Inline single-line control structures if separated by ';'
    if [[ "$USER_INPUT" =~ (if|for|while)[[:space:]] ]] && [[ "$USER_INPUT" =~ (end[[:space:]]+(if|for|while)|endif|endfor|endwhile) ]]; then
        local -a INLINE_LINES=()
        IFS=';' read -ra PARTS <<< "$USER_INPUT"
        for p in "${PARTS[@]}"; do
            p="$(echo "$p" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')"
            if [[ -n "$p" ]]; then
                INLINE_LINES+=("$p")
            fi
        done
        az_execute_block_lines "${INLINE_LINES[@]}"
        return 0
    fi

    # 7. Catch stray block endings and keywords
    local TRIMMED_INPUT
    TRIMMED_INPUT="$(echo "$USER_INPUT" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')"
    if [[ "$TRIMMED_INPUT" == "end if" || "$TRIMMED_INPUT" == "endif" ]]; then
        echo "Error: 'end if' without matching 'if'."
        return 0
    elif [[ "$TRIMMED_INPUT" == "end for" || "$TRIMMED_INPUT" == "endfor" ]]; then
        echo "Error: 'end for' without matching 'for'."
        return 0
    elif [[ "$TRIMMED_INPUT" == "end while" || "$TRIMMED_INPUT" == "endwhile" ]]; then
        echo "Error: 'end while' without matching 'while'."
        return 0
    elif [[ "$TRIMMED_INPUT" =~ ^else([[:space:]]|$) ]]; then
        echo "Error: 'else' without matching 'if'."
        return 0
    elif [[ "$TRIMMED_INPUT" == "if" ]]; then
        echo "Error: Missing condition in 'if' statement."
        echo "Usage: if <condition>"
        return 0
    elif [[ "$TRIMMED_INPUT" == "for" ]]; then
        echo "Error: Invalid 'for' loop syntax."
        echo "Usage: for <var>=<val1>,<val2>,..."
        return 0
    elif [[ "$TRIMMED_INPUT" == "while" ]]; then
        echo "Error: Missing condition in 'while' statement."
        echo "Usage: while <condition>"
        return 0
    fi

    return 1
}
