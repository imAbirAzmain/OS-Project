# Operating Systems Project: AzTerm & Cloudion

An integrated Unix/Linux systems project featuring **AzTerm** (a modular custom Bash shell with interactive history navigation and scripting) and **Cloudion** (a multi-tenant cloud file-sharing and server platform whose operational backbone is a comprehensive collection of focused Bash scripts).

---

## Architecture Overview

The repository unites two major operating systems components designed to operate both independently and in synergy:

```
                               ┌──────────────────────────────────────────────┐
                               │                 User Space                   │
                               └──────┬────────────────────────────────┬──────┘
                                      │                                │
                       [Interactive Terminal CLI]            [Web Browser UI :4000]
                                      │                                │
                                      ▼                                ▼
                         ┌───────────────────────────┐    ┌─────────────────────────┐
                         │         AzTerm v2         │    │    Cloudion Web App     │
                         │   (Custom Bash Terminal)  │    │ (Vanilla HTML / CSS / JS│
                         └─────────────┬─────────────┘    └────────────┬────────────┘
                                       │                               │
                               [cloud commands]                  [REST / API]
                                       │                               │
                                       ▼                               ▼
                         ┌───────────────────────────┐    ┌─────────────────────────┐
                         │   AzTerm cloudion.sh      │    │  Node / Express Server  │
                         │    (Integration Layer)    │    │  (SQLite State & Auth)  │
                         └─────────────┬─────────────┘    └────────────┬────────────┘
                                       │                               │
                                       │  scripts/cloud/cloud.sh       │  execFile('bash')
                                       │  (Unified Dispatcher)         │  (Whitelisted scripts)
                                       └───────────────┬───────────────┘
                                                       │
                                                       ▼
                                     ┌───────────────────────────────────┐
                                     │     Cloudion Modular Engine       │
                                     │     (Focused Bash Scripts)        │
                                     ├───────────────────────────────────┤
                                     │ • personal/     • one_to_one/     │
                                     │ • groups/       • global/         │
                                     │ • monitoring/   • backup/restore/ │
                                     │ • maintenance/  • logging/        │
                                     └─────────────────┬─────────────────┘
                                                       │
                                                       ▼
                                     ┌───────────────────────────────────┐
                                     │    Linux / macOS File System      │
                                     │   (storage/, logs/, backups/)     │
                                     └───────────────────────────────────┘
```

### Core Design Philosophy
- **Database & Backend**: Manages identity, credentials, user sessions, friendships, group memberships, chat messages, and authorization decisions.
- **Bash & Operating System**: Handles all physical filesystem manipulation, directories, file movements, searches, disk quotas, tarball backup creation/restoration, log sinks, and system resource monitoring.
- **Terminal Shell**: AzTerm provides native, colored terminal ergonomics for everyday system administration and directly executes Cloudion lifecycle actions.

---

## Component Overview

### 1. AzTerm v2 (Custom Bash Shell)
A custom command-line interface written 100% in Bash. It features:
- **Interactive History Navigation**: Cycle through command history with native `Up` (`↑`) and `Down` (`↓`) arrow keys.
- **Dedicated Terminal Launching**: Spawns a dedicated macOS Terminal window with recursion prevention (`AZTERM_CHILD=1`).
- **File Management**: Create, delete, move, copy, and inspect files with `show files` (supporting recursive depth limiting `--depth N`).
- **File Content Viewer**: Fast text and script previewing with `open <file>` (supports `.txt`, `.az`, and `.sh`).
- **`.az` Scripting Language**: Automation script interpreter and built-in editor (`write script <name.az>`, `script <name.az>`).
- **Native Cloudion Interface**: Seamless `cloud` command suite (`start`, `stop`, `restart`, `status`, `storage`, `logs`, `info`).
- **Professional Theme**: Sleek dark terminal palette with custom ASCII branding.

### 2. Cloudion (Cloud File-Sharing & Storage Engine)
A modular cloud platform featuring:
- **Single-Page Web Application**: Responsive interface for file management, friend connections, 1:1 chat, and group collaborations.
- **Multi-Tenant Storage Partitions**:
  - **Personal Cloud**: User-isolated private files (`storage/users/<username>/files/`).
  - **One-to-One Cloud**: Mutual shared storage between friends (`storage/one_to_one/conversation_<id>/`).
  - **Group Cloud**: Multi-user shared file workspace (`storage/groups/group_<id>/files/`).
  - **Global Cloud**: Public community repository shared across all registered accounts (`storage/global/`).
- **Engine + Wrapper Script Architecture**: Shared, hardened filesystem engine (`scripts/files/`) wrapped by domain-specific scripts to eliminate duplicated logic.
- **Security & Path Hardening**:
  - Path traversal defense (`resolve_within_base` with `realpath -m` and rejection of `..`).
  - Command injection prevention (zero shell strings; backend uses `execFile('bash', [scriptPath, ...args])`).
  - Enforced file permissions (`chmod 0640` on files, `0750` on storage directories).
  - Explicit refusal of symbolic links on deletions.
- **Standardized Machine Contracts**: Scripts emit machine-readable `KEY=VALUE` output and standardized exit codes (0 to 7) mapped cleanly to HTTP status codes.
- **Server Health & Monitoring**: Automated telemetry measuring CPU, memory, disk usage, active processes, and network interfaces.
- **Automated Backup & Maintenance**: Automated snapshot archiving (`tar.gz`), log retention rotation, and orphaned upload cleanups.
- **Admin CLI Console**: Terminal-based administration menu (`./cloudctl.sh`).

---

## Repository Structure

```
.
├── README.md                   # Repository documentation (this file)
├── .gitignore                  # Git ignore rules for node_modules, logs, PIDs, uploads
├── AzTerm/                     # Custom Bash Terminal implementation
│   ├── README.md               # AzTerm overview & quick reference
│   ├── azterm.sh               # Main entry point & window launcher
│   ├── install.sh              # Installation script
│   ├── uninstall.sh            # Uninstallation script
│   ├── update.sh               # Update script
│   ├── config/
│   │   └── config.sh           # Theme palette & path configurations
│   ├── lib/
│   │   ├── commands.sh         # Built-in general commands (help, version, exit, run)
│   │   ├── filesystem.sh       # Filesystem navigation, manipulation, and open viewer
│   │   ├── history.sh          # History persistence & interactive arrow navigation
│   │   ├── parser.sh           # Tokenizer & command router
│   │   ├── script.sh           # .az script interpreter & editor
│   │   ├── cloudion.sh         # Cloudion management integration layer
│   │   └── utils.sh            # Banner rendering, tables, and formatting utilities
│   ├── data/
│   │   ├── history.txt         # Command history persistence
│   │   └── settings.conf       # Local preferences
│   ├── docs/
│   │   ├── UserGuide.md        # Comprehensive AzTerm command guide
│   │   └── DeveloperGuide.md   # AzTerm internal architecture guide
│   ├── assets/                 # ASCII logo and visual banners
│   └── scripts/                # AzTerm sample & user automation scripts
│
└── cloudion/                   # Cloud storage & Bash automation platform
    ├── README.md               # Detailed Cloudion technical documentation
    ├── VERSION                 # Current release version string
    ├── cloudctl.sh             # Interactive terminal administration console
    ├── frontend/               # Single-page web UI (HTML, CSS, JavaScript)
    ├── backend/                # Node.js / Express API service
    │   ├── server.js           # Express app entry point (port 4000)
    │   ├── config/             # Paths, tokens, and storage constraints
    │   ├── database/           # SQLite schema and query abstraction (db.js)
    │   ├── middleware/         # JWT authentication & Multer upload staging
    │   ├── controllers/        # Domain controllers (personal, groups, auth, etc.)
    │   ├── routes/             # Express API endpoints
    │   └── services/           # scriptRunner (executes whitelisted Bash scripts)
    ├── scripts/                # Modular Bash script execution engine
    │   ├── lib/common.sh       # Shared logging, path validation, exit codes
    │   ├── auth/               # User directory provisioning & teardown
    │   ├── files/              # Core upload, download, search, delete, info engine
    │   ├── personal/           # Personal cloud wrappers
    │   ├── one_to_one/         # 1:1 conversation storage wrappers
    │   ├── groups/             # Group storage wrappers
    │   ├── global/             # Global storage wrappers
    │   ├── storage/            # Disk usage & capacity reports
    │   ├── monitoring/         # CPU, memory, disk, network, and process monitors
    │   ├── backup/             # Archive creation, restoration, and deletion
    │   ├── maintenance/        # Temporary file & old log cleanup jobs
    │   ├── logging/            # Centralized log operation sink
    │   └── cloud/              # Unified `cloud.sh` command suite
    ├── storage/                # Physical file storage partitions
    ├── logs/                   # Server, category, and audit logs
    └── backups/                # Compressed archive snapshots
```

---

## Quick Start

### Prerequisites
- **Operating System**: macOS (tested on Sonoma/Sequoia) or Linux (Ubuntu/Debian)
- **Shell**: Bash 3.2 or higher
- **Node.js**: Node.js v16+ and `npm` (for Cloudion backend)
- **Core Utilities**: Standard Unix tools (`tar`, `df`, `stat`, `ps`, `grep`, `sed`)

---

### Running AzTerm

1. Navigate to the `AzTerm` directory:
   ```bash
   cd AzTerm
   chmod +x install.sh azterm.sh
   ./install.sh
   ```

2. Launch the shell:
   ```bash
   ./azterm.sh
   ```
   *On macOS, a dedicated new Terminal window will open automatically.*

3. Try out sample commands in AzTerm:
   ```bash
   az> help
   az> make folder Demo
   az> go Demo
   az> make file test.txt
   az> open test.txt
   az> show files
   az> go ..
   ```
   *Use the **Up (`↑`)** and **Down (`↓`)** arrow keys at any time to recall previous commands.*

---

### Managing Cloudion from AzTerm

You can manage the Cloudion server directly from inside AzTerm:

```bash
az> cloud start        # Start Cloudion in the background (port 4000)
az> cloud status       # View live server health, CPU, memory, and PID
az> cloud storage      # View storage utilization report
az> cloud logs 20      # View the last 20 log entries
az> cloud restart      # Safely restart the server
az> cloud stop         # Stop the background process
```

---

### Running Cloudion Standalone

#### Web Application & Backend
1. Install backend dependencies and start the server:
   ```bash
   cd cloudion/backend
   npm install
   npm start
   ```

2. Open **http://localhost:4000** in your browser.
3. Register accounts to test file sharing, 1:1 chat, and group storage.

#### Terminal Admin Console
You can also inspect and administer Cloudion using the interactive terminal tool:
```bash
cd cloudion
chmod +x cloudctl.sh
./cloudctl.sh
```

---

## Standardized Exit Codes

Every script executed by Cloudion or AzTerm complies with a strict exit code specification:

| Code | Meaning | HTTP Status |
|:---:|:---|:---:|
| `0` | `SUCCESS` | `200` |
| `1` | `GENERAL_ERROR` | `500` |
| `2` | `INVALID_ARGUMENT` | `400` |
| `3` | `FILE_NOT_FOUND` | `404` |
| `4` | `PERMISSION_DENIED` | `403` |
| `5` | `STORAGE_ERROR` | `507` |
| `6` | `INVALID_PATH` | `400` |
| `7` | `AUTHORIZATION_FAILURE` | `403` |

---

## Documentation Links

- **[AzTerm User Guide](AzTerm/docs/UserGuide.md)**: Full command reference, syntax, and examples.
- **[AzTerm Developer Guide](AzTerm/docs/DeveloperGuide.md)**: Architecture, module dispatching, tokenizer, and extension guide.
- **[AzTerm README](AzTerm/README.md)**: Quick overview and command reference for AzTerm.
- **[Cloudion README](cloudion/README.md)**: Detailed security specifications, request lifecycle, script engine docs, and storage architecture.

---

## License & Course Information
This repository is developed as a comprehensive Operating Systems course project.
