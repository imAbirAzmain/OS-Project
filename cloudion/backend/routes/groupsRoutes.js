const express = require('express');
const router = express.Router();
const groupsController = require('../controllers/groupsController');
const { requireAuth } = require('../middleware/auth');
const { upload } = require('../middleware/upload');

router.use(requireAuth);

router.get('/', groupsController.listGroups);
router.post('/', groupsController.createGroup);
router.delete('/:id', groupsController.deleteGroup);
router.get('/:id/members', groupsController.listMembers);
router.post('/:id/members', groupsController.addMember);
router.delete('/:id/members/:username', groupsController.removeMember);
router.get('/:id/messages', groupsController.listGroupMessages);
router.post('/:id/messages', groupsController.sendGroupMessage);
router.post('/:id/files', upload.single('file'), groupsController.uploadFile);
router.get('/:id/files', groupsController.listFiles);
router.get('/:id/files/search', groupsController.searchFiles);
router.get('/:id/files/:filename/info', groupsController.fileInfo);
router.get('/:id/files/:filename/download', groupsController.downloadFile);
router.get('/:id/files/:filename/view', groupsController.viewFile);
router.delete('/:id/files/:filename', groupsController.deleteFile);

module.exports = router;
