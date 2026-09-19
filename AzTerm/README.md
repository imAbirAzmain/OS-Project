# AzTerm v2

A custom Bash terminal/shell written entirely in Bash.

## Features

- Dedicated AzTerm terminal window on macOS
- Dark professional terminal theme with yellow/orange accents
- Persistent command history with interactive Up/Down arrow navigation
- File viewing with `open` command (`.txt`, `.az`, `.sh`)
- Custom programming language interpreter (`lib/interpreter.sh`)
- Variables, string interpolation (`$var`), and arithmetic (`+`, `-`, `*`, `/`, `++`, `--`)
- Relational comparisons (`>`, `<`, `>=`, `<=`, `==`, `!=`)
- Control flow structures (`if ... else if ... else ... end if`, `for`, `while`)
- `.az` scripting language engine and built-in editor
- Standalone mathematical expression evaluator (`calc` and direct math)
- Program execution capability
- Integrated Cloudion server management suite
- Clean modular architecture
- 100% Bash implementation

## Quick Start

### Installation

```bash
chmod +x install.sh
./install.sh
```

### Running AzTerm

```bash
./azterm.sh
```

On macOS, running `./azterm.sh` opens a new Terminal window for AzTerm while leaving the current terminal usable. The original shell continues to run normally. On Linux, AzTerm runs in the current terminal unless a compatible launcher is available.

## Dedicated Terminal Window Behavior

AzTerm uses a launcher guard via `AZTERM_CHILD=1` to prevent recursive window spawning:

- the original shell calls `./azterm.sh`
- the launcher starts a new macOS Terminal window
- the new window runs AzTerm with `AZTERM_CHILD=1`
- AzTerm detects the flag and starts normally without opening another window

## Theme

AzTerm uses a dark terminal palette built from centralized Bash color variables:

- Background: dark black/near-black
- Primary: yellow
- Secondary: orange
- Text: white
- Errors: red
- Success: orange/yellow

The color palette is defined in `config/config.sh` and reused by the startup banner, prompt, help table, and history output.

## Commands

### General

- `help` - Display help and available commands
- `version` - Show AzTerm version
- `clear` - Clear the screen
- `exit` - Exit AzTerm

### Programming Language & Math

- `print "<message>"` - Print message with variable interpolation (`$var`)
- `calc <expression>` - Evaluate mathematical and relational expressions
- `<number> <op> <number>` - Direct calculation (e.g. `5 + 3`, `10 > 2`, `10 != 5`)
- `x = <val>` - Variable assignment (`x = 10`, `y = x * 2`)
- `x++` / `x--` - Increment / decrement variable
- `if <cond> ... end if` - Conditional block branching
- `for <var>=<v1>,<v2>,... ... end for` - Iteration loop
- `while <cond> ... end while` - Conditional loop

### Cloudion Management

- `cloud start` - Start the Cloudion mini cloud server
- `cloud stop` - Stop the Cloudion mini cloud server
- `cloud restart` - Restart Cloudion
- `cloud status` - Show current Cloudion status
- `cloud storage` - Show storage usage and capacity report
- `cloud logs [N] [category]` - Show recent Cloudion logs
- `cloud info` - Show Cloudion configuration and process info
- `cloud help` - Show Cloudion management help

> AzTerm acts as the management interface for Cloudion. Cloudion operates as an independent service with its own backend and storage architecture.

### Navigation

- `go <folder>` - Change to a directory
- `go ..` - Go to parent directory
- `go ~` - Go to home directory
- `where am i` - Show current directory

### File Management

- `show files` - List files in current directory
- `show files <folder>` - List files in a specific folder
- `show files --depth N` - List files recursively up to depth N
- `open <filename>` - Display text/script file contents (`.txt`, `.az`, `.sh`)
- `make folder <name>` - Create a new folder
- `make file <name>` - Create a new file
- `delete <name>` - Delete a file or folder
- `copy <source> <destination>` - Copy a file or folder
- `move <source> <destination>` - Move a file or folder

### Program Execution

- `run <program>` - Execute a program
- `run <program> [arguments]` - Execute a program with arguments

### History

- `history` - Display command history
- **Arrow Keys (`Up` / `Down`)** - Interactively cycle through command history directly at the prompt

### Scripts

- `script <file.az>` - Execute a `.az` script
- `write script <file.az>` - Create or edit a `.az` script

## Project Structure

```
AzTerm/
├── README.md                 # Project overview
├── azterm.sh                 # Main entry point
├── calculator.az             # Complete language demo script
├── install.sh                # Installation script
├── uninstall.sh              # Uninstallation script
├── update.sh                 # Update script
├── config/
│   └── config.sh            # Configuration settings
├── lib/
│   ├── utils.sh             # Utility functions & UI formatting
│   ├── parser.sh            # Command parser
│   ├── commands.sh          # General built-in commands & help table
│   ├── filesystem.sh        # Filesystem operations & file viewing
│   ├── history.sh           # History management & arrow key navigation
│   ├── script.sh            # Script runner & editor
│   ├── interpreter.sh       # Language interpreter (math, variables, loops)
│   └── cloudion.sh          # Cloudion management integration
├── data/
│   ├── history.txt          # Command history file
│   └── settings.conf        # Settings file
├── docs/
│   ├── UserGuide.md         # User documentation
│   └── DeveloperGuide.md    # Developer documentation
├── assets/
│   └── logo.txt             # ASCII logo
└── scripts/                 # User scripts directory
    ├── .gitkeep             # Git tracking keep
    └── calculator.az        # Preserved demo script copy
```

## Requirements

- Bash 3.2+
- Unix/Linux environment (macOS, Linux, WSL, etc.)
- Standard Unix utilities: `ls`, `mkdir`, `rm`, `cp`, `mv`, `grep`, `sed`, etc.

## Architecture

AzTerm uses a modular architecture with clear separation of concerns:

- **parser.sh**: Tokenizes user input and routes commands
- **commands.sh**: Handles general commands (help, version, exit, run)
- **filesystem.sh**: Handles directory navigation, file operations, and `open` content display
- **history.sh**: Manages persistent history and interactive readline arrow navigation
- **script.sh**: Implements the `.az` script runner and editor
- **interpreter.sh**: Implements variable storage, math expressions, string interpolation, and control flow (if, for, while)
- **cloudion.sh**: Integrates Cloudion lifecycle management, status, and log monitoring
- **utils.sh**: Provides shared styling, table rendering, and utility functions

See [DeveloperGuide.md](docs/DeveloperGuide.md) for detailed architecture information.

## Example Session

```
az:~> where am i
/home/user

az:~> make folder MyProject
Folder created: MyProject

az:~> go MyProject
Changed to: /home/user/MyProject

az:MyProject> make file app.sh
File created: app.sh

az:MyProject> show files
app.sh

az:MyProject> go ..
Changed to: /home/user

az:~> history
  1  where am i
  2  make folder MyProject
  3  go MyProject
  4  make file app.sh
  5  show files
  6  go ..

az:~> exit
Goodbye.
```

## .az Script & Language Demo (`calculator.az`)

AzTerm includes a comprehensive language demonstration script, `calculator.az`:

```bash
# Execute the full demo script
az:~> script calculator.az
```

Script contents:
```bash
a = 10
b = 5

sum = a + b
print "Sum: $sum"

diff = a - b
print "Difference: $diff"

prod = a * b
print "Product: $prod"

div = a / b
print "Division: $div"

count = 1
count++
print "Increment: $count"
count--
print "Decrement: $count"

if a > b
print "a is greater than b"
else if a == b
print "a equals b"
else
print "a is smaller than b"
end if

if a != b
print "a is not equal to b"
end if

for i=1,2,3,4,5
print "Abir XOSS"
end for

n = 1
while n <= 3
print "Step $n"
n++
end while
```

## Documentation

- [UserGuide.md](docs/UserGuide.md) - Complete command reference and usage guide
- [DeveloperGuide.md](docs/DeveloperGuide.md) - Architecture and development guide

## License

This project is a university assignment implementation.

## Author

AzTerm v2 - Built with Bash

