const express = require('express');
const { getOrCreateChat, sendMessage, getUserChats } = require('../controllers/chatController');
const { getBotResponse } = require('../controllers/chatBotController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(protect);

router.post('/bot', getBotResponse);

router.route('/')
  .post(getOrCreateChat)
  .get(getUserChats);

router.post('/:id/messages', sendMessage);

module.exports = router;
