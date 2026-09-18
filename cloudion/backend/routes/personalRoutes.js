const express = require('express');
const router = express.Router();
const personalController = require('../controllers/personalController');
const { requireAuth } = require('../middleware/auth');
const { upload } = require('../middleware/upload');

router.use(requireAuth);

router.get('/files', personalController.list);
router.get('/files/search', personalController.search);
router.post('/files', upload.single('file'), personalController.upload);
router.get('/files/:filename/info', personalController.info);
router.get('/files/:filename/download', personalController.download);
router.get('/files/:filename/view', personalController.view);
router.delete('/files/:filename', personalController.del);

module.exports = router;
