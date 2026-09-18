const fs = require('fs');
const path = require('path');
const { STORAGE_ROOT } = require('../config/config');

const USERS_ROOT = path.join(STORAGE_ROOT, 'users');
const GROUPS_ROOT = path.join(STORAGE_ROOT, 'groups');
const GROUP_META_ROOT = path.join(STORAGE_ROOT, 'groups_meta');
const CONVERSATIONS_ROOT = path.join(STORAGE_ROOT, 'conversations');
const ONE_TO_ONE_STORAGE_ROOT = path.join(STORAGE_ROOT, 'one_to_one');
const GLOBAL_ROOT = path.join(STORAGE_ROOT, 'global');
const ACCOUNTS_ROOT = path.join(STORAGE_ROOT, 'accounts');

function ensureDir(dirPath) {
  fs.mkdirSync(dirPath, { recursive: true });
}

function readJson(filePath, fallback = null) {
  try {
    const raw = fs.readFileSync(filePath, 'utf8');
    return raw ? JSON.parse(raw) : fallback;
  } catch (err) {
    return fallback;
  }
}

function writeJson(filePath, value) {
  ensureDir(path.dirname(filePath));
  fs.writeFileSync(filePath, JSON.stringify(value, null, 2));
}

function userDir(username) {
  return path.join(USERS_ROOT, username);
}

function userMetaPath(username) {
  return path.join(ACCOUNTS_ROOT, `${username}.json`);
}

function userFriendsPath(username) {
  return path.join(userDir(username), 'friends.json');
}

function userRequestsPath(username) {
  return path.join(userDir(username), 'requests.json');
}

function groupDir(groupId) {
  return path.join(GROUPS_ROOT, String(groupId));
}

function groupMetaPath(groupId) {
  return path.join(GROUP_META_ROOT, `group-${groupId}.json`);
}

function conversationFile(a, b) {
  const [left, right] = [String(a), String(b)].sort();
  return path.join(CONVERSATIONS_ROOT, `${left}__${right}.json`);
}

function conversationStorageDir(conversationId) {
  return path.join(ONE_TO_ONE_STORAGE_ROOT, `conversation_${conversationId}`);
}

function ensureUser(username) {
  ensureDir(ACCOUNTS_ROOT);
  const metaPath = userMetaPath(username);
  const existing = readJson(metaPath, null);
  if (!existing) {
    writeJson(metaPath, {
      username,
      password_hash: '',
      friends: [],
      incoming_requests: [],
      outgoing_requests: [],
      created_at: new Date().toISOString(),
    });
  }
  return true;
}

function createUserAccount(username, passwordHash) {
  ensureDir(USERS_ROOT);
  ensureUser(username);
  const meta = readJson(userMetaPath(username), { username, password_hash: '', friends: [] });
  meta.password_hash = passwordHash;
  writeJson(userMetaPath(username), meta);
  return { username, password_hash: passwordHash };
}

function getUser(username) {
  const metaPath = userMetaPath(username);
  const meta = readJson(metaPath, null);
  if (!meta) return null;
  return {
    username: meta.username,
    password_hash: meta.password_hash,
    created_at: meta.created_at,
    friends: Array.isArray(meta.friends) ? meta.friends : [],
    incoming_requests: Array.isArray(meta.incoming_requests) ? meta.incoming_requests : [],
    outgoing_requests: Array.isArray(meta.outgoing_requests) ? meta.outgoing_requests : [],
  };
}

function deleteUserAccount(username) {
  const metaPath = userMetaPath(username);
  if (fs.existsSync(metaPath)) {
    fs.rmSync(metaPath, { force: true });
  }
  return true;
}

function listUsers() {
  ensureDir(ACCOUNTS_ROOT);
  return fs.readdirSync(ACCOUNTS_ROOT)
    .filter((name) => name.endsWith('.json'))
    .map((name) => name.replace(/\.json$/, ''))
    .sort();
}

function normalizeFriendsList(list) {
  return Array.from(new Set((list || []).filter(Boolean))).sort();
}

function getUserFriends(username) {
  const meta = readJson(userMetaPath(username), { friends: [] });
  return normalizeFriendsList(meta.friends || []);
}

function saveUserFriends(username, friends) {
  const meta = readJson(userMetaPath(username), { username, friends: [] });
  meta.friends = normalizeFriendsList(friends);
  writeJson(userMetaPath(username), meta);
}

function saveUserRequests(username, data) {
  const meta = readJson(userMetaPath(username), { username, incoming_requests: [], outgoing_requests: [] });
  meta.incoming_requests = Array.isArray(data.incoming) ? data.incoming : [];
  meta.outgoing_requests = Array.isArray(data.outgoing) ? data.outgoing : [];
  writeJson(userMetaPath(username), meta);
}

function addFriendRelation(userA, userB) {
  const aFriends = getUserFriends(userA);
  const bFriends = getUserFriends(userB);
  saveUserFriends(userA, [...aFriends, userB]);
  saveUserFriends(userB, [...bFriends, userA]);
  return true;
}

function isFriend(userA, userB) {
  return getUserFriends(userA).includes(userB);
}

function listIncomingRequests(username) {
  const meta = readJson(userMetaPath(username), { incoming_requests: [] });
  return Array.isArray(meta.incoming_requests) ? meta.incoming_requests : [];
}

function listOutgoingRequests(username) {
  const meta = readJson(userMetaPath(username), { outgoing_requests: [] });
  return Array.isArray(meta.outgoing_requests) ? meta.outgoing_requests : [];
}

function addFriendRequest(fromUser, toUser) {
  const fromMeta = readJson(userMetaPath(fromUser), { username: fromUser, outgoing_requests: [] });
  const toMeta = readJson(userMetaPath(toUser), { username: toUser, incoming_requests: [] });
  const request = {
    id: `${Date.now()}-${Math.random().toString(16).slice(2)}`,
    from_username: fromUser,
    to_username: toUser,
    created_at: new Date().toISOString(),
    status: 'pending',
  };

  fromMeta.outgoing_requests = Array.isArray(fromMeta.outgoing_requests) ? fromMeta.outgoing_requests : [];
  toMeta.incoming_requests = Array.isArray(toMeta.incoming_requests) ? toMeta.incoming_requests : [];

  if (!fromMeta.outgoing_requests.some((entry) => entry.to_username === toUser && entry.status === 'pending')) {
    fromMeta.outgoing_requests.push({ ...request, from_username: fromUser, to_username: toUser });
  }
  if (!toMeta.incoming_requests.some((entry) => entry.from_username === fromUser && entry.status === 'pending')) {
    toMeta.incoming_requests.push({ ...request, from_username: fromUser, to_username: toUser });
  }

  writeJson(userMetaPath(fromUser), fromMeta);
  writeJson(userMetaPath(toUser), toMeta);
  return request;
}

function respondToFriendRequest(username, requestId, accepted) {
  const meta = readJson(userMetaPath(username), { incoming_requests: [] });
  meta.incoming_requests = (meta.incoming_requests || []).map((request) => {
    if (request.id === requestId) return { ...request, status: accepted ? 'accepted' : 'rejected' };
    return request;
  });
  writeJson(userMetaPath(username), meta);

  if (accepted) {
    const target = meta.incoming_requests.find((request) => request.id === requestId);
    if (target) addFriendRelation(username, target.from_username);
  }

  return true;
}

function createConversation(userA, userB) {
  if (!isFriend(userA, userB)) return null;
  const [left, right] = [String(userA), String(userB)].sort();
  const convId = `${left}__${right}`;
  const key = conversationFile(userA, userB);
  ensureDir(path.dirname(key));
  if (!fs.existsSync(key)) {
    writeJson(key, {
      id: convId,
      participants: [left, right],
      messages: [],
    });
  }
  // Ensure physical storage folder exists for file uploads in 1:1 conversation
  ensureDir(conversationStorageDir(convId));
  return convId;
}

function getConversation(userA, userB) {
  const key = conversationFile(userA, userB);
  return readJson(key, null);
}

function listConversationsForUser(username) {
  ensureDir(CONVERSATIONS_ROOT);
  const files = fs.readdirSync(CONVERSATIONS_ROOT).filter((name) => name.endsWith('.json'));
  return files
    .map((name) => readJson(path.join(CONVERSATIONS_ROOT, name), null))
    .filter((entry) => entry && Array.isArray(entry.participants) && entry.participants.includes(username))
    .map((entry) => ({ id: entry.id, with_username: entry.participants.find((p) => p !== username), created_at: entry.created_at || new Date().toISOString() }));
}

function appendConversationMessage(userA, userB, sender, content) {
  const [left, right] = [String(userA), String(userB)].sort();
  const convId = `${left}__${right}`;
  const conv = getConversation(userA, userB) || {
    id: convId,
    participants: [left, right],
    messages: [],
  };
  conv.messages = Array.isArray(conv.messages) ? conv.messages : [];
  conv.messages.push({
    id: `${Date.now()}-${Math.random().toString(16).slice(2)}`,
    sender,
    content,
    created_at: new Date().toISOString(),
    message_type: 'text',
  });
  writeJson(conversationFile(userA, userB), conv);
  return conv.messages[conv.messages.length - 1];
}

function appendConversationFileMessage(userA, userB, sender, fileInfo) {
  const [left, right] = [String(userA), String(userB)].sort();
  const convId = `${left}__${right}`;
  const conv = getConversation(userA, userB) || {
    id: convId,
    participants: [left, right],
    messages: [],
  };
  conv.messages = Array.isArray(conv.messages) ? conv.messages : [];
  conv.messages.push({
    id: `${Date.now()}-${Math.random().toString(16).slice(2)}`,
    sender,
    message_type: 'file',
    file_name: fileInfo.FILE_NAME,
    relative_path: fileInfo.RELATIVE_PATH,
    created_at: new Date().toISOString(),
  });
  writeJson(conversationFile(userA, userB), conv);
  return conv.messages[conv.messages.length - 1];
}

function conversationMessages(userA, userB) {
  const conv = getConversation(userA, userB) || { messages: [] };
  return Array.isArray(conv.messages) ? conv.messages : [];
}

function isConversationParticipant(username, conversationId) {
  const parts = String(conversationId).split('__');
  return parts.includes(username);
}

function ensureGroupStorage(groupId) {
  const dir = groupDir(groupId);
  ensureDir(dir);
  const metaPath = groupMetaPath(groupId);
  if (!fs.existsSync(metaPath)) {
    writeJson(metaPath, { id: String(groupId), name: `group-${groupId}`, admin: null, admin_id: null, members: [], created_at: new Date().toISOString() });
  }
  ensureDir(path.join(dir, 'files'));
  return dir;
}

function createGroupRecord(groupName, adminUsername) {
  ensureDir(GROUP_META_ROOT);
  const existingIds = fs.readdirSync(GROUP_META_ROOT)
    .filter((name) => name.endsWith('.json'))
    .map((name) => Number(name.replace(/^group-/, '').replace(/\.json$/, '')) || 0);
  const id = existingIds.length ? Math.max(...existingIds) + 1 : 1;
  const meta = { id: String(id), name: groupName, admin: adminUsername, admin_id: adminUsername, members: [adminUsername], created_at: new Date().toISOString() };
  writeJson(groupMetaPath(id), meta);
  return { id: String(id), name: groupName, admin: adminUsername, admin_id: adminUsername, members: [adminUsername] };
}

function listGroupsForUser(username) {
  ensureDir(GROUP_META_ROOT);
  const files = fs.readdirSync(GROUP_META_ROOT).filter((name) => name.endsWith('.json'));
  const groups = files.map((file) => readJson(path.join(GROUP_META_ROOT, file), null)).filter(Boolean);
  return groups.filter((group) => Array.isArray(group.members) && group.members.includes(username)).map((group) => ({
    id: Number(group.id),
    name: group.name,
    admin: group.admin || group.admin_id,
    admin_id: group.admin_id || group.admin,
    role: (group.admin === username || group.admin_id === username) ? 'admin' : 'member',
  }));
}

function getGroup(groupId) {
  const meta = readJson(groupMetaPath(groupId), null);
  return meta ? {
    id: Number(meta.id),
    name: meta.name,
    admin: meta.admin || meta.admin_id,
    admin_id: meta.admin_id || meta.admin,
    members: meta.members || [],
  } : null;
}

function addGroupMember(groupId, username) {
  const meta = readJson(groupMetaPath(groupId), { members: [] });
  meta.members = Array.isArray(meta.members) ? meta.members : [];
  if (!meta.members.includes(username)) meta.members.push(username);
  writeJson(groupMetaPath(groupId), meta);
  return true;
}

function removeGroupMember(groupId, username) {
  const meta = readJson(groupMetaPath(groupId), { members: [] });
  meta.members = (meta.members || []).filter((member) => member !== username);
  writeJson(groupMetaPath(groupId), meta);
  return true;
}

function groupMembers(groupId) {
  const meta = readJson(groupMetaPath(groupId), { members: [] });
  return Array.isArray(meta.members) ? meta.members : [];
}

function getGroupMessages(groupId) {
  const pathName = path.join(groupDir(groupId), 'messages.json');
  return readJson(pathName, []);
}

function addGroupMessage(groupId, sender, content) {
  const messages = getGroupMessages(groupId);
  const entry = {
    id: `${Date.now()}-${Math.random().toString(16).slice(2)}`,
    sender,
    content,
    created_at: new Date().toISOString(),
    message_type: 'text',
  };
  messages.push(entry);
  writeJson(path.join(groupDir(groupId), 'messages.json'), messages);
  return entry;
}

function addGroupFileMessage(groupId, sender, fileInfo) {
  const messages = getGroupMessages(groupId);
  messages.push({
    id: `${Date.now()}-${Math.random().toString(16).slice(2)}`,
    sender,
    file_name: fileInfo.FILE_NAME,
    relative_path: fileInfo.RELATIVE_PATH,
    created_at: new Date().toISOString(),
    message_type: 'file',
  });
  writeJson(path.join(groupDir(groupId), 'messages.json'), messages);
}

function globalOwnersFile() {
  ensureDir(GLOBAL_ROOT);
  const hiddenFile = path.join(GLOBAL_ROOT, '.owners.json');
  const legacyFile = path.join(GLOBAL_ROOT, 'owners.json');
  if (fs.existsSync(legacyFile) && !fs.existsSync(hiddenFile)) {
    try { fs.renameSync(legacyFile, hiddenFile); } catch (e) {}
  }
  const target = fs.existsSync(hiddenFile) ? hiddenFile : (fs.existsSync(legacyFile) ? legacyFile : hiddenFile);
  if (!fs.existsSync(target)) writeJson(target, {});
  return target;
}

function setGlobalOwner(filename, username) {
  const owners = readJson(globalOwnersFile(), {});
  owners[filename] = username;
  writeJson(globalOwnersFile(), owners);
}

function getGlobalOwner(filename) {
  const owners = readJson(globalOwnersFile(), {});
  return owners[filename] || null;
}

function deleteGlobalOwner(filename) {
  const owners = readJson(globalOwnersFile(), {});
  delete owners[filename];
  writeJson(globalOwnersFile(), owners);
}

module.exports = {
  ensureUser,
  createUserAccount,
  getUser,
  deleteUserAccount,
  listUsers,
  addFriendRequest,
  listIncomingRequests,
  listOutgoingRequests,
  respondToFriendRequest,
  getUserFriends,
  saveUserFriends,
  addFriendRelation,
  isFriend,
  createConversation,
  getConversation,
  listConversationsForUser,
  appendConversationMessage,
  appendConversationFileMessage,
  conversationMessages,
  isConversationParticipant,
  conversationStorageDir,
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
  setGlobalOwner,
  getGlobalOwner,
  deleteGlobalOwner,
  userDir,
  userMetaPath,
  groupDir,
  groupMetaPath,
  converter: { path },
};
