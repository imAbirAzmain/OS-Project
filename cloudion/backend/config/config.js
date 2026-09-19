const path = require('path');

const PROJECT_ROOT = path.resolve(__dirname, '..', '..');

module.exports = {
  PROJECT_ROOT,
  SCRIPTS_ROOT: path.join(PROJECT_ROOT, 'scripts'),
  STORAGE_ROOT: path.join(PROJECT_ROOT, 'storage'),
  BACKUPS_ROOT: path.join(PROJECT_ROOT, 'backups'),
  UPLOAD_STAGING_DIR: path.join(PROJECT_ROOT, 'storage', 'temporary', 'uploads'),
  SERVER_OWNER_USERNAME: process.env.CLOUDION_OWNER || 'root',
  PORT: process.env.PORT || 4000,
  // In a real deployment this MUST come from an environment variable / secret
  // manager, never be hardcoded. It is inlined here only because this is a
  // learning project meant to run standalone with zero external setup.
  JWT_SECRET: process.env.JWT_SECRET || 'dev-only-secret-change-me',
  JWT_EXPIRY: '12h',
  MAX_UPLOAD_BYTES: 500 * 1024 * 1024, // 500 MB, mirrors scripts/files/file_upload.sh
  SCRIPT_TIMEOUT_MS: 15000,
};
