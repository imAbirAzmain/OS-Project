const express = require('express');
const router = express.Router();
const globalController = require('../controllers/globalController');
const { requireAuth } = require('../middleware/auth');
const { upload } = require('../middleware/upload');

router.use(requireAuth);

router.get('/files', globalController.list);
router.get('/files/search', globalController.search);
router.post('/files', upload.single('file'), globalController.upload);
router.get('/files/:filename/info', globalController.info);
router.get('/files/:filename/download', globalController.download);
router.get('/files/:filename/view', globalController.view);
router.delete('/files/:filename', globalController.del);

module.exports = router;
