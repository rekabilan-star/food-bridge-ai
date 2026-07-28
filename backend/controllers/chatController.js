const Chat = require('../models/Chat');

// @desc    Get or Create Chat
// @route   POST /api/chat
// @access  Private
exports.getOrCreateChat = async (req, res, next) => {
  try {
    const { receiverId, donationId } = req.body;

    let chat = await Chat.findOne({
      participants: { $all: [req.user.id, receiverId] },
      donationId: donationId
    }).populate('participants', 'name profileImage');

    if (!chat) {
      chat = await Chat.create({
        participants: [req.user.id, receiverId],
        donationId: donationId,
        messages: []
      });
      chat = await chat.populate('participants', 'name profileImage');
    }

    res.status(200).json({
      success: true,
      data: chat,
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Send Message
// @route   POST /api/chat/:id/messages
// @access  Private
exports.sendMessage = async (req, res, next) => {
  try {
    const { text } = req.body;
    const chat = await Chat.findById(req.params.id);

    if (!chat) {
      return res.status(404).json({ success: false, message: 'Chat not found' });
    }

    const newMessage = {
      senderId: req.user.id,
      text,
      time: Date.now()
    };

    chat.messages.push(newMessage);
    chat.lastMessage = {
      text,
      time: Date.now()
    };

    await chat.save();

    res.status(201).json({
      success: true,
      data: newMessage,
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Get User Chats
// @route   GET /api/chat
// @access  Private
exports.getUserChats = async (req, res, next) => {
  try {
    const chats = await Chat.find({ participants: req.user.id })
      .populate('participants', 'name profileImage role')
      .populate('donationId', 'foodName status')
      .sort('-lastMessage.time');

    res.status(200).json({
      success: true,
      data: chats,
    });
  } catch (err) {
    next(err);
  }
};
