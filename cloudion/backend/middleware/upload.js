const multer = require('multer');
const fs = require('fs');
const { UPLOAD_STAGING_DIR, MAX_UPLOAD_BYTES } = require('../config/config');

fs.mkdirSync(UPLOAD_STAGING_DIR, { recursive: true });

// Files land in the staging area under a random name first. The backend
// then hands (stagingPath, sanitizedOriginalName) to the relevant upload
// script, which is the only thing that moves the file into real storage.
// This means the backend itself never decides the final on-disk path.
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, UPLOAD_STAGING_DIR),
  filename: (req, file, cb) => {
    const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    cb(null, unique);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: MAX_UPLOAD_BYTES },
});

// Strips path separators and control characters from a client-supplied
// filename before it is ever passed as an argv argument to a script.
function sanitizeFilename(name) {
  const base = name.split('/').pop().split('\\').pop();
  return base.replace(/[\x00-\x1f]/g, '').replace(/^[-.]+/, '').slice(0, 255) || 'file';
}

module.exports = { upload, sanitizeFilename };
