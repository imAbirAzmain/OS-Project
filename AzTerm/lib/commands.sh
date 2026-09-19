#!/bin/bash

############################################################
# General Built-in Commands
############################################################

############################################################
# Dispatch general commands
# Returns 0 if handled, 1 if not
############################################################
commands_dispatch()
{
    case "$COMMAND" in
        help)
            command_help
            return 0
            ;;
        version)
            command_version
            return 0
            ;;
        clear)
            command_clear
            return 0
            ;;
        exit)
            command_exit
            return 0
            ;;
        run)
            command_run
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

############################################################
# help: Display help information
############################################################
command_help()
{
    local -a HELP_ROWS=(
        "help|Show available commands|help"
        "version|Show AzTerm version|version"
        "clear|Clear terminal screen|clear"
        "exit|Exit AzTerm|exit"
        "go|Change directory|go folder"
        "where am i|Show current directory|where am i"
        "show files|Directory tree|show files"
        "show files|Directory tree with depth|show files --depth 2"
        "make folder|Create a directory|make folder NAME"
        "make file|Create a file|make file NAME"
        "open filename|Display file contents|open file.txt"
        "delete|Delete a file or directory|delete NAME"
        "copy|Copy a file or directory|copy SOURCE DESTINATION"
        "move|Move a file or directory|move SOURCE DESTINATION"
        "run|Execute a program|run PROGRAM [ARGS]"
        "print|Print text in quotes|print \"Abir XOSS\""
        "calc / math|Arithmetic (+,-,*,/) & ++/--|x = 5 + 3 or i++"
        "compare|Relational (>,<,>=,<=,==)|x > 5 or a == b"
        "if condition|Conditional branching|if x > 5 ... end if"
        "for loop|Loop over values|for i=1,2,3,4,5 ... end for"
        "while loop|Conditional loop|while i <= 5 ... end while"
        "history|Show command history|history"
        "script|Execute an AzTerm script|script FILE.az"
        "write script|Open the script editor|write script FILE.az"
        "cloud|Manage Cloudion|cloud start"
        "cloud start|Start Cloudion|cloud start"
        "cloud stop|Stop Cloudion|cloud stop"
        "cloud restart|Restart Cloudion|cloud restart"
        "cloud status|Show Cloudion status|cloud status"
        "cloud storage|Show Cloudion storage|cloud storage"
        "cloud logs|Show recent Cloudion logs|cloud logs"
        "cloud info|Show Cloudion details|cloud info"
        "cloud help|Show Cloudion help|cloud help"
    )

    azterm_print_help_table "${HELP_ROWS[@]}"
}

############################################################
# version: Show AzTerm version
############################################################
command_version()
{
    echo
    echo "$AZTERM_NAME v$AZTERM_VERSION"
    echo "A custom Linux shell written in Bash"
    echo
}

############################################################
# clear: Clear the terminal screen
############################################################
command_clear()
{
    clear
}

############################################################
# exit: Exit AzTerm
############################################################
command_exit()
{
    echo
    echo "Goodbye."
    echo
    exit 0
}

############################################################
# run: Execute a program
# Syntax: run <program>
#         run <program> arg1 arg2 ...
############################################################
command_run()
{
    if [[ $ARG_COUNT -lt 1 ]]; then
        echo
        echo "Error: Missing program name."
        echo "Usage:"
        echo "  run <program> [arguments...]"
        echo
        return 1
    fi

    local PROGRAM="${ARGS[0]}"
    local -a PROGRAM_ARGS=()

    # Collect remaining arguments
    local i
    for ((i = 1; i < ${#ARGS[@]}; i++)); do
        PROGRAM_ARGS+=("${ARGS[$i]}")
    done

    # Check if program exists
    if ! command -v "$PROGRAM" &> /dev/null; then
        echo
        echo "Error: Program not found: $PROGRAM"
        echo
        return 1
    fi

    # Execute the program with arguments
    echo
    "$PROGRAM" "${PROGRAM_ARGS[@]}"
    local EXIT_CODE=$?
    echo
    
    return $EXIT_CODE
}

