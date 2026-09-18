const { runScript } = require('../services/scriptRunner');
const { httpStatusForExitCode } = require('../services/scriptRunner/exitCodes');

async function status(req, res) {
  const result = await runScript('SERVER_STATUS', []);
  return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
}

async function storage(req, res) {
  const result = await runScript('STORAGE_USAGE', []);
  return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
}

async function storageReport(req, res) {
  const result = await runScript('STORAGE_REPORT', []);
  return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
}

async function createBackup(req, res) {
  const label = (req.body && req.body.label) || 'manual';
  const result = await runScript('BACKUP_CREATE', [label]);
  return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
}

async function listBackups(req, res) {
  const result = await runScript('BACKUP_LIST', []);
  return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
}

async function restoreBackup(req, res) {
  const { archiveName } = req.body || {};
  if (!archiveName) return res.status(400).json({ status: 'FAILURE', message: 'archiveName is required' });
  const result = await runScript('BACKUP_RESTORE', [archiveName]);
  return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
}

async function cleanup(req, res) {
  const tempResult = await runScript('CLEANUP_TEMP', []);
  const logsResult = await runScript('CLEANUP_LOGS', []);
  return res.json({
    status: 'SUCCESS',
    tempCleanup: tempResult.data,
    logsCleanup: logsResult.data,
  });
}

module.exports = { status, storage, storageReport, createBackup, listBackups, restoreBackup, cleanup };
