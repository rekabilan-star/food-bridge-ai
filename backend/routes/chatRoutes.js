const express = require('express');
const {
  getOrCreateChat,
  sendMessage,
  getUserChats,
  getChatMessages,
  updateMessageStatus,
  editMessage,
  deleteMessage
} = require('../controllers/chatController');
const { getBotResponse } = require('../controllers/chatBotController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(protect);

router.post('/bot', getBotResponse);

router.route('/')
  .post(getOrCreateChat)
  .get(getUserChats);

router.get('/:id/messages', getChatMessages);
router.post('/:id/messages', sendMessage);

router.route('/messages/:id')
  .put(editMessage)
  .delete(deleteMessage);

router.put('/messages/:id/status', updateMessageStatus);

module.exports = router;
