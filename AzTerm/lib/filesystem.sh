#!/bin/bash

############################################################
# File System Module
############################################################

# Current working directory (stored in AzTerm context)
AZTERM_PWD="$PWD"

############################################################
# Dispatch filesystem commands
# Returns 0 if handled, 1 if not
############################################################
filesystem_dispatch()
{
    case "$COMMAND" in
        go)
            filesystem_go
            return 0
            ;;
        where)
            # "where am i" - the "where" is the command
            if [[ "${ARGS[0]}" == "am" ]] && [[ "${ARGS[1]}" == "i" ]]; then
                filesystem_where_am_i
                return 0
            fi
            return 1
            ;;
        show)
            filesystem_show
            return 0
            ;;
        make)
            filesystem_make
            return 0
            ;;
        delete)
            filesystem_delete
            return 0
            ;;
        copy)
            filesystem_copy
            return 0
            ;;
        move)
            filesystem_move
            return 0
            ;;
        open)
            filesystem_open
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

############################################################
# go: Change directory
# Syntax: go <folder>
#         go ..
#         go ~
############################################################
filesystem_go()
{
    # No arguments provided
    if [[ $ARG_COUNT -eq 0 ]]; then
        echo
        echo "Error: Missing destination folder."
        echo "Usage:"
        echo "  go <folder>    - Change to folder"
        echo "  go ..          - Go to parent directory"
        echo "  go ~           - Go to home directory"
        echo
        return 1
    fi

    local TARGET="${ARGS[0]}"

    # Handle special cases
    if [[ "$TARGET" == ".." ]]; then
        # Go to parent directory
        if cd ..; then
            AZTERM_PWD="$PWD"
            echo
            echo "Changed to: $AZTERM_PWD"
            echo
        else
            echo
            echo "Error: Cannot go to parent directory."
            echo
            return 1
        fi
    elif [[ "$TARGET" == "~" ]]; then
        # Go to home directory
        if cd "$HOME"; then
            AZTERM_PWD="$PWD"
            echo
            echo "Changed to: $AZTERM_PWD"
            echo
        else
            echo
            echo "Error: Cannot go to home directory."
            echo
            return 1
        fi
    else
        # Regular folder change
        if cd "$TARGET"; then
            AZTERM_PWD="$PWD"
            echo
            echo "Changed to: $AZTERM_PWD"
            echo
        else
            echo
            echo "Error: Directory not found: $TARGET"
            echo
            return 1
        fi
    fi
}

############################################################
# where am i: Show current directory
############################################################
filesystem_where_am_i()
{
    echo
    echo "$AZTERM_PWD"
    echo
}

############################################################
# Print a directory tree using Bash and standard utilities.
# Skips hidden entries by default and does not follow symlinks.
############################################################
filesystem_print_tree()
{
    local ROOT_DIR="$1"
    local MAX_DEPTH="$2"
    local PREFIX="$3"
    local DEPTH_LEVEL="$4"

    if [[ ! -d "$ROOT_DIR" ]]; then
        return 1
    fi

    local -a DIRS=()
    local -a FILES=()
    local ENTRY

    while IFS= read -r -d '' ENTRY; do
        local NAME="${ENTRY##*/}"
        if [[ "$NAME" == .* ]]; then
            continue
        fi

        if [[ -L "$ENTRY" ]]; then
            continue
        fi

        if [[ -d "$ENTRY" ]]; then
            DIRS+=("$ENTRY")
        elif [[ -f "$ENTRY" ]]; then
            FILES+=("$ENTRY")
        fi
    done < <(find "$ROOT_DIR" -mindepth 1 -maxdepth 1 ! -name '.*' -print0 2>/dev/null)

    local -a SORTED_DIRS=()
    local -a SORTED_FILES=()

    if [[ ${#DIRS[@]} -gt 0 ]]; then
        while IFS= read -r ENTRY; do
            SORTED_DIRS+=("$ENTRY")
        done < <(printf '%s\n' "${DIRS[@]}" | LC_ALL=C sort)
    fi

    if [[ ${#FILES[@]} -gt 0 ]]; then
        while IFS= read -r ENTRY; do
            SORTED_FILES+=("$ENTRY")
        done < <(printf '%s\n' "${FILES[@]}" | LC_ALL=C sort)
    fi

    local -a ENTRIES=()
    ENTRIES=("${SORTED_DIRS[@]}" "${SORTED_FILES[@]}")

    local TOTAL_ENTRIES=${#ENTRIES[@]}
    local INDEX
    local IS_LAST

    for ((INDEX = 0; INDEX < TOTAL_ENTRIES; INDEX++)); do
        ENTRY="${ENTRIES[$INDEX]}"
        local NAME="${ENTRY##*/}"
        IS_LAST=false
        if (( INDEX == TOTAL_ENTRIES - 1 )); then
            IS_LAST=true
        fi

        local BRANCH
        if [[ "$IS_LAST" == true ]]; then
            BRANCH="└── "
        else
            BRANCH="├── "
        fi

        if [[ -d "$ENTRY" ]]; then
            printf '%s%s%s/\n' "$PREFIX" "$BRANCH" "$NAME"
            if [[ -z "$MAX_DEPTH" ]] || (( DEPTH_LEVEL < MAX_DEPTH )); then
                local CHILD_PREFIX
                if [[ "$IS_LAST" == true ]]; then
                    CHILD_PREFIX="${PREFIX}    "
                else
                    CHILD_PREFIX="${PREFIX}│   "
                fi
                filesystem_print_tree "$ENTRY" "$MAX_DEPTH" "$CHILD_PREFIX" "$((DEPTH_LEVEL + 1))"
            fi
        else
            printf '%s%s%s\n' "$PREFIX" "$BRANCH" "$NAME"
        fi
    done
}

############################################################
# show: Display files/directories
# Syntax: show files
#         show files <folder>
#         show files --depth N
#         show files <folder> --depth N
############################################################
filesystem_show()
{
    if [[ $ARG_COUNT -lt 1 ]] || [[ "${ARGS[0]}" != "files" ]]; then
        echo
        echo "Error: Invalid syntax."
        echo "Usage:"
        echo "  show files                  - List current directory"
        echo "  show files <folder>         - List a specific folder"
        echo "  show files --depth <N>      - List with maximum depth N"
        echo "  show files <folder> --depth <N> - List with depth N"
        echo
        return 1
    fi

    local TARGET_DIR="."
    local DEPTH=""
    local INDEX

    for ((INDEX = 1; INDEX < ARG_COUNT; INDEX++)); do
        case "${ARGS[$INDEX]}" in
            --depth)
                if (( INDEX + 1 >= ARG_COUNT )); then
                    echo
                    echo "Error: Missing depth value."
                    echo
                    return 1
                fi
                DEPTH="${ARGS[$((INDEX + 1))]}"
                if ! [[ "$DEPTH" =~ ^[0-9]+$ ]]; then
                    echo
                    echo "Error: Depth must be a number."
                    echo
                    return 1
                fi
                ((INDEX++))
                ;;
            *)
                if [[ "$TARGET_DIR" == "." ]]; then
                    TARGET_DIR="${ARGS[$INDEX]}"
                else
                    echo
                    echo "Error: Invalid syntax."
                    echo "Usage:"
                    echo "  show files                  - List current directory"
                    echo "  show files <folder>         - List a specific folder"
                    echo "  show files --depth <N>      - List with maximum depth N"
                    echo "  show files <folder> --depth <N> - List with depth N"
                    echo
                    return 1
                fi
                ;;
        esac
    done

    if [[ ! -d "$TARGET_DIR" ]]; then
        echo
        echo "Error: Directory not found: $TARGET_DIR"
        echo
        return 1
    fi

    if [[ ! -r "$TARGET_DIR" ]]; then
        echo
        echo "Error: Permission denied: $TARGET_DIR"
        echo
        return 1
    fi

    local ROOT_NAME
    ROOT_NAME="$(basename "$TARGET_DIR")"
    if [[ -z "$ROOT_NAME" ]]; then
        ROOT_NAME="."
    fi

    echo
    printf '%s/\n' "$ROOT_NAME"

    if [[ -n "$DEPTH" ]]; then
        filesystem_print_tree "$TARGET_DIR" "$DEPTH" "" 0
    else
        filesystem_print_tree "$TARGET_DIR" "" "" 0
    fi

    echo
    return 0
}

############################################################
# make: Create folder or file
# Syntax: make folder <name>
#         make file <name>
############################################################
filesystem_make()
{
    if [[ $ARG_COUNT -lt 2 ]]; then
        echo
        echo "Error: Invalid syntax."
        echo "Usage:"
        echo "  make folder <name>   - Create a folder"
        echo "  make file <name>     - Create a file"
        echo
        return 1
    fi

    local TYPE="${ARGS[0]}"
    local NAME="${ARGS[1]}"

    if [[ "$TYPE" == "folder" ]]; then
        # Create folder
        if [[ -e "$NAME" ]]; then
            echo
            echo "Error: Folder already exists: $NAME"
            echo
            return 1
        fi
        if mkdir "$NAME"; then
            echo
            echo "Folder created: $NAME"
            echo
        else
            echo
            echo "Error: Failed to create folder: $NAME"
            echo
            return 1
        fi
    elif [[ "$TYPE" == "file" ]]; then
        # Create file
        if [[ -e "$NAME" ]]; then
            echo
            echo "Error: File already exists: $NAME"
            echo
            return 1
        fi
        if touch "$NAME"; then
            echo
            echo "File created: $NAME"
            echo
        else
            echo
            echo "Error: Failed to create file: $NAME"
            echo
            return 1
        fi
    else
        echo
        echo "Error: Unknown type '$TYPE'. Use 'folder' or 'file'."
        echo
        return 1
    fi
}

############################################################
# delete: Delete file or directory
# Syntax: delete <name>
############################################################
filesystem_delete()
{
    if [[ $ARG_COUNT -lt 1 ]]; then
        echo
        echo "Error: Missing item to delete."
        echo "Usage:"
        echo "  delete <name>   - Delete file or folder"
        echo
        return 1
    fi

    local TARGET="${ARGS[0]}"

    if [[ ! -e "$TARGET" ]]; then
        echo
        echo "Error: Item not found: $TARGET"
        echo
        return 1
    fi

    if [[ -d "$TARGET" ]]; then
        # It's a directory
        if rm -rf "$TARGET"; then
            echo
            echo "Deleted: $TARGET"
            echo
        else
            echo
            echo "Error: Failed to delete: $TARGET"
            echo
            return 1
        fi
    else
        # It's a file
        if rm "$TARGET"; then
            echo
            echo "Deleted: $TARGET"
            echo
        else
            echo
            echo "Error: Failed to delete: $TARGET"
            echo
            return 1
        fi
    fi
}

############################################################
# copy: Copy file or directory
# Syntax: copy <source> <destination>
############################################################
filesystem_copy()
{
    if [[ $ARG_COUNT -lt 2 ]]; then
        echo
        echo "Error: Missing arguments."
        echo "Usage:"
        echo "  copy <source> <destination>   - Copy file or folder"
        echo
        return 1
    fi

    local SOURCE="${ARGS[0]}"
    local DESTINATION="${ARGS[1]}"

    if [[ ! -e "$SOURCE" ]]; then
        echo
        echo "Error: Source not found: $SOURCE"
        echo
        return 1
    fi

    if [[ -e "$DESTINATION" ]]; then
        echo
        echo "Error: Destination already exists: $DESTINATION"
        echo
        return 1
    fi

    if cp -r "$SOURCE" "$DESTINATION"; then
        echo
        echo "Copied: $SOURCE -> $DESTINATION"
        echo
    else
        echo
        echo "Error: Failed to copy: $SOURCE"
        echo
        return 1
    fi
}

############################################################
# move: Move file or directory
# Syntax: move <source> <destination>
############################################################
filesystem_move()
{
    if [[ $ARG_COUNT -lt 2 ]]; then
        echo
        echo "Error: Missing arguments."
        echo "Usage:"
        echo "  move <source> <destination>   - Move file or folder"
        echo
        return 1
    fi

    local SOURCE="${ARGS[0]}"
    local DESTINATION="${ARGS[1]}"

    if [[ ! -e "$SOURCE" ]]; then
        echo
        echo "Error: Source not found: $SOURCE"
        echo
        return 1
    fi

    if [[ -e "$DESTINATION" ]]; then
        echo
        echo "Error: Destination already exists: $DESTINATION"
        echo
        return 1
    fi

    if mv "$SOURCE" "$DESTINATION"; then
        echo
        echo "Moved: $SOURCE -> $DESTINATION"
        echo
    else
        echo
        echo "Error: Failed to move: $SOURCE"
        echo
        return 1
    fi
}

############################################################
# open: Display file contents (cat functionality)
# Primarily .txt and .az files
# Syntax: open <filename>
############################################################
filesystem_open()
{
    if [[ $ARG_COUNT -lt 1 ]]; then
        echo
        echo "Error: Missing filename."
        echo "Usage:"
        echo "  open <filename>   - Display file contents"
        echo
        return 1
    fi

    local TARGET="${ARGS[0]}"

    if [[ ! -e "$TARGET" ]]; then
        echo
        echo "Error: File not found: $TARGET"
        echo
        return 1
    fi

    if [[ -d "$TARGET" ]]; then
        echo
        echo "Error: Cannot open directory: $TARGET"
        echo
        return 1
    fi

    if [[ ! -r "$TARGET" ]]; then
        echo
        echo "Error: Permission denied: $TARGET"
        echo
        return 1
    fi

    # Check for binary file to prevent dumping binary data into the terminal
    if [[ -s "$TARGET" ]] && file -b --mime "$TARGET" 2>/dev/null | grep -q "charset=binary"; then
        echo
        echo "Error: Cannot open binary file: $TARGET"
        echo "The open command is for text files (primarily .txt and .az files)."
        echo
        return 1
    fi

    if [[ -s "$TARGET" ]]; then
        cat "$TARGET"
        # Ensure trailing newline if file doesn't end with one
        local LAST_BYTE
        LAST_BYTE="$(tail -c 1 "$TARGET" 2>/dev/null)"
        if [[ -n "$LAST_BYTE" && "$LAST_BYTE" != $'\n' ]]; then
            echo
        fi
    fi

    return 0
}

