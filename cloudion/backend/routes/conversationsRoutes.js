const express = require('express');
const router = express.Router();
const conversationsController = require('../controllers/conversationsController');
const { requireAuth } = require('../middleware/auth');
const { upload } = require('../middleware/upload');

router.use(requireAuth);

router.get('/', conversationsController.listConversations);
router.post('/', conversationsController.createConversation);
router.get('/:id/messages', conversationsController.listMessages);
router.post('/:id/messages', conversationsController.sendMessage);
router.post('/:id/files', upload.single('file'), conversationsController.uploadFile);
router.get('/:id/files', conversationsController.listFiles);
router.get('/:id/files/search', conversationsController.searchFiles);
router.get('/:id/files/:filename/download', conversationsController.downloadFile);
router.get('/:id/files/:filename/view', conversationsController.viewFile);
router.delete('/:id/files/:filename', conversationsController.deleteFile);

module.exports = router;
