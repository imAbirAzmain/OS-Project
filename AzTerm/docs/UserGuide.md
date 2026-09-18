# AzTerm v2 User Guide

A comprehensive guide to using AzTerm v2.

## Table of Contents

1. [Getting Started](#getting-started)
2. [General Commands](#general-commands)
3. [Navigation](#navigation)
4. [File Management](#file-management)
5. [Program Execution](#program-execution)
6. [History](#history)
7. [Scripting](#scripting)
8. [Examples](#examples)
9. [Troubleshooting](#troubleshooting)

## Getting Started

### Starting AzTerm

```bash
./azterm.sh
```

On macOS, this starts a dedicated AzTerm window in the Terminal app. The original terminal remains usable. On Linux, AzTerm starts in the current terminal by default unless a compatible terminal launcher is available.

You should see the AzTerm banner, a dark theme, and a prompt like:

```
az> 
```

The prompt shows the current directory. Type `help` to see all available commands.

### Terminal Theme

AzTerm uses a professional dark theme with yellow/orange highlights and white text. The startup screen, prompt, help table, and history box all follow the same palette.

### Window Title

The AzTerm window title is set to `AzTerm v2` while the shell is active.

### Exiting AzTerm

Type `exit` to exit AzTerm:

```
az:~> exit
Goodbye.
```

## Cloudion Management

AzTerm provides native terminal controls to manage the Cloudion cloud server through its modular script dispatcher (`scripts/cloud/cloud.sh`).

### cloud start

Start the Cloudion service in the background if it is not already running.

```bash
az:~> cloud start
Starting Cloudion...
Cloudion started successfully.
PID: 42831
Port: 4000
```

### cloud stop

Stop a running Cloudion server process safely.

```bash
az:~> cloud stop
Stopping Cloudion...
Cloudion stopped successfully.
```

### cloud restart

Restart the Cloudion server cleanly.

```bash
az:~> cloud restart
Restarting Cloudion...
Cloudion stopped.
Cloudion started successfully.
PID: 43105
```

### cloud status

Display comprehensive live status for the Cloudion server including PID, uptime, resource consumption, and network metrics.

```bash
az:~> cloud status
┌────────────────────────────────────────┐
│             CLOUDION STATUS            │
└────────────────────────────────────────┘
  State       : RUNNING
  PID         : 42831
  Port        : 4000
  Uptime      : 01:24:12
  CPU Usage   : 0.4%
  Memory      : 42.8 MB
  Disk Free   : 148.2 GB
```

### cloud storage

Display storage utilization metrics across all Cloudion partitions (Personal, One-to-One, Groups, Global, and Backups).

```bash
az:~> cloud storage
┌────────────────────────────────────────┐
│            CLOUDION STORAGE            │
└────────────────────────────────────────┘
  Total Used  : 14.6 MB
  Users       : 8.2 MB
  1-to-1      : 2.1 MB
  Groups      : 3.4 MB
  Global      : 0.9 MB
  Backups     : 12.0 MB
```

### cloud logs

Display recent log output from Cloudion. You can optionally specify the number of lines and a specific category (`server`, `auth`, `file`, `group`, `chat`).

```bash
az:~> cloud logs 20
┌────────────────────────────────────────┐
│             CLOUDION LOGS              │
└────────────────────────────────────────┘
[recent log entries...]

az:~> cloud logs 10 auth
```

### cloud info

Display Cloudion environment configurations, paths, database, and process details.

```bash
az:~> cloud info
┌────────────────────────────────────────┐
│          CLOUDION INFORMATION          │
└────────────────────────────────────────┘
  Project     : Cloudion
  Version     : 2.0.0
  Backend     : Node.js / Express
  Database    : SQLite (cloud.db)
  Location    : /path/to/cloudion
  Port        : 4000
  PID File    : /path/to/cloudion/.cloudion.pid
  Log File    : /path/to/cloudion/logs/server.log
```

### cloud help

Show all available Cloudion management subcommands.

```bash
az:~> cloud help
Cloudion Management Commands
=============================
  cloud start              - Start Cloudion server
  cloud stop               - Stop Cloudion server
  cloud restart            - Restart Cloudion server
  cloud status             - Show server status & metrics
  cloud storage            - Show storage usage breakdown
  cloud logs [N] [cat]     - View recent server/category logs
  cloud info               - Show configuration & environment
  cloud help               - Show this help reference

## General Commands

### help

Display all available commands organized by category.

```
az:~> help
```

Shows:
- General commands
- Navigation commands
- File management commands
- Execution commands
- History
- Scripts

### version

Display the AzTerm version and description.

```
az:~> version
AzTerm v2.0
A custom Linux shell written in Bash
```

### clear

Clear the terminal screen.

```
az:~> clear
```

### exit

Exit AzTerm and return to the system shell.

```
az:~> exit
Goodbye.
```

## Navigation

### go <folder>

Change to a directory.

```
az:~> go Documents
Changed to: /home/user/Documents

az:Documents>
```

### go ..

Move to the parent directory.

```
az:Documents> go ..
Changed to: /home/user

az:~>
```

### go ~

Move to the home directory from anywhere.

```
az:Documents> go ~
Changed to: /home/user

az:~>
```

### where am i

Display the current directory path.

```
az:Documents> where am i
/home/user/Documents
```

## File Management

### show files

List files and directories in the current directory.

```
az:~> show files
Desktop
Documents
Downloads
Pictures
```

### show files <folder>

List files and directories in a specific folder.

```
az:~> show files Documents
file1.txt
file2.txt
Subfolder
```

### show files --depth N

List files recursively up to depth N.

```
az:~> show files --depth 2
./
./Documents
./Documents/file1.txt
./Documents/file2.txt
./Pictures
```

### make folder <name>

Create a new directory.

```
az:~> make folder MyProject
Folder created: MyProject
```

Error handling:

```
az:~> make folder MyProject
Error: Folder already exists: MyProject
```

### make file <name>

Create a new empty file.

```
az:~> make file note.txt
File created: note.txt
```

Error handling:

```
az:~> make file note.txt
Error: File already exists: note.txt
```

### open <filename>

Display the contents of a file (cat functionality). Primarily used for `.txt`, `.az`, and `.sh` files.

```
az:~> open note.txt
Hello from AzTerm!
```

Script file examples:

```
az:~> open abir.az
make folder bijoy2
go bijoy2
make file inside.txt
```

Shell script example:

```
az:~> open script.sh
#!/bin/bash
echo "Hello from script"
```

Error handling:

```
az:~> open nonexistent.txt
Error: File not found: nonexistent.txt

az:~> open MyProject
Error: Cannot open directory: MyProject
```

### delete <name>

Delete a file or directory. Directories are deleted recursively.

```
az:~> delete note.txt
Deleted: note.txt
```

For directories:

```
az:~> delete MyProject
Deleted: MyProject
```

Error handling:

```
az:~> delete nonexistent.txt
Error: Item not found: nonexistent.txt
```

### copy <source> <destination>

Copy a file or directory.

```
az:~> copy file.txt backup.txt
Copied: file.txt -> backup.txt
```

For directories:

```
az:~> copy MyProject MyProject_backup
Copied: MyProject -> MyProject_backup
```

Error handling:

```
az:~> copy source.txt dest.txt
Error: Source not found: source.txt

az:~> copy file.txt existing.txt
Error: Destination already exists: existing.txt
```

### move <source> <destination>

Move or rename a file or directory.

```
az:~> move oldname.txt newname.txt
Moved: oldname.txt -> newname.txt
```

For directories:

```
az:~> move OldFolder NewFolder
Moved: OldFolder -> NewFolder
```

## Program Execution

### run <program>

Execute a system program.

```
az:~> run echo Hello
Hello
```

### run <program> [arguments]

Execute a program with arguments.

```
az:~> run echo "Hello World"
Hello World

az:~> run ls -la
total 48
drwxr-xr-x  10 user  staff  320 Aug 17 12:30 .
drwxr-xr-x   3 root  wheel   96 Aug  1 10:00 ..
...
```

Error handling:

```
az:~> run nonexistent_program
Error: Program not found: nonexistent_program
```

## History

### history

Display all previously executed commands with line numbers.

```
az:~> history
  1  where am i
  2  make folder MyProject
  3  go MyProject
  4  make file readme.txt
  5  go ..
  6  show files
```

History is automatically:
- Saved to `data/history.txt`
- Preserved between sessions
- Numbered for reference

### Interactive History Navigation (Arrow Keys)

AzTerm supports native interactive readline history traversal directly at the prompt:

- Press **`Up Arrow` (`↑`)**: Recalls the immediately preceding command in history. Pressing repeatedly traverses backwards through earlier commands.
- Press **`Down Arrow` (`↓`)**: Navigates forward toward more recent commands or clears back to a fresh prompt.
- The recalled command can be edited directly before pressing Enter.

## Scripting

### .az Script Format

.az scripts are simple text files with AzTerm commands.

Features:
- One command per line
- Comments start with `#`
- Empty lines are ignored
- All AzTerm commands are supported

Example script:

```bash
# setup.az
# Create project structure

make folder src
make folder tests
make folder docs

go src
make file main.sh
go ..

show files
```

### script <file.az>

Execute a .az script.

```
az:~> script setup.az
Executing script: setup.az

[1] make folder src
Folder created: src

[2] make folder tests
Folder created: tests

...

Script completed successfully.
```

### write script <file.az>

Create or edit a script using the built-in editor.

```
az:~> write script setup.az
========================================
        AZTERM SCRIPT EDITOR
========================================

Writing setup.az

Enter script commands. Type ':save' to save or ':cancel' to discard.

az-script> make folder src
az-script> make folder tests
az-script> go src
az-script> make file main.sh
az-script> go ..
az-script> :save
Script saved: setup.az
```

## Examples

### Example 1: Create a Project Structure

```
az:~> make folder MyApp
Folder created: MyApp

az:~> go MyApp
Changed to: /home/user/MyApp

az:MyApp> make folder src
Folder created: src

az:MyApp> make folder tests
Folder created: tests

az:MyApp> make folder docs
Folder created: docs

az:MyApp> make file README.md
File created: README.md

az:MyApp> show files
README.md
docs
src
tests

az:MyApp> go ..
Changed to: /home/user
```

### Example 2: Using Scripts

Create a script:

```
az:~> write script backup.az
az-script> make folder backup
az-script> copy README.md backup/README.md
az-script> copy data backup/data
az-script> :save
Script saved: backup.az
```

Execute the script:

```
az:~> script backup.az
Executing script: backup.az

[1] make folder backup
Folder created: backup

[2] copy README.md backup/README.md
Copied: README.md -> backup/README.md

[3] copy data backup/data
Copied: data -> backup/data

Script completed successfully.
```

### Example 3: Using run Command

```
az:~> run date
Sun Aug 17 12:30:45 PDT 2025

az:~> run pwd
/home/user

az:~> run grep "error" logfile.txt
[error] Something went wrong
```

## Troubleshooting

### Command not found

If you see "Unknown command: xyz", the command doesn't exist in AzTerm.

Solution: Type `help` to see all available commands.

### Permission denied

If a file operation fails with permission denied:

```
Error: Failed to create folder: MyFolder
```

Solution: Check directory permissions with `run ls -ld <directory>`

### Script not found

```
Error: Script file not found: setup.az
```

Solution: Make sure the script file exists in the current directory. Use `show files` to list files.

### History not saving

History should automatically save to `data/history.txt`.

If history is not appearing:
- Ensure the `data` directory exists
- Check file permissions
- Use `history` command to verify

## Tips and Tricks

1. **Use the prompt directory indicator**: The prompt shows your current directory, so you always know where you are.

2. **Navigate efficiently**: Use `go ..` to move up quickly, and `go ~` to return home from anywhere.

3. **Create scripts for repeated tasks**: Instead of typing the same commands repeatedly, create a .az script.

4. **View history for reference**: Use `history` to see what commands you've run and when.

5. **Comment your scripts**: Use `#` to add comments explaining what your script does.

## Command Summary

| Command | Purpose |
|---------|---------|
| `help` | Show all commands |
| `version` | Show AzTerm version |
| `clear` | Clear screen |
| `exit` | Exit AzTerm |
| `go <folder>` | Change directory |
| `go ..` | Go to parent |
| `go ~` | Go to home |
| `where am i` | Show current path |
| `show files` | List files |
| `make folder <name>` | Create folder |
| `make file <name>` | Create file |
| `delete <name>` | Delete file/folder |
| `copy <src> <dst>` | Copy file/folder |
| `move <src> <dst>` | Move file/folder |
| `run <program>` | Execute program |
| `history` | Show command history |
| `script <file.az>` | Execute script |
| `write script <file>` | Create script |

