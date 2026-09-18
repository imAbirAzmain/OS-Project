const express = require('express');
const router = express.Router();
const friendsController = require('../controllers/friendsController');
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth);

router.get('/search', friendsController.searchUsers);
router.get('/', friendsController.listFriends);
router.get('/requests', friendsController.listIncomingRequestsForUser);
router.post('/requests', friendsController.sendRequest);
router.post('/requests/:id/accept', friendsController.accept);
router.post('/requests/:id/reject', friendsController.reject);

module.exports = router;
