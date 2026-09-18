const jwt = require('jsonwebtoken');
const { JWT_SECRET, SERVER_OWNER_USERNAME } = require('../config/config');

function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = (header.startsWith('Bearer ') ? header.slice(7) : null) || req.cookies?.token || req.query?.token;

  if (!token) {
    return res.status(401).json({ status: 'FAILURE', message: 'Authentication required' });
  }

  try {
    const payload = jwt.verify(token, JWT_SECRET);
    req.user = { id: payload.sub, username: payload.username };
    next();
  } catch (err) {
    return res.status(401).json({ status: 'FAILURE', message: 'Invalid or expired session' });
  }
}

function requireServerOwner(req, res, next) {
  const username = req.user?.username;
  if (!username || username !== SERVER_OWNER_USERNAME) {
    return res.status(403).json({ status: 'FAILURE', message: 'Server status is restricted to the server owner only.' });
  }
  next();
}

module.exports = { requireAuth, requireServerOwner };
