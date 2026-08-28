# AzTerm v2 Developer Guide

Technical documentation for AzTerm v2 development and architecture.

## Table of Contents

1. [Architecture](#architecture)
2. [Module Overview](#module-overview)
3. [Parser and Dispatcher](#parser-and-dispatcher)
4. [Adding Commands](#adding-commands)
5. [Configuration](#configuration)
6. [Development Standards](#development-standards)
7. [Testing](#testing)
8. [Code Quality](#code-quality)

## Architecture

AzTerm follows a modular, layered architecture:

```
User Input
    ↓
Parser (tokenizer)
    ↓
Command Router (dispatcher)
    ↓
Module Handlers
├── commands.sh (general)
├── filesystem.sh (navigation/files)
├── history.sh (history)
├── script.sh (scripting)
├── cloudion.sh (Cloudion management)
└── execution & output
    ↓
Cloudion Mini Cloud Server
```

### Cloudion Management Architecture

```
                    AzTerm
                       |
                 Command Parser
                       |
                 Command Router
                       |
              +--------+--------+
              |                 |
       Normal Commands      cloudion.sh
                                  |
                                  v
                              Cloudion
                                  |
                                  v
                            Mini Cloud Server
```

AzTerm is the Bash management interface. Cloudion remains a separate server project. The `cloudion.sh` module is responsible for safe process detection, PID tracking, log handling, and OS compatibility checks. The Cloudion server itself is not rewritten into Bash.

### Design Principles

1. **Separation of Concerns**: Each module handles specific functionality
2. **Clean Interfaces**: Modules communicate via return codes and global variables
3. **Error Handling**: Graceful error handling without crashing the shell
4. **Modularity**: Easy to add new modules or commands
5. **Simplicity**: Readable, maintainable Bash code

## Module Overview

### azterm.sh - Main Entry Point

**Responsibilities:**
- Locate and load configuration
- Load all library modules
- Detect whether the shell is the child instance of a dedicated window launcher
- Initialize systems (history, etc.)
- Display banner
- Main loop for user input
- Update dynamic prompt

**Key Features:**
- Determines script directory for relative paths
- Uses `AZTERM_CHILD=1` to prevent recursive Terminal spawn loops
- Opens a dedicated macOS Terminal window when launched from a normal shell
- Initializes history system
- Manages the main read-eval loop
- Updates prompt with current directory

**Launcher behavior:**
```bash
if [[ "${AZTERM_CHILD:-0}" != "1" ]]; then
    case "$(uname -s)" in
        Darwin)
            azterm_launch_macos_terminal
            ;;
    esac
fi
```
This keeps the original terminal usable while AzTerm runs in a separate dedicated window.

### config/config.sh - Configuration

**Stores:**
- AzTerm name and version
- Default prompt
- History file path
- Script directory

**Usage:**
```bash
AZTERM_NAME="AzTerm"
AZTERM_VERSION="2.0"
AZTERM_PROMPT="az> "
HISTORY_FILE="data/history.txt"
SCRIPT_DIRECTORY="scripts"
```

### lib/parser.sh - Command Parser

**Responsibilities:**
- Tokenize user input
- Handle quoted arguments
- Extract command and arguments
- Route commands to handlers

**Key Functions:**
- `tokenize_input()` - Splits input into tokens
- `parse_command()` - Main parser function
- `route_command()` - Dispatcher

**Global Variables Set:**
- `COMMAND` - The command name
- `ARGS[]` - Array of arguments
- `ARG_COUNT` - Number of arguments
- `USER_INPUT` - Original input string

**Example:**
```bash
User types: make folder "My Project"
After tokenize: ["make", "folder", "My Project"]
After parse:
  COMMAND="make"
  ARGS=["folder", "My Project"]
  ARG_COUNT=2
```

### lib/commands.sh - General Commands

**Implements:**
- `help` - Display command help
- `version` - Show version
- `clear` - Clear screen
- `exit` - Exit AzTerm
- `run` - Execute programs

**Dispatcher Pattern:**
```bash
commands_dispatch() {
    case "$COMMAND" in
        help)
            command_help
            return 0
            ;;
        *)
            return 1  # Not handled
            ;;
    esac
}
```

### lib/filesystem.sh - File Operations

**Implements:**
- `go` - Change directory
- `where am i` - Show current directory
- `show files` - List directory contents
- `make folder/file` - Create items
- `delete` - Remove items
- `copy` - Copy items
- `move` - Move items

**State Management:**
- Maintains `AZTERM_PWD` for current directory

### lib/history.sh - Command History

**Responsibilities:**
- Load/initialize history file
- Record commands
- Display history
- Persist to disk

**Key Functions:**
- `history_init()` - Initialize history file
- `history_add()` - Record a command
- `history_display()` - Show history

**File Format:**
- One command per line
- Stored in `data/history.txt`
- Line numbers added on display

### lib/script.sh - Script Engine

**Implements:**
- `.az` script execution
- Built-in script editor
- Comment/blank line handling
- Error reporting with line numbers

**Key Functions:**
- `script_execute()` - Run a .az file
- `script_editor()` - Interactive editor
- `script_dispatch()` - Router

### lib/cloudion.sh - Cloudion Management Layer

**Implements:**
- `cloud start` / `cloud stop` / `cloud restart`
- `cloud status` / `cloud logs` / `cloud info`
- OS compatibility validation
- PID detection and cleanup
- Log file access and process verification

**Key Responsibilities:**
- Detect whether the Cloudion binary is runnable on the current OS
- Resolve the real Cloudion project path and binary location
- Start the server only when it is not already running
- Verify the process exists before reporting success
- Keep all Cloudion-specific logic isolated from AzTerm's general commands

### lib/utils.sh - Shared Utilities

**Provides:**
- `show_banner()` - Display startup banner
- `print_line()` - Print formatted output
- `get_prompt_path()` - Get prompt directory

## Parser and Dispatcher

### Tokenization Process

The tokenizer handles:
1. Splitting on spaces
2. Preserving quoted strings
3. Removing quote characters
4. Building token array

```bash
# Input: go "My Folder"
# Tokens: ["go", "My Folder"]
```

### Command Routing

The dispatcher tries modules in order:
1. `commands_dispatch` - General commands
2. `filesystem_dispatch` - File operations
3. `history_dispatch` - History
4. `script_dispatch` - Scripts

First module to return 0 (handled) wins. If all return 1, command is unknown.

```bash
route_command() {
    commands_dispatch && return 0
    filesystem_dispatch && return 0
    history_dispatch && return 0
    script_dispatch && return 0
    
    # Unknown command
    echo "Unknown command: $COMMAND"
    return 1
}
```

## Adding Commands

### Step 1: Add Implementation

In the appropriate module (e.g., `lib/commands.sh`):

```bash
command_mycommand()
{
    if [[ $ARG_COUNT -lt 1 ]]; then
        echo "Error: Missing argument"
        return 1
    fi
    
    echo "Executing: $COMMAND with ${ARGS[0]}"
}
```

### Step 2: Update Dispatcher

In the same module:

```bash
module_dispatch()
{
    case "$COMMAND" in
        mycommand)
            command_mycommand
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}
```

### Step 3: Test

```bash
bash -n lib/module.sh  # Syntax check
./azterm.sh << EOF
mycommand arg1
exit
EOF
```

## Configuration

### Adding Configuration Values

Edit `config/config.sh`:

```bash
MY_SETTING="value"
```

Access in any module:

```bash
echo "$MY_SETTING"
```

### Settings File

Use `data/settings.conf` for runtime settings that persist:

```
# data/settings.conf
THEME=dark
COLOR_MODE=enabled
```

### Accessing Script Directory

Use `$SCRIPT_DIR`:

```bash
source "$SCRIPT_DIR/config/config.sh"
```

## Development Standards

### Naming Conventions

**Functions:**
- Module functions: `module_command()` or `module_subcommand_action()`
- Private functions: prefix with underscore
- Examples: `filesystem_go()`, `history_add()`

**Variables:**
- Global: `UPPERCASE_WITH_UNDERSCORES`
- Local: `lowercase_with_underscores` (declared with `local`)
- Examples: `COMMAND`, `AZTERM_PWD`, `line_content`

**Constants:**
- `AZTERM_*` for AzTerm-specific values
- Examples: `AZTERM_NAME`, `AZTERM_VERSION`

### Code Style

**Spacing:**
- Use 4-space indentation
- Separate function definitions with blank lines
- Section comments with multiple `#` lines

**Comments:**
- Block comments explain "why", not "what"
- Functions have header comments
- Complex logic has inline comments

**Quoting:**
- Quote variables: `"$VAR"` not `$VAR`
- Quote command substitutions: `"$(command)"`
- Use `[[ ]]` instead of `[ ]`

### Error Handling

Every function should:
1. Validate arguments
2. Return appropriate exit codes (0 for success, 1 for failure)
3. Provide helpful error messages
4. Not crash the shell

```bash
command_example()
{
    if [[ $ARG_COUNT -lt 1 ]]; then
        echo
        echo "Error: Missing argument"
        echo "Usage: example <arg>"
        echo
        return 1
    fi
    
    # Do work...
    return 0
}
```

## Testing

### Syntax Checking

Check all files before testing:

```bash
bash -n azterm.sh
bash -n lib/*.sh
bash -n config/*.sh
```

### Unit Testing Commands

Test individual commands:

```bash
./azterm.sh << EOF
command arg1 arg2
exit
EOF
```

### Integration Testing

Test command sequences:

```bash
./azterm.sh << EOF
where am i
make folder test
go test
show files
go ..
delete test
exit
EOF
```

### Script Testing

Create test scripts:

```bash
# test.az
make folder test_folder
go test_folder
make file test.txt
go ..
show files
delete test_folder
```

Execute and verify:

```bash
./azterm.sh << EOF
script test.az
exit
EOF
```

### Error Testing

Test error conditions:

```bash
./azterm.sh << EOF
go nonexistent
make folder existing_folder
make folder existing_folder
delete nonexistent
exit
EOF
```

## Code Quality

### Readability

1. Use meaningful variable names
2. Add comments for non-obvious code
3. Keep functions focused and short
4. Avoid deeply nested logic

### Maintainability

1. Follow the modular architecture
2. Don't repeat code - use functions
3. Keep configuration centralized
4. Document changes in code comments

### Performance

1. Avoid unnecessary processes
2. Use built-in Bash features when possible
3. Don't spawn processes in tight loops
4. Use `local` variables in functions

### Security

1. Quote variables to prevent expansion
2. Validate user input
3. Be careful with `rm` and file operations
4. Don't use `eval` on user input

## Common Tasks

### Add a New General Command

1. Add function in `lib/commands.sh`
2. Add case in `commands_dispatch()`
3. Update `help` command text
4. Test thoroughly

### Add a New File Operation

1. Add function in `lib/filesystem.sh`
2. Add case in `filesystem_dispatch()`
3. Update `help` command text
4. Test with various inputs

### Add Configuration Value

1. Add to `config/config.sh`
2. Update documentation
3. Use `$VARIABLE_NAME` throughout codebase

### Fix a Bug

1. Identify the module
2. Add debugging with `echo` statements
3. Use `bash -n` to check syntax
4. Test the fix thoroughly
5. Remove debugging statements

## Deployment

### Installation

The `install.sh` script should:
- Verify Bash version
- Make scripts executable
- Initialize data directories
- Create initial history file

### Updates

The `update.sh` script should:
- Preserve user data
- Update code files only
- Maintain backward compatibility

### Uninstallation

The `uninstall.sh` script should:
- Safely remove code
- Warn before deleting data
- Provide restoration guidance

