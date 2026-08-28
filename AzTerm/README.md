# AzTerm v2

A custom Bash terminal/shell written entirely in Bash.

## Features

- Dedicated AzTerm terminal window on macOS
- Dark professional terminal theme with yellow/orange accents
- Persistent command history
- `.az` scripting language for automation
- Built-in script editor
- Program execution capability
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

### Cloudion Management

- `cloud start` - Start the Cloudion mini cloud server
- `cloud stop` - Stop the Cloudion mini cloud server
- `cloud restart` - Restart Cloudion
- `cloud status` - Show current Cloudion status
- `cloud logs [N]` - Show recent Cloudion logs
- `cloud info` - Show Cloudion configuration and process info
- `cloud help` - Show Cloudion management help

> AzTerm acts as the management interface for the existing Cloudion server. Cloudion remains a separate project and remains independent of the AzTerm Bash shell.

### Navigation

- `go <folder>` - Change to a directory
- `go ..` - Go to parent directory
- `go ~` - Go to home directory
- `where am i` - Show current directory

### File Management

- `show files` - List files in current directory
- `show files <folder>` - List files in a specific folder
- `show files --depth N` - List files recursively up to depth N
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

### Scripts

- `script <file.az>` - Execute a `.az` script
- `write script <file.az>` - Create or edit a `.az` script

## Project Structure

```
AzTerm/
├── README.md                 # Project overview
├── azterm.sh                 # Main entry point
├── install.sh                # Installation script
├── uninstall.sh              # Uninstallation script
├── update.sh                 # Update script
├── config/
│   └── config.sh            # Configuration settings
├── lib/
│   ├── utils.sh             # Utility functions
│   ├── parser.sh            # Command parser
│   ├── commands.sh          # General built-in commands
│   ├── filesystem.sh        # Filesystem operations
│   ├── history.sh           # History management
│   └── script.sh            # Script engine
├── data/
│   ├── history.txt          # Command history file
│   └── settings.conf        # Settings file
├── docs/
│   ├── UserGuide.md         # User documentation
│   └── DeveloperGuide.md    # Developer documentation
├── assets/
│   ├── logo.txt             # ASCII logo
│   └── banners/             # Banner files
└── scripts/                 # User scripts directory
```

## Requirements

- Bash 3.2+
- Unix/Linux environment (macOS, Linux, WSL, etc.)
- Standard Unix utilities: `ls`, `mkdir`, `rm`, `cp`, `mv`, `grep`, `sed`, etc.

## Architecture

AzTerm uses a modular architecture with clear separation of concerns:

- **parser.sh**: Tokenizes user input and routes commands
- **commands.sh**: Handles general commands (help, version, exit, run)
- **filesystem.sh**: Handles directory navigation and file operations
- **history.sh**: Manages command history persistence
- **script.sh**: Implements the .az scripting language
- **utils.sh**: Provides shared utility functions

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

## .az Script Example

Create a script to automate tasks:

```bash
# project-setup.az
# Create project structure

make folder src
make folder tests
make folder docs

go src
make file main.sh
go ..

go tests
make file test.sh
go ..

show files
```

Execute it:

```
az:~> script project-setup.az
```

## Documentation

- [UserGuide.md](docs/UserGuide.md) - Complete command reference and usage guide
- [DeveloperGuide.md](docs/DeveloperGuide.md) - Architecture and development guide

## License

This project is a university assignment implementation.

## Author

AzTerm v2 - Built with Bash

