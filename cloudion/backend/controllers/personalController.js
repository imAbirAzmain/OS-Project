const fs = require('fs');
const { runScript } = require('../services/scriptRunner');
const { httpStatusForExitCode } = require('../services/scriptRunner/exitCodes');
const { sanitizeFilename } = require('../middleware/upload');
const { sendInline } = require('../services/fileStream');

// Every handler below follows the same shape:
//   1. Backend already knows req.user (via requireAuth) -> that IS the
//      authorization check for Personal Cloud: a user can only ever act on
//      their own username-scoped storage area, so there is nothing further
//      to verify here.
//   2. Delegate the actual filesystem work to a whitelisted Bash script.
//   3. Map the script's exit code to an HTTP status and return its
//      KEY=VALUE output as JSON.

async function upload(req, res) {
  if (!req.file) {
    return res.status(400).json({ status: 'FAILURE', message: 'No file uploaded' });
  }
  const destFilename = sanitizeFilename(req.body.filename || req.file.originalname);
  const result = await runScript('PERSONAL_UPLOAD', [req.user.username, req.file.path, destFilename]);
  cleanupStagingOnFailure(result, req.file.path);
  return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
}

async function list(req, res) {
  const result = await runScript('PERSONAL_LIST', [req.user.username]);
  return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
}

async function search(req, res) {
  const { term = '', extension = '' } = req.query;
  const result = await runScript('PERSONAL_SEARCH', [req.user.username, term, extension]);
  return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
}

async function info(req, res) {
  const result = await runScript('PERSONAL_INFO', [req.user.username, req.params.filename]);
  return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
}

async function download(req, res) {
  const result = await runScript('PERSONAL_DOWNLOAD', [req.user.username, req.params.filename]);
  if (result.exitCode !== 0) {
    return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
  }
  // The backend streams the validated path; it never lets the client
  // supply a path directly to res.sendFile / res.download.
  return res.download(result.data.PATH, result.data.FILE_NAME);
}

async function view(req, res) {
  // Same validation script as download — only the response headers differ.
  const result = await runScript('PERSONAL_DOWNLOAD', [req.user.username, req.params.filename]);
  if (result.exitCode !== 0) {
    return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
  }
  return sendInline(res, result);
}

async function del(req, res) {
  const result = await runScript('PERSONAL_DELETE', [req.user.username, req.params.filename]);
  return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
}

function cleanupStagingOnFailure(result, stagedPath) {
  if (result.exitCode !== 0 && fs.existsSync(stagedPath)) {
    fs.unlink(stagedPath, () => {});
  }
}

module.exports = { upload, list, search, info, download, view, del };
