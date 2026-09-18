const fs = require('fs');
const { runScript } = require('../services/scriptRunner');
const { httpStatusForExitCode } = require('../services/scriptRunner/exitCodes');
const { sanitizeFilename } = require('../middleware/upload');
const { sendInline } = require('../services/fileStream');
const { setGlobalOwner, getGlobalOwner, deleteGlobalOwner } = require('../services/fsStore');

async function upload(req, res) {
  if (!req.file) return res.status(400).json({ status: 'FAILURE', message: 'No file uploaded' });
  const destFilename = sanitizeFilename(req.body.filename || req.file.originalname);

  const result = await runScript('GLOBAL_UPLOAD', [req.file.path, destFilename, req.user.username]);
  if (result.exitCode !== 0) {
    if (fs.existsSync(req.file.path)) fs.unlink(req.file.path, () => {});
    return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
  }

  setGlobalOwner(result.data.FILE_NAME, req.user.username);
  return res.status(201).json(result.data);
}

async function list(req, res) {
  const result = await runScript('GLOBAL_LIST', []);
  return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
}

async function search(req, res) {
  const { term = '', extension = '' } = req.query;
  const result = await runScript('GLOBAL_SEARCH', [term, extension]);
  return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
}

async function info(req, res) {
  const result = await runScript('GLOBAL_FILE_INFO', [req.params.filename]);
  return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
}

async function download(req, res) {
  const result = await runScript('GLOBAL_DOWNLOAD', [req.params.filename, req.user.username]);
  if (result.exitCode !== 0) {
    return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
  }
  return res.download(result.data.PATH, result.data.FILE_NAME);
}

async function view(req, res) {
  const result = await runScript('GLOBAL_DOWNLOAD', [req.params.filename, req.user.username]);
  if (result.exitCode !== 0) {
    return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
  }
  return sendInline(res, result);
}

async function del(req, res) {
  const filename = req.params.filename;
  if (getGlobalOwner(filename) !== req.user.username) {
    return res.status(403).json({ status: 'FAILURE', message: 'Only the uploader may delete this file' });
  }

  const result = await runScript('GLOBAL_DELETE', [filename, req.user.username]);
  if (result.exitCode === 0) {
    deleteGlobalOwner(filename);
  }
  return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
}

module.exports = { upload, list, search, info, download, view, del };
