const fs = require('fs');
const { runScript } = require('../services/scriptRunner');
const { httpStatusForExitCode } = require('../services/scriptRunner/exitCodes');
const { sanitizeFilename } = require('../middleware/upload');
const { sendInline } = require('../services/fileStream');
const {
  isFriend,
  createConversation: createDirectConversation,
  listConversationsForUser,
  conversationMessages,
  appendConversationMessage,
  appendConversationFileMessage,
  setConversationFileOwner,
  getConversationFileOwner,
  deleteConversationFileOwner,
} = require('../services/fsStore');

function getAuthorizedConversation(req, res) {
  const conversationId = req.params.id;
  const [left, right] = String(conversationId).split('__');
  if (!left || !right) {
    res.status(404).json({ status: 'FAILURE', message: 'Conversation not found' });
    return null;
  }
  const participants = [left, right];
  if (!participants.includes(req.user.username)) {
    res.status(403).json({ status: 'FAILURE', message: 'You are not a participant in this conversation' });
    return null;
  }
  return { id: conversationId, participants };
}

async function listConversations(req, res) {
  const rows = listConversationsForUser(req.user.username);
  return res.json({ status: 'SUCCESS', conversations: rows });
}

async function createConversation(req, res) {
  const { username } = req.body || {};
  if (!username) return res.status(400).json({ status: 'FAILURE', message: 'Username is required' });
  if (!isFriend(req.user.username, username)) {
    return res.status(403).json({ status: 'FAILURE', message: 'You can only message accepted friends' });
  }
  const conversationId = createDirectConversation(req.user.username, username);
  if (!conversationId) {
    return res.status(500).json({ status: 'FAILURE', message: 'Failed to provision conversation storage' });
  }
  return res.status(201).json({ status: 'SUCCESS', conversationId });
}

async function listMessages(req, res) {
  const conversation = getAuthorizedConversation(req, res);
  if (!conversation) return;
  const rows = conversationMessages(conversation.participants[0], conversation.participants[1]);
  return res.json({ status: 'SUCCESS', messages: rows });
}

async function sendMessage(req, res) {
  const conversation = getAuthorizedConversation(req, res);
  if (!conversation) return;
  const { content } = req.body || {};
  if (!content || !content.trim()) {
    return res.status(400).json({ status: 'FAILURE', message: 'Message content is required' });
  }
  appendConversationMessage(conversation.participants[0], conversation.participants[1], req.user.username, content.trim());
  return res.status(201).json({ status: 'SUCCESS' });
}

async function uploadFile(req, res) {
  const conversation = getAuthorizedConversation(req, res);
  if (!conversation) return;
  if (!req.file) return res.status(400).json({ status: 'FAILURE', message: 'No file uploaded' });

  const destFilename = sanitizeFilename(req.body.filename || req.file.originalname);
  const result = await runScript('ONE_TO_ONE_UPLOAD', [
    conversation.id,
    req.file.path,
    destFilename,
    req.user.username,
  ]);
  if (result.exitCode !== 0) {
    if (fs.existsSync(req.file.path)) fs.unlink(req.file.path, () => {});
    return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
  }

  setConversationFileOwner(conversation.id, result.data.FILE_NAME, req.user.username);
  appendConversationFileMessage(conversation.participants[0], conversation.participants[1], req.user.username, result.data);
  return res.status(201).json(result.data);
}

async function listFiles(req, res) {
  const conversation = getAuthorizedConversation(req, res);
  if (!conversation) return;
  const result = await runScript('ONE_TO_ONE_LIST', [conversation.id]);
  return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
}

async function searchFiles(req, res) {
  const conversation = getAuthorizedConversation(req, res);
  if (!conversation) return;
  const { term = '', extension = '' } = req.query;
  const result = await runScript('ONE_TO_ONE_SEARCH', [conversation.id, term, extension]);
  return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
}

async function downloadFile(req, res) {
  const conversation = getAuthorizedConversation(req, res);
  if (!conversation) return;
  const result = await runScript('ONE_TO_ONE_DOWNLOAD', [
    conversation.id,
    req.params.filename,
    req.user.username,
  ]);
  if (result.exitCode !== 0) return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
  return res.download(result.data.PATH, result.data.FILE_NAME);
}

async function viewFile(req, res) {
  const conversation = getAuthorizedConversation(req, res);
  if (!conversation) return;
  const result = await runScript('ONE_TO_ONE_DOWNLOAD', [
    conversation.id,
    req.params.filename,
    req.user.username,
  ]);
  if (result.exitCode !== 0) return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
  return sendInline(res, result);
}

async function deleteFile(req, res) {
  const conversation = getAuthorizedConversation(req, res);
  if (!conversation) return;

  const filename = req.params.filename;
  const sender = getConversationFileOwner(conversation.id, filename);
  if (sender && sender !== req.user.username) {
    return res.status(403).json({
      status: 'FAILURE',
      message: 'Only the sender who uploaded this file may delete it',
    });
  }

  const result = await runScript('ONE_TO_ONE_DELETE', [
    conversation.id,
    filename,
    req.user.username,
  ]);
  if (result.exitCode === 0) {
    deleteConversationFileOwner(conversation.id, filename);
  }
  return res.status(httpStatusForExitCode(result.exitCode)).json(result.data);
}

module.exports = {
  listConversations,
  createConversation,
  listMessages,
  sendMessage,
  uploadFile,
  listFiles,
  searchFiles,
  downloadFile,
  viewFile,
  deleteFile,
};
