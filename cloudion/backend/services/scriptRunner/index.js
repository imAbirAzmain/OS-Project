// =============================================================================
// scriptRunner — the ONLY place in the backend that is allowed to execute a
// Bash script.
//
// Design rules (see README.md section "Security"):
//   1. The client can never name a script. Every caller passes an
//      `operation` key from the OPERATIONS whitelist below; the actual
//      script path is looked up server-side.
//   2. execFile (not exec/spawn with shell:true) is used, so arguments are
//      passed as an argv array straight to the OS — there is no shell
//      involved, so there is nothing for shell metacharacters to inject
//      into. Even a filename like `; rm -rf /` is just a literal string
//      argument.
//   3. Every invocation has a timeout, so a hung/misbehaving script cannot
//      hang an HTTP request forever.
//   4. stdout is parsed as KEY=VALUE lines into a plain object; exit code
//      is preserved so controllers can map it to an HTTP status using the
//      standardized exit-code contract in scripts/lib/common.sh.
// =============================================================================
const { execFile } = require('child_process');
const path = require('path');
const { SCRIPTS_ROOT, SCRIPT_TIMEOUT_MS } = require('../../config/config');

// Fixed, server-side whitelist: operation name -> script path (relative to
// SCRIPTS_ROOT). This is the single source of truth for "what Bash scripts
// this application is allowed to run."
const OPERATIONS = {
  // auth / user lifecycle
  CREATE_USER_STORAGE: 'auth/create_user_storage.sh',
  DELETE_USER_STORAGE: 'auth/delete_user_storage.sh',

  // personal cloud
  PERSONAL_UPLOAD: 'personal/personal_upload.sh',
  PERSONAL_DOWNLOAD: 'personal/personal_download.sh',
  PERSONAL_DELETE: 'personal/personal_delete.sh',
  PERSONAL_SEARCH: 'personal/personal_search.sh',
  PERSONAL_LIST: 'personal/personal_list.sh',
  PERSONAL_INFO: 'personal/personal_info.sh',

  // one-to-one cloud
  CONVERSATION_CREATE: 'one_to_one/conversation_create.sh',
  ONE_TO_ONE_UPLOAD: 'one_to_one/one_to_one_upload.sh',
  ONE_TO_ONE_DOWNLOAD: 'one_to_one/one_to_one_download.sh',
  ONE_TO_ONE_DELETE: 'one_to_one/one_to_one_delete.sh',
  ONE_TO_ONE_SEARCH: 'one_to_one/one_to_one_search.sh',
  ONE_TO_ONE_LIST: 'one_to_one/one_to_one_list.sh',
  ONE_TO_ONE_FILE_INFO: 'one_to_one/one_to_one_file_info.sh',

  // group cloud
  CREATE_GROUP_STORAGE: 'groups/create_group_storage.sh',
  DELETE_GROUP_STORAGE: 'groups/delete_group_storage.sh',
  GROUP_UPLOAD: 'groups/group_upload.sh',
  GROUP_DOWNLOAD: 'groups/group_download.sh',
  GROUP_DELETE_FILE: 'groups/group_delete_file.sh',
  GROUP_SEARCH: 'groups/group_search.sh',
  GROUP_LIST_FILES: 'groups/group_list_files.sh',
  GROUP_FILE_INFO: 'groups/group_file_info.sh',

  // global cloud
  GLOBAL_UPLOAD: 'global/global_upload.sh',
  GLOBAL_DOWNLOAD: 'global/global_download.sh',
  GLOBAL_DELETE: 'global/global_delete.sh',
  GLOBAL_SEARCH: 'global/global_search.sh',
  GLOBAL_LIST: 'global/global_list.sh',
  GLOBAL_FILE_INFO: 'global/global_file_info.sh',

  // storage & monitoring
  STORAGE_USAGE: 'storage/storage_usage.sh',
  STORAGE_REPORT: 'storage/storage_report.sh',
  SERVER_STATUS: 'monitoring/server_status.sh',

  // backup
  BACKUP_CREATE: 'backup/backup.sh',
  BACKUP_LIST: 'backup/backup_list.sh',
  BACKUP_RESTORE: 'backup/restore.sh',
  BACKUP_DELETE: 'backup/backup_delete.sh',

  // maintenance
  CLEANUP_TEMP: 'maintenance/cleanup_temp.sh',
  CLEANUP_LOGS: 'maintenance/cleanup_old_logs.sh',
};

function parseKeyValueOutput(stdout) {
  const result = {};
  const lines = stdout.split('\n');
  for (const line of lines) {
    const idx = line.indexOf('=');
    if (idx === -1) continue;
    const key = line.slice(0, idx);
    const value = line.slice(idx + 1);
    result[key] = value;
  }
  return result;
}

/**
 * Run a whitelisted Bash script.
 * @param {string} operation - key into OPERATIONS
 * @param {string[]} args - positional arguments (never user-controlled shell syntax; passed as argv)
 * @returns {Promise<{exitCode:number, data:object, stderr:string}>}
 */
function runScript(operation, args = []) {
  const relativeScriptPath = OPERATIONS[operation];
  if (!relativeScriptPath) {
    return Promise.reject(new Error(`Unknown script operation: ${operation}`));
  }
  const scriptPath = path.join(SCRIPTS_ROOT, relativeScriptPath);

  // Defensive: args must be strings/numbers, never objects — this keeps the
  // argv array literal and prevents any accidental injection surface.
  const safeArgs = args.map((a) => String(a));

  return new Promise((resolve) => {
    execFile(
      'bash',
      [scriptPath, ...safeArgs],
      { timeout: SCRIPT_TIMEOUT_MS, maxBuffer: 10 * 1024 * 1024 },
      (error, stdout, stderr) => {
        const exitCode = error && typeof error.code === 'number' ? error.code : 0;
        resolve({
          exitCode,
          data: parseKeyValueOutput(stdout || ''),
          stderr: stderr || '',
          timedOut: Boolean(error && error.killed),
        });
      }
    );
  });
}

module.exports = { runScript, OPERATIONS };
