const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const path = require('path');

const { PORT } = require('./config/config');

const authRoutes = require('./routes/authRoutes');
const personalRoutes = require('./routes/personalRoutes');
const friendsRoutes = require('./routes/friendsRoutes');
const conversationsRoutes = require('./routes/conversationsRoutes');
const groupsRoutes = require('./routes/groupsRoutes');
const globalRoutes = require('./routes/globalRoutes');
const serverRoutes = require('./routes/serverRoutes');

const app = express();

app.use(cors({ origin: true, credentials: true }));
app.use(cookieParser());
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/personal', personalRoutes);
app.use('/api/friends', friendsRoutes);
app.use('/api/conversations', conversationsRoutes);
app.use('/api/groups', groupsRoutes);
app.use('/api/global', globalRoutes);
app.use('/api/server', serverRoutes);

// Serve the static frontend.
app.use(express.static(path.join(__dirname, '..', 'frontend')));

// Centralized error handler — catches anything a controller didn't
// explicitly handle (e.g. an unexpected exception), so the process never
// crashes on a single bad request.
app.use((err, req, res, next) => {
  console.error(err);
  if (err.type === 'entity.too.large' || err.code === 'LIMIT_FILE_SIZE') {
    return res.status(413).json({ status: 'FAILURE', message: 'Upload exceeds maximum allowed size' });
  }
  res.status(500).json({ status: 'FAILURE', message: 'Internal server error' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Cloudion backend listening on port ${PORT} (accessible at http://localhost:${PORT} and local network IP)`);
});
