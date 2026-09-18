# Cloudion

A learning project: a cloud file-sharing server whose web application is
just the interface — **the operational engine is a large collection of
focused Bash scripts** that do all the real Linux/filesystem work.

> Web UI → Backend (Node/Express + SQLite) → Bash scripts → Linux filesystem

If you take nothing else from this project, take this rule, which is
enforced everywhere in the codebase:

- **Database/backend** owns: users, passwords, sessions, friendships,
  group membership, chat messages, permission decisions.
- **Bash/Linux** owns: directories, files, moving/copying/deleting files,
  searching the filesystem, disk usage, backups, restores, logs, server
  monitoring.

The backend never touches the filesystem directly for cloud-storage
operations — it always calls a whitelisted `.sh` script and relays the
result.

---

## 1. Quick start

```bash
cd backend
npm install
npm start
```

Then open **http://localhost:4000** in a browser. Register two accounts to
try out friends, one-to-one chat, and groups.

You can also manage everything from the terminal, without the web UI at
all:

```bash
./cloudctl.sh          # interactive menu
./cloudctl.sh status   # one-shot status check
```

---

## 2. Project layout

```
cloudion/
├── frontend/                 single-page web UI (HTML/CSS/vanilla JS)
├── backend/
│   ├── server.js             Express app entrypoint
│   ├── config/                paths, secrets, limits
│   ├── database/              SQLite schema + connection (db.js)
│   ├── middleware/             auth (JWT), upload (multer) middleware
│   ├── controllers/            one per feature area (personal/groups/etc)
│   ├── routes/                 Express routers, one per feature area
│   └── services/scriptRunner/  the ONLY code allowed to exec a .sh script
├── scripts/
│   ├── lib/common.sh          shared helpers: exit codes, logging, path safety
│   ├── auth/                  user storage lifecycle
│   ├── files/                 generic upload/download/delete/search/info/list engine
│   ├── personal/              thin wrappers -> Personal Cloud
│   ├── one_to_one/            thin wrappers -> 1:1 conversation storage
│   ├── groups/                thin wrappers -> Group Cloud storage
│   ├── global/                thin wrappers -> Global Cloud storage
│   ├── storage/                disk usage / per-user storage reports
│   ├── monitoring/             CPU/memory/disk/process/network/status
│   ├── backup/                 backup / restore / list / delete archives
│   ├── maintenance/             cleanup of temp files, old logs, failed uploads
│   ├── logging/                 log_operation.sh, the single logging sink
│   └── cloud/                   `cloud <subcommand>` family — see section 10
├── storage/                    users/, one_to_one/, groups/, global/, temporary/
├── logs/                        server.log + per-category logs
├── backups/                     tar.gz archives
├── VERSION                      plain-text version string, read by cloud_info.sh
└── cloudctl.sh                  terminal admin console
```

### Why generic engine scripts + thin wrappers?

Rather than writing four independent copies of "upload a file" (one each
for personal/one-to-one/group/global), `scripts/files/` contains one
well-tested **engine** (`file_upload.sh`, `file_download.sh`,
`file_delete.sh`, `file_search.sh`, `file_info.sh`, `file_list.sh`) that
operates on any `base_dir` it's given. Each cloud area then gets a small,
readable **wrapper** script (e.g. `personal_upload.sh`) whose only job is
to resolve the right `base_dir` for that area and call the engine. This
keeps the security-critical logic (path validation, space checks,
permissions) in exactly one place instead of four almost-identical copies
that could drift out of sync — while still giving every area its own
purpose-named, independently runnable script, as called for in the brief.

---

## 3. How a request actually flows

**Upload:**

```
Browser "Upload" button
   -> POST /api/personal/files  (multipart, JWT in Authorization header)
   -> backend/routes/personalRoutes.js
   -> backend/controllers/personalController.js
        - requireAuth already confirmed WHO the user is
        - multer already saved the raw bytes to storage/temporary/uploads/<random>
   -> services/scriptRunner.runScript('PERSONAL_UPLOAD', [username, tempPath, filename])
   -> scripts/personal/personal_upload.sh
   -> scripts/files/file_upload.sh
        - validates the filename
        - checks free disk space with `df`
        - creates the destination directory with `mkdir -p`
        - moves the file into place with `mv`
        - sets permissions with `chmod`
        - reads metadata with `stat` / `file`
        - logs the operation via log_operation.sh
        - prints STATUS=SUCCESS / FILE_NAME=... / FILE_SIZE=... etc.
   -> scriptRunner parses that into a JS object
   -> controller returns it as JSON
   -> frontend re-renders the file table
```

**Search:**

```
"Search" button -> GET /api/personal/files/search?term=report
   -> personal_search.sh <username> <term>
   -> file_search.sh <base_dir> <term>
        find "$base_dir" -type f -iname "*term*" | sort by mtime
   -> KEY=VALUE result list -> JSON -> table in the browser
```

**Server Status:**

```
Dashboard load -> GET /api/server/status
   -> monitoring/server_status.sh
        composes cpu_usage.sh + memory_usage.sh + disk_usage.sh +
        process_status.sh + network_status.sh (each reading /proc,
        `df`, `ps`, `ip`, `ss`) into one aggregate report
```

---

## 4. Security

| Threat                      | Defense                                                              |
|------------------------------|-----------------------------------------------------------------------|
| Path traversal (`../../etc`) | `resolve_within_base()` in `scripts/lib/common.sh` resolves the final path with `realpath -m` and rejects anything outside the allowed base directory, plus rejects `..` and absolute paths outright before even touching the filesystem. |
| Shell/command injection      | The backend never builds a shell string. `scriptRunner` uses Node's `execFile('bash', [scriptPath, ...args])` — arguments go straight into `argv`, so there is no shell to inject into. Scripts themselves always quote variables (`"$var"`) and use `--` before filenames. |
| Client naming an arbitrary script | `scriptRunner.js` has a fixed `OPERATIONS` map from operation name -> script path. The client only ever sends an operation like `PERSONAL_UPLOAD`; it can never supply a script path or filename to execute. |
| Unauthorized file access      | Two layers, always both present: (1) application authorization in the controller (e.g. `getAuthorizedConversation` confirms you're a participant before any script runs) and (2) Linux file permissions (`chmod 0640` on uploaded files, `0750` on storage directories). |
| Oversized uploads             | Enforced in three places: multer's `limits.fileSize`, and again inside `file_upload.sh` via `stat`, and a live `df` check for available disk space. |
| Malicious filenames            | `sanitizeFilename()` in the backend strips path separators and control characters before a filename is ever used; `validate_filename()` in Bash re-checks independently (defense in depth — the script never trusts the caller). |
| Symlink tricks on delete       | `file_delete.sh` explicitly refuses to operate on anything that is a symlink (`[[ -L "$resolved" ]]`). |
| Group file deletion            | Restricted to the group admin only (enforced in `groupsController.js` before `group_delete_file.sh` is ever invoked). |
| Global file deletion           | Restricted to whoever uploaded the file, tracked in the `global_file_metadata` table (Bash has no concept of "ownership", so this check lives entirely in the database/backend). |

---

## 5. Standardized exit codes

Every script in `scripts/` sources `scripts/lib/common.sh` and exits with
one of these codes; the backend's `exitCodes.js` maps them straight to
HTTP statuses.

| Code | Meaning              | HTTP |
|------|----------------------|------|
| 0    | SUCCESS               | 200  |
| 1    | GENERAL_ERROR         | 500  |
| 2    | INVALID_ARGUMENT      | 400  |
| 3    | FILE_NOT_FOUND        | 404  |
| 4    | PERMISSION_DENIED     | 403  |
| 5    | STORAGE_ERROR         | 507  |
| 6    | INVALID_PATH          | 400  |
| 7    | AUTHORIZATION_FAILURE | 403  |

Scripts print machine-readable `KEY=VALUE` lines on stdout (e.g.
`STATUS=SUCCESS`, `FILE_NAME=report.pdf`, `FILE_SIZE=204800`) so the
backend never has to parse fragile human-readable text.

---

## 6. Testing scripts independently from the terminal

Every script works standalone — you don't need the web app running:

```bash
# Provision a user
./scripts/auth/create_user_storage.sh alice

# Upload a file (as if it were already staged by the backend)
echo "hello" > /tmp/hello.txt
./scripts/personal/personal_upload.sh alice /tmp/hello.txt hello.txt

# List / search / inspect / delete
./scripts/personal/personal_list.sh alice
./scripts/personal/personal_search.sh alice hello
./scripts/personal/personal_info.sh alice hello.txt
./scripts/personal/personal_delete.sh alice hello.txt

# Try to break it (should be rejected with exit code 6 / INVALID_PATH)
./scripts/personal/personal_download.sh alice "../../../etc/passwd"

# Server + storage
./scripts/monitoring/server_status.sh
./scripts/storage/storage_usage.sh
./scripts/storage/storage_report.sh

# Backup / restore
./scripts/backup/backup.sh nightly
./scripts/backup/backup_list.sh
./scripts/backup/restore.sh backup_nightly_<timestamp>.tar.gz
```

Then test the full path through the web stack:

```
Browser -> POST /api/... -> scriptRunner -> Bash script -> filesystem
```

---

## 7. The `cloud` command family (terminal integration)

Cloudion ships a dedicated `scripts/cloud/` module so an external custom
terminal can drive it with `cloud <subcommand>` style commands — this was
built to match an integration like **AzTerm**, which defines:

| Command       | Functionality               |
|---------------|------------------------------|
| `cloud start`   | Start Cloudion               |
| `cloud stop`    | Stop Cloudion                |
| `cloud restart` | Restart Cloudion             |
| `cloud status`  | Show Cloudion status         |
| `cloud logs`    | Show recent Cloudion logs    |
| `cloud info`    | Show Cloudion details        |
| `cloud help`    | Show Cloudion's cloud help   |

**Single entry point:** a terminal only ever needs to exec one script —
`scripts/cloud/cloud.sh <subcommand> [args...]` — which routes to a
focused script per subcommand (same "thin dispatcher + focused scripts"
pattern used elsewhere, e.g. `server_status.sh`). So:

```
AzTerm parses:  cloud start
   -> exec:     ./scripts/cloud/cloud.sh start
   -> routes to: ./scripts/cloud/cloud_start.sh
```

| Script | What it does |
|---|---|
| `cloud_start.sh` | Starts the Node backend as a detached background process, writes its real PID to `.cloudion.pid`, fails with exit code 1 if already running |
| `cloud_stop.sh` | Sends `SIGTERM` to the tracked PID (escalates to `SIGKILL` after a short grace period), removes the PID file |
| `cloud_restart.sh` | Calls `cloud_stop.sh` then `cloud_start.sh` (stop failures are tolerated — it may not have been running) |
| `cloud_status.sh` | Reports `CLOUDION_STATE=RUNNING\|STOPPED` (+ PID if running), merged with live CPU/memory/disk/process/network metrics from `monitoring/server_status.sh` |
| `cloud_logs.sh [lines] [category]` | Prints the last N lines (default 30) from a log category (`server` = combined timeline by default) |
| `cloud_info.sh` | Name, version (read from `VERSION`), running state, uptime, and key paths |
| `cloud_help.sh` | Prints the reference table above |

Every one of these is independently runnable too:

```bash
./scripts/cloud/cloud.sh start
./scripts/cloud/cloud.sh status
./scripts/cloud/cloud.sh logs 20 file
./scripts/cloud/cloud.sh stop
```

`cloudctl.sh`'s Start/Stop/Restart menu options and its "Server Status"
option now delegate to these same scripts, so there's exactly one
implementation of "start/stop/restart/status" in the whole project —
`cloudctl.sh` also accepts a passthrough for convenience:
`./cloudctl.sh cloud status`.

A neat detail worth knowing if you're integrating this yourself:
`cloud_start.sh` doesn't just do `node server.js &`, because capturing
`$!` after `setsid CMD &` gives you `setsid`'s own transient PID (it forks
before exec-ing), not the actual `node` process's PID — that PID goes
stale the instant `setsid` hands off, silently breaking `cloud_status.sh`
and `cloud_stop.sh` later. Instead it detaches via a small `bash -c`
wrapper that writes its **own** PID to the PID file and then `exec`s
`node` in place — since `exec` replaces the process image without
forking, the PID that gets written is guaranteed to be `node`'s real PID.

---

## 8. Data model (what lives in the database vs. the filesystem)

**SQLite (`backend/database/cloud.db`)** — users, password hashes, friend
requests/friendships, conversations, group membership, chat messages, and
a small `global_file_metadata` table that records who uploaded each Global
Cloud file (needed for the "only the uploader can delete it" rule, which
Bash has no way to know on its own).

**Filesystem (`storage/`)** — the actual file bytes, organized by area:

```
storage/
├── users/<username>/files/          Personal Cloud
├── one_to_one/conversation_<id>/    shared files per 1:1 conversation
├── groups/group_<id>/files/         shared files per group
├── global/                          shared with every user
└── temporary/uploads/               staging area multer writes to before
                                      a script moves the file into place
```

---

## 9. Known simplifications

This is a learning/demo project, so a few things are intentionally kept
simple rather than production-hardened:

- `JWT_SECRET` defaults to a hardcoded dev value if `JWT_SECRET` isn't set
  in the environment — set a real one before deploying anywhere real.
- The backup/restore/cleanup endpoints under `/api/server` are gated by
  login only, not by a separate admin role — in a real deployment these
  should require an explicit admin permission.
- There's no file-type/virus scanning on uploads.
- `logs/`, `backups/`, and `storage/` are all local disk — a real
  multi-server deployment would need shared/networked storage.

---

## 10. Exit-code-aware error example

If you request a file that doesn't exist:

```bash
$ ./scripts/personal/personal_info.sh alice nonexistent.txt
ERROR: File not found: nonexistent.txt
STATUS=FAILURE
CODE=3
MESSAGE=File not found: nonexistent.txt
$ echo $?
3
```

The backend receives exit code `3`, maps it to HTTP `404` via
`exitCodes.js`, and returns the script's own `MESSAGE` field as the JSON
error body — the same contract for every single script in the project.
