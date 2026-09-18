const fs = require('fs');
const { runScript } = require('../services/scriptRunner');
const { httpStatusForExitCode } = require('../services/scriptRunner/exitCodes');
const { sanitizeFilename } = require('../middleware/upload');
const { sendInline } = require('../services/fileStream');
const {
  createGroupRecord,
  ensureGroupStorage,
  listGroupsForUser,
  getGroup,
  addGroupMember,
  removeGroupMember,
  groupMembers,
  getGroupMessages,
  addGroupMessage,
  addGroupFileMessage,
  getUser,
} = require('../services/fsStore');

function getMembership(groupId, username) {
  const group = getGroup(groupId);
  if (!group) return null;
  const isAdmin = group.admin === username || group.admin_id === username;
  return group.members.includes(username) ? { role: isAdmin ? 'admin' : 'member' } : null;
}

function getAuthorizedGroup(req, res, { requireAdmin = false } = {}) {
  const groupId = Number(req.params.id);
  const group = getGroup(groupId);
  if (!group) {
    res.status(404).json({ status: 'FAILURE', message: 'Group not found' });
    return null;
  }
  const membership = getMembership(groupId, req.user.username);
  if (!membership) {
    res.status(403).json({ status: 'FAILURE', message: 'You are not a member of this group' });
    return null;
  }
  if (requireAdmin && membership.role !== 'admin') {
    res.status(403).json({ status: 'FAILURE', message: 'Only the group admin can perform this action' });
    return null;
  }
  return group;
}

async function listGroups(req, res) {
  const rows = listGroupsForUser(req.user.username);
  return res.json({ status: 'SUCCESS', groups: rows });
}

async function createGroup(req, res) {
  const { name } = req.body || {};
  if (!name || !name.trim()) {
    return res.status(400).json({ status: 'FAILURE', message: 'Group name is required' });
  }

  const group = createGroupRecord(name.trim(), req.user.username);
  ensureGroupStorage(group.id);
  const result = await runScript('CREATE_GROUP_STORAGE', [group.id]);
  if (result.exitCode !== 0) {
    return res.status(500).json({ status: 'FAILURE', message: 'Failed to provision group storage' });
  }
  return res.status(201).json({ status: 'SUCCESS', groupId: Number(group.id) });
}

async function deleteGroup(req, res) {
  const group = getAuthorizedGroup(req, res, { requireAdmin: true });
  if (!group) return;
  const result = await runScript('DELETE_GROUP_STORAGE', [group.id]);
  if (result.exitCode !== 0) {
    return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
  }
  return res.json({ status: 'SUCCESS', message: 'Group deleted' });
}

async function addMember(req, res) {
  const group = getAuthorizedGroup(req, res, { requireAdmin: true });
  if (!group) return;
  const { username } = req.body || {};
  const target = getUser(username);
  if (!target) return res.status(404).json({ status: 'FAILURE', message: 'User not found' });
  if (groupMembers(group.id).includes(username)) {
    return res.status(409).json({ status: 'FAILURE', message: 'User is already a member' });
  }
  addGroupMember(group.id, username);
  return res.status(201).json({ status: 'SUCCESS', message: 'Member added' });
}

async function removeMember(req, res) {
  const group = getAuthorizedGroup(req, res, { requireAdmin: true });
  if (!group) return;
  const username = req.params.username;
  if (group.admin_id === username || group.admin === username) {
    return res.status(400).json({ status: 'FAILURE', message: 'Cannot remove the group admin' });
  }
  removeGroupMember(group.id, username);
  return res.json({ status: 'SUCCESS', message: 'Member removed' });
}

async function listMembers(req, res) {
  const group = getAuthorizedGroup(req, res);
  if (!group) return;
  const rows = groupMembers(group.id).map((username) => ({ username, role: (group.admin_id === username || group.admin === username) ? 'admin' : 'member' }));
  return res.json({ status: 'SUCCESS', members: rows });
}

async function listGroupMessages(req, res) {
  const group = getAuthorizedGroup(req, res);
  if (!group) return;
  return res.json({ status: 'SUCCESS', messages: getGroupMessages(group.id) });
}

async function sendGroupMessage(req, res) {
  const group = getAuthorizedGroup(req, res);
  if (!group) return;
  const { content } = req.body || {};
  if (!content || !content.trim()) {
    return res.status(400).json({ status: 'FAILURE', message: 'Message content is required' });
  }
  addGroupMessage(group.id, req.user.username, content.trim());
  return res.status(201).json({ status: 'SUCCESS' });
}

async function uploadFile(req, res) {
  const group = getAuthorizedGroup(req, res);
  if (!group) return;
  if (!req.file) return res.status(400).json({ status: 'FAILURE', message: 'No file uploaded' });

  const destFilename = sanitizeFilename(req.body.filename || req.file.originalname);
  const result = await runScript('GROUP_UPLOAD', [group.id, req.file.path, destFilename, req.user.username]);
  if (result.exitCode !== 0) {
    if (fs.existsSync(req.file.path)) fs.unlink(req.file.path, () => {});
    return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
  }
  addGroupFileMessage(group.id, req.user.username, result.data);
  return res.status(201).json(result.data);
}

async function listFiles(req, res) {
  const group = getAuthorizedGroup(req, res);
  if (!group) return;
  const result = await runScript('GROUP_LIST_FILES', [group.id]);
  return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
}

async function searchFiles(req, res) {
  const group = getAuthorizedGroup(req, res);
  if (!group) return;
  const { term = '', extension = '' } = req.query;
  const result = await runScript('GROUP_SEARCH', [group.id, term, extension]);
  return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
}

async function fileInfo(req, res) {
  const group = getAuthorizedGroup(req, res);
  if (!group) return;
  const result = await runScript('GROUP_FILE_INFO', [group.id, req.params.filename]);
  return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
}

async function downloadFile(req, res) {
  const group = getAuthorizedGroup(req, res);
  if (!group) return;
  const result = await runScript('GROUP_DOWNLOAD', [group.id, req.params.filename, req.user.username]);
  if (result.exitCode !== 0) return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
  return res.download(result.data.PATH, result.data.FILE_NAME);
}

async function viewFile(req, res) {
  const group = getAuthorizedGroup(req, res);
  if (!group) return;
  const result = await runScript('GROUP_DOWNLOAD', [group.id, req.params.filename, req.user.username]);
  if (result.exitCode !== 0) return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
  return sendInline(res, result);
}

async function deleteFile(req, res) {
  const group = getAuthorizedGroup(req, res, { requireAdmin: true });
  if (!group) return;
  const result = await runScript('GROUP_DELETE_FILE', [group.id, req.params.filename, req.user.username]);
  return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
}

module.exports = {
  listGroups,
  createGroup,
  deleteGroup,
  addMember,
  removeMember,
  listMembers,
  listGroupMessages,
  sendGroupMessage,
  uploadFile,
  listFiles,
  searchFiles,
  fileInfo,
  downloadFile,
  viewFile,
  deleteFile,
};
