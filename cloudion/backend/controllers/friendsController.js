const {
  getUser,
  listUsers,
  getUserFriends,
  addFriendRequest,
  listIncomingRequests,
  listOutgoingRequests,
  respondToFriendRequest,
  addFriendRelation,
  removeFriendRelation,
  isFriend,
} = require('../services/fsStore');

function searchUsers(req, res) {
  const q = (req.query.q || '').trim();
  if (!q) return res.json({ status: 'SUCCESS', users: [] });
  const users = listUsers().filter((u) => u !== req.user.username && u.toLowerCase().includes(q.toLowerCase())).slice(0, 20);
  return res.json({ status: 'SUCCESS', users });
}

function listFriends(req, res) {
  const friends = getUserFriends(req.user.username);
  return res.json({ status: 'SUCCESS', friends });
}

function listIncomingRequestsForUser(req, res) {
  const rows = listIncomingRequests(req.user.username)
    .filter((entry) => entry.status === 'pending')
    .map((entry) => ({ id: entry.id, from_username: entry.from_username, created_at: entry.created_at }));
  return res.json({ status: 'SUCCESS', requests: rows });
}

function sendRequest(req, res) {
  const { username } = req.body || {};
  const target = getUser(username);
  if (!target) return res.status(404).json({ status: 'FAILURE', message: 'User not found' });
  if (username === req.user.username) {
    return res.status(400).json({ status: 'FAILURE', message: 'Cannot friend yourself' });
  }
  if (isFriend(req.user.username, username)) {
    return res.status(409).json({ status: 'FAILURE', message: 'Already friends' });
  }

  const existingOutgoing = listOutgoingRequests(req.user.username).some((entry) => entry.to_username === username && entry.status === 'pending');
  if (existingOutgoing) {
    return res.status(409).json({ status: 'FAILURE', message: 'Friend request already sent' });
  }

  addFriendRequest(req.user.username, username);
  return res.status(201).json({ status: 'SUCCESS', message: 'Friend request sent' });
}

function respondToRequest(req, res, accept) {
  const requestId = String(req.params.id);
  const target = listIncomingRequests(req.user.username).find((entry) => entry.id === requestId && entry.status === 'pending');
  if (!target) {
    return res.status(404).json({ status: 'FAILURE', message: 'Friend request not found' });
  }

  respondToFriendRequest(req.user.username, requestId, accept);
  if (accept) addFriendRelation(req.user.username, target.from_username);

  return res.json({ status: 'SUCCESS', message: accept ? 'Friend request accepted' : 'Friend request rejected' });
}

function removeFriend(req, res) {
  const { username } = req.params;
  if (!username) {
    return res.status(400).json({ status: 'FAILURE', message: 'Target username is required' });
  }
  if (!isFriend(req.user.username, username)) {
    return res.status(400).json({ status: 'FAILURE', message: 'User is not in your friends list' });
  }
  removeFriendRelation(req.user.username, username);
  return res.json({ status: 'SUCCESS', message: 'Friend removed successfully' });
}

module.exports = {
  searchUsers,
  listFriends,
  listIncomingRequestsForUser,
  sendRequest,
  removeFriend,
  accept: (req, res) => respondToRequest(req, res, true),
  reject: (req, res) => respondToRequest(req, res, false),
};
